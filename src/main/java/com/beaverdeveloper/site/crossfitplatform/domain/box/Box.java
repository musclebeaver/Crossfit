package com.beaverdeveloper.site.crossfitplatform.domain.box;

import com.beaverdeveloper.site.crossfitplatform.domain.user.User;
import com.beaverdeveloper.site.crossfitplatform.global.common.BaseEntity;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "boxes")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor
@Builder
public class Box extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String name;

    @Column(nullable = false)
    private String location;

    @Column(name = "business_number")
    private String businessNumber;

    @Column(name = "is_verified", nullable = false)
    private boolean isVerified;

    @Builder.Default
    @Column(name = "is_auto_wod_enabled", nullable = false)
    private boolean isAutoWodEnabled = true;

    public void updateAutoWod(boolean enabled) {
        this.isAutoWodEnabled = enabled;
    }

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "owner_id")
    private User owner;
}
