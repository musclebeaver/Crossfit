package com.beaverdeveloper.site.crossfitplatform.domain.user;

import lombok.Getter;

@Getter
public enum UserRole {
    USER("Common User"),
    PREMIUM("Premium User (Ad-free)"),
    COACH("Box Coach"),
    ADMIN("Platform Admin");

    private final String description;

    UserRole(String description) {
        this.description = description;
    }
}
