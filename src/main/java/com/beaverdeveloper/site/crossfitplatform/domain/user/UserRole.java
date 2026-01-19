package com.beaverdeveloper.site.crossfitplatform.domain.user;

import lombok.Getter;

@Getter
public enum UserRole {
    USER("Common User"),
    PREMIUM_USER("Premium User (Ad-free)"),
    COACH("Box Coach"),
    PREMIUM_COACH("Premium Coach (Ad-free)"),
    ADMIN("Platform Admin");

    private final String description;
    private final String key;

    UserRole(String description) {
        this.description = description;
        this.key = "ROLE_" + this.name();
    }

    public String getKey() {
        return key;
    }
}
