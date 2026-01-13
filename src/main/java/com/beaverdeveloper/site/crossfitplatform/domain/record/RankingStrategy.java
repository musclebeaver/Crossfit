package com.beaverdeveloper.site.crossfitplatform.domain.record;

import com.beaverdeveloper.site.crossfitplatform.domain.wod.WodType;
import org.springframework.stereotype.Component;

import java.util.Comparator;

public interface RankingStrategy {
    WodType getSupportedType();

    Comparator<Record> getComparator();

    Double calculateRedisScore(Record record);
}

@Component
class AmrapRankingStrategy implements RankingStrategy {
    @Override
    public WodType getSupportedType() {
        return WodType.AMRAP;
    }

    @Override
    public Comparator<Record> getComparator() {
        return Comparator.comparing(Record::isRx).reversed()
                .thenComparing(Record::getResultValue).reversed();
    }

    @Override
    public Double calculateRedisScore(Record record) {
        // Rx'd 가중치: 10,000,000 (충분히 큰 값)
        double rxWeight = record.isRx() ? 10_000_000.0 : 0.0;
        return rxWeight + record.getResultValue();
    }
}

@Component
class ForTimeRankingStrategy implements RankingStrategy {
    @Override
    public WodType getSupportedType() {
        return WodType.FOR_TIME;
    }

    @Override
    public Comparator<Record> getComparator() {
        return Comparator.comparing(Record::isRx).reversed()
                .thenComparing(Record::getResultValue);
    }

    @Override
    public Double calculateRedisScore(Record record) {
        // For Time은 시간이 짧을수록 좋으므로, 가중치에서 뺀 값을 사용
        // Rx'd는 더 높은 점수를 가져야 함
        double rxWeight = record.isRx() ? 10_000_000.0 : 0.0;
        // 결과값이 0 이상 10,000,000 미만이라고 가정 (약 115일 분량의 초)
        return rxWeight + (10_000_000.0 - record.getResultValue());
    }
}

@Component
class MaxWeightRankingStrategy implements RankingStrategy {
    @Override
    public WodType getSupportedType() {
        return WodType.MAX_WEIGHT;
    }

    @Override
    public Comparator<Record> getComparator() {
        return Comparator.comparing(Record::isRx).reversed()
                .thenComparing(Record::getResultValue).reversed();
    }

    @Override
    public Double calculateRedisScore(Record record) {
        double rxWeight = record.isRx() ? 10_000_000.0 : 0.0;
        return rxWeight + record.getResultValue();
    }
}
