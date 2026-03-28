package com.beaverdeveloper.site.crossfitplatform.domain.record;

import com.beaverdeveloper.site.crossfitplatform.domain.wod.WodType;
import lombok.RequiredArgsConstructor;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.data.redis.core.ZSetOperations;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Objects;
import java.util.Set;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class RecordService {

    private final RecordRepository recordRepository;
    private final com.beaverdeveloper.site.crossfitplatform.domain.user.UserRepository userRepository;
    private final com.beaverdeveloper.site.crossfitplatform.domain.wod.WodRepository wodRepository;
    private final List<RankingStrategy> strategies;
    private final RedisTemplate<String, Object> redisTemplate;

    private static final String RANKING_KEY_PREFIX = "rank:wod:";

    @Transactional
    public Long registerRecord(Record record) {
        Record savedRecord = recordRepository.save(record);

        // Award point to user (participation score)
        userRepository.findById(record.getUserId()).ifPresent(user -> {
            user.addPoints(1L);
            userRepository.save(user); // JPA Dirty Checking might work, but explicit save for safety
        });

        updateRedisRanking(savedRecord);
        return savedRecord.getId();
    }

    private void updateRedisRanking(Record record) {
        RankingStrategy strategy = getStrategy(record.getWod().getType());
        Double score = strategy.calculateRedisScore(record);

        Long wodId = record.getWod().getId();
        Long wodBoxId = record.getWod().getBoxId();

        // Find user's box info
        Long userBoxId = userRepository.findById(record.getUserId())
                .map(com.beaverdeveloper.site.crossfitplatform.domain.user.User::getBoxId)
                .orElse(null);

        if (wodBoxId == null) {
            // Global WOD: Save to global ranking
            String globalKey = RANKING_KEY_PREFIX + wodId + ":global";
            redisTemplate.opsForZSet().add(globalKey, record.getUserId().toString(), score);

            // Also save to user's box ranking if available
            if (userBoxId != null) {
                String boxKey = RANKING_KEY_PREFIX + wodId + ":box:" + userBoxId;
                redisTemplate.opsForZSet().add(boxKey, record.getUserId().toString(), score);
            }
        } else {
            // Box WOD: Save to specific box ranking only
            String boxKey = RANKING_KEY_PREFIX + wodId + ":box:" + wodBoxId;
            redisTemplate.opsForZSet().add(boxKey, record.getUserId().toString(), score);
        }
    }

    public RecordController.CursorResponse<RecordController.RankingResponse> getRankings(Long wodId, Long boxId,
            Long cursorRank, int size,
            String nickname) {
        String key = (boxId == null) ? RANKING_KEY_PREFIX + wodId + ":global"
                : RANKING_KEY_PREFIX + wodId + ":box:" + boxId;

        com.beaverdeveloper.site.crossfitplatform.domain.wod.Wod wod = wodRepository.findById(wodId)
                .orElseThrow(() -> new IllegalArgumentException("WOD not found"));
        RankingStrategy strategy = getStrategy(wod.getType());

        if (nickname != null && !nickname.isEmpty()) {
            // Use MySQL for nickname search, map cursorRank to page
            int page = cursorRank == null ? 0 : (int) (cursorRank / size);
            org.springframework.data.domain.Pageable pageable = org.springframework.data.domain.PageRequest.of(page,
                    size);
            org.springframework.data.domain.Page<com.beaverdeveloper.site.crossfitplatform.domain.user.User> userPage;

            if (boxId == null) {
                userPage = userRepository.findByNicknameContaining(nickname, pageable);
            } else {
                userPage = userRepository.findByBoxIdAndNicknameContaining(boxId, nickname, pageable);
            }

            List<RecordController.RankingResponse> list = userPage.getContent().stream()
                    .map(u -> {
                        Double score = redisTemplate.opsForZSet().score(key, u.getId().toString());
                        if (score == null)
                            return null;
                        Long rank = redisTemplate.opsForZSet().reverseRank(key, u.getId().toString());

                        double resultValue = strategy.getResultValueFromScore(score);
                        String displayValue = strategy.formatRecord(resultValue);
                        boolean isRx = strategy.isRxFromScore(score);
                        boolean isCapped = strategy.isCappedFromScore(score);

                        return new RecordController.RankingResponse(u.getId(), u.getNickname(), score,
                                rank != null ? rank.intValue() + 1 : null, displayValue, isRx, isCapped,
                                u.getTier().name());
                    })
                    .filter(Objects::nonNull)
                    .sorted((a, b) -> b.getScore().compareTo(a.getScore()))
                    .collect(Collectors.toList());

            boolean hasNext = userPage.hasNext();
            Long nextCursor = hasNext ? (long) ((page + 1) * size) : null;
            return new RecordController.CursorResponse<>(list, nextCursor, hasNext);

        } else {
            // Use Redis cursor-based pagination (by rank)
            int start = cursorRank == null ? 0 : cursorRank.intValue();
            int fetchStop = start + size; // Fetch size + 1 to check for hasNext

            Set<ZSetOperations.TypedTuple<Object>> fetchResults = redisTemplate.opsForZSet().reverseRangeWithScores(key,
                    start, fetchStop);

            if (fetchResults == null || fetchResults.isEmpty()) {
                return new RecordController.CursorResponse<>(List.of(), null, false);
            }

            boolean hasNext = fetchResults.size() > size;
            List<ZSetOperations.TypedTuple<Object>> activeResults = fetchResults.stream()
                    .limit(size)
                    .collect(Collectors.toList());

            int[] currentRank = { start + 1 }; // 1-based rank
            List<RecordController.RankingResponse> list = activeResults.stream()
                    .map(tuple -> {
                        Long userId = Long.valueOf((String) tuple.getValue());
                        Double score = tuple.getScore();
                        com.beaverdeveloper.site.crossfitplatform.domain.user.User user = userRepository
                                .findById(userId)
                                .orElse(null);
                        String userNickname = user != null ? user.getNickname() : "Unknown";
                        String userTier = user != null ? user.getTier().name() : "NEWBIE";

                        double resultValue = strategy.getResultValueFromScore(score);
                        String displayValue = strategy.formatRecord(resultValue);
                        boolean isRx = strategy.isRxFromScore(score);
                        boolean isCapped = strategy.isCappedFromScore(score);

                        return new RecordController.RankingResponse(userId, userNickname, score,
                                currentRank[0]++, displayValue, isRx, isCapped, userTier);
                    })
                    .collect(Collectors.toList());

            Long nextCursor = hasNext ? (long) (start + size) : null;
            return new RecordController.CursorResponse<>(list, nextCursor, hasNext);
        }
    }

    private RankingStrategy getStrategy(WodType type) {
        return strategies.stream()
                .filter(s -> s.getSupportedType() == type)
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException("Unsupported WOD type: " + type));
    }
}
