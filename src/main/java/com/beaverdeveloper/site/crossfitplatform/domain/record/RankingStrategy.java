package com.beaverdeveloper.site.crossfitplatform.domain.record;

import com.beaverdeveloper.site.crossfitplatform.domain.wod.WodType;
import org.springframework.stereotype.Component;

import java.util.Comparator;

public interface RankingStrategy {
    WodType getSupportedType();

    Comparator<Record> getComparator();

    Double calculateRedisScore(Record record);

    String formatRecord(Double resultValue);

    default boolean isRxFromScore(Double score) {
        return score != null && score >= 10_000_000.0;
    }

    default Double getResultValueFromScore(Double score) {
        if (score == null)
            return 0.0;
        return score >= 10_000_000.0 ? score - 10_000_000.0 : score;
    }

    default boolean isCappedFromScore(Double score) {
        return false;
    }
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
        double rxWeight = record.isRx() ? 10_000_000.0 : 0.0;
        return rxWeight + record.getResultValue();
    }

    @Override
    public String formatRecord(Double resultValue) {
        if (resultValue == null)
            return "0 reps";
        return resultValue.intValue() + " reps";
    }
}

@Component
class ForTimeRankingStrategy implements RankingStrategy {
    private static final double MAX_VALUE = 10_000_000.0;

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
        double rxWeight = record.isRx() ? 20_000_000.0 : 0.0;
        double finishedWeight = !record.isCapped() ? 10_000_000.0 : 0.0;
        return rxWeight + finishedWeight + (MAX_VALUE - record.getResultValue());
    }

    @Override
    public Double getResultValueFromScore(Double score) {
        if (score == null)
            return 0.0;
        double base = score;
        if (base >= 20_000_000.0)
            base -= 20_000_000.0;
        if (base >= 10_000_000.0)
            base -= 10_000_000.0;
        return MAX_VALUE - base;
    }

    @Override
    public boolean isCappedFromScore(Double score) {
        if (score == null)
            return false;
        double base = score;
        if (base >= 20_000_000.0)
            base -= 20_000_000.0;
        return base < 10_000_000.0; // If finishedWeight was not added, base < 10,000,000
    }

    @Override
    public String formatRecord(Double resultValue) {
        if (resultValue == null)
            return "0:00";
        int totalSeconds = resultValue.intValue();
        int minutes = totalSeconds / 60;
        int seconds = totalSeconds % 60;
        return String.format("%02d:%02d", minutes, seconds);
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

    @Override
    public String formatRecord(Double resultValue) {
        if (resultValue == null)
            return "0 kg";
        return resultValue.intValue() + " kg";
    }
}

@Component
class EmomRankingStrategy implements RankingStrategy {
    @Override
    public WodType getSupportedType() {
        return WodType.EMOM;
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

    @Override
    public String formatRecord(Double resultValue) {
        if (resultValue == null)
            return "0";
        return String.valueOf(resultValue.intValue());
    }
}
