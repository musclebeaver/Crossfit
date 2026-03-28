package com.beaverdeveloper.site.crossfitplatform.domain.record;

import com.beaverdeveloper.site.crossfitplatform.domain.wod.Wod;
import com.beaverdeveloper.site.crossfitplatform.domain.wod.WodRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.data.redis.core.ZSetOperations;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;
import java.util.Set;
import java.util.Map;
import java.util.stream.Collectors;

@Component
@RequiredArgsConstructor
public class DailyRankingScheduler {
    private static final org.slf4j.Logger log = org.slf4j.LoggerFactory.getLogger(DailyRankingScheduler.class);

    private final WodRepository wodRepository;
    private final RecordService recordService;
    private final RecordRepository recordRepository;
    private final RankingHistoryRepository rankingHistoryRepository;
    private final com.beaverdeveloper.site.crossfitplatform.domain.user.UserRepository userRepository;
    private final RedisTemplate<String, Object> redisTemplate;

    /**
     * 매일 자정(00:00)에 실행되어 전날의 WOD 랭킹을 DB에 저장합니다.
     */
    @Scheduled(cron = "0 0 0 * * *")
    @Transactional
    public void snapshotDailyRankings() {
        LocalDate yesterday = LocalDate.now().minusDays(1);
        log.info("Starting daily ranking snapshot for date: {}", yesterday);

        List<Wod> yesterdayWods = wodRepository.findAllByDate(yesterday);

        for (Wod wod : yesterdayWods) {
            List<RecordController.RankingResponse> rankings = recordService.getRankings(wod.getId(),
                    wod.getBoxId(), 0L, Integer.MAX_VALUE, null).getContent();
                    
            List<Record> rawRecords = recordRepository.findAllByWodId(wod.getId());
            Map<Long, Record> recordMap = rawRecords.stream()
                    .collect(Collectors.toMap(Record::getUserId, r -> r, (r1, r2) -> r1));
                    
            int totalParticipants = rankings.size();

            for (RecordController.RankingResponse ranking : rankings) {
                Long userId = ranking.getUserId();
                Double score = ranking.getScore();
                
                Record record = recordMap.get(userId);
                boolean isRx = record != null ? record.isRx() : (score >= 10_000_000.0);
                boolean isCapped = record != null && record.isCapped();

                RankingHistory history = RankingHistory.builder()
                        .wodId(wod.getId())
                        .userId(userId)
                        .rank(ranking.getRank() != null ? ranking.getRank() : 0)
                        .score(score)
                        .isRx(isRx)
                        .date(yesterday)
                        .build();

                rankingHistoryRepository.save(history);

                // Award rank-based points
                int rankValue = ranking.getRank() != null ? ranking.getRank() : 0;
                long pointsToAward = 0;
                
                if (isCapped) {
                    pointsToAward = 5;
                } else if (isRx) {
                    pointsToAward = 15;
                } else {
                    pointsToAward = 10;
                }

                if (rankValue == 1) pointsToAward = Math.max(pointsToAward, 100);
                else if (rankValue == 2) pointsToAward = Math.max(pointsToAward, 80);
                else if (rankValue == 3) pointsToAward = Math.max(pointsToAward, 60);
                else if (rankValue <= totalParticipants * 0.10) pointsToAward = Math.max(pointsToAward, 40);
                else if (rankValue <= totalParticipants * 0.30) pointsToAward = Math.max(pointsToAward, 25);

                if (pointsToAward > 0) {
                    long finalPoints = pointsToAward;
                    userRepository.findById(userId).ifPresent(user -> {
                        user.addPoints(finalPoints);
                        userRepository.save(user);
                    });
                }
            }
            log.info("WOD ID {} ranking snapshot completed. Total {} users.", wod.getId(), rankings.size());
        }
        log.info("Daily ranking snapshot for {} completed successfully.", yesterday);
    }
}
