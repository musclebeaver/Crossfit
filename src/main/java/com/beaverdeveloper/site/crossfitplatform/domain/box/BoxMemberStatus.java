package com.beaverdeveloper.site.crossfitplatform.domain.box;

import lombok.Getter;

@Getter
public enum BoxMemberStatus {
    PENDING("Approval Pending"),
    APPROVED("Member Approved"),
    REJECTED("Registration Rejected");

    private final String description;

    BoxMemberStatus(String description) {
        this.description = description;
    }
}
