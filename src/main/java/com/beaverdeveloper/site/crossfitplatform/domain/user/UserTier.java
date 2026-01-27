package com.beaverdeveloper.site.crossfitplatform.domain.user;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

import java.util.Arrays;

@Getter
@RequiredArgsConstructor
public enum UserTier {
    NEWBIE("Level 1", 0L),
    AMATEUR("Level 2", 50L),
    PRO("Level 3", 200L),
    ELITE("Level 4", 500L),
    LEGEND("Level 5", 1000L);

    private final String name;
    private final Long requiredPoints;

    public static UserTier calculateTier(Long points) {
        return Arrays.stream(UserTier.values())
                .filter(tier -> points >= tier.getRequiredPoints())
                .reduce((first, second) -> second)
                .orElse(NEWBIE);
    }
}
