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

@Component
@RequiredArgsConstructor
public class DailyRankingScheduler {
    private static final org.slf4j.Logger log = org.slf4j.LoggerFactory.getLogger(DailyRankingScheduler.class);

    private final WodRepository wodRepository;
    private final RecordService recordService;
    private final RankingHistoryRepository rankingHistoryRepository;
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
                    null, 0, Integer.MAX_VALUE, null);

            for (RecordController.RankingResponse ranking : rankings) {
                Long userId = ranking.getUserId();
                Double score = ranking.getScore();

                // Score 해석: 10,000,000 이상이면 Rx'd
                boolean isRx = score >= 10_000_000.0;

                RankingHistory history = RankingHistory.builder()
                        .wodId(wod.getId())
                        .userId(userId)
                        .rank(ranking.getRank() != null ? ranking.getRank() : 0)
                        .score(score)
                        .isRx(isRx)
                        .date(yesterday)
                        .build();

                rankingHistoryRepository.save(history);
            }
            log.info("WOD ID {} ranking snapshot completed. Total {} users.", wod.getId(), rankings.size());
        }
        log.info("Daily ranking snapshot for {} completed successfully.", yesterday);
    }
}
