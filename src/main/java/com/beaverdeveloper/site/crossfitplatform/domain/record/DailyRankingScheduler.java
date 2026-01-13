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

@Slf4j
@Component
@RequiredArgsConstructor
public class DailyRankingScheduler {

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
            Set<ZSetOperations.TypedTuple<Object>> rankings = recordService.getTopRankings(wod.getId(),
                    null, Integer.MAX_VALUE);

            int currentRank = 1;
            for (ZSetOperations.TypedTuple<Object> tuple : rankings) {
                Long userId = Long.valueOf((String) tuple.getValue());
                Double score = tuple.getScore();

                // Score 해석: 10,000,000 이상이면 Rx'd
                boolean isRx = score >= 10_000_000.0;

                RankingHistory history = RankingHistory.builder()
                        .wodId(wod.getId())
                        .userId(userId)
                        .rank(currentRank++)
                        .score(score)
                        .isRx(isRx)
                        .date(yesterday)
                        .build();

                rankingHistoryRepository.save(history);
            }
            log.info("WOD ID {} ranking snapshot completed. Total {} users.", wod.getId(), currentRank - 1);
        }
        log.info("Daily ranking snapshot for {} completed successfully.", yesterday);
    }
}
