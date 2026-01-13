package com.beaverdeveloper.site.crossfitplatform.domain.record;

import com.beaverdeveloper.site.crossfitplatform.domain.wod.WodType;
import lombok.RequiredArgsConstructor;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.data.redis.core.ZSetOperations;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Set;

@Service
@RequiredArgsConstructor
public class RecordService {

    private final RecordRepository recordRepository;
    private final com.beaverdeveloper.site.crossfitplatform.domain.user.UserRepository userRepository;
    private final List<RankingStrategy> strategies;
    private final RedisTemplate<String, Object> redisTemplate;

    private static final String RANKING_KEY_PREFIX = "rank:wod:";

    @Transactional
    public Long registerRecord(Record record) {
        Record savedRecord = recordRepository.save(record);
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

    public Set<ZSetOperations.TypedTuple<Object>> getTopRankings(Long wodId, Long boxId, int limit) {
        String key;
        if (boxId == null) {
            key = RANKING_KEY_PREFIX + wodId + ":global";
        } else {
            key = RANKING_KEY_PREFIX + wodId + ":box:" + boxId;
        }
        return redisTemplate.opsForZSet().reverseRangeWithScores(key, 0, limit - 1);
    }

    private RankingStrategy getStrategy(WodType type) {
        return strategies.stream()
                .filter(s -> s.getSupportedType() == type)
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException("Unsupported WOD type: " + type));
    }
}
