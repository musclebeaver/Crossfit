package com.beaverdeveloper.site.crossfitplatform.domain.wod;

import lombok.Getter;

@Getter
public enum WodType {
    AMRAP("As Many Rounds As Possible"),
    FOR_TIME("For Time"),
    EMOM("Every Minute on the Minute"),
    MAX_WEIGHT("Max Weight");

    private final String description;

    WodType(String description) {
        this.description = description;
    }
}
