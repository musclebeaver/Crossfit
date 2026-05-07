package com.beaverdeveloper.site.crossfitplatform.domain.user;

import com.beaverdeveloper.site.crossfitplatform.global.common.BaseEntity;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "users")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor
@Builder
public class User extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String email;

    @Column(nullable = false)
    private String password;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    @Builder.Default
    private AuthProvider provider = AuthProvider.LOCAL;

    @Column(nullable = false)
    @Builder.Default
    private Long points = 0L;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    @Builder.Default
    private UserTier tier = UserTier.NEWBIE;

    @Column(nullable = false)
    private String nickname;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private UserRole role;

    @Column(name = "box_id")
    private Long boxId;

    @Column
    private String picture;

    @Column(nullable = false)
    private boolean isVerified;
    
    @Column(name = "fcm_token")
    private String fcmToken;

    public User update(String name, String picture) {
        this.nickname = name;
        this.picture = picture;
        return this;
    }

    public void updateBox(Long boxId) {
        this.boxId = boxId;
    }
    
    public void updateFcmToken(String fcmToken) {
        this.fcmToken = fcmToken;
    }

    public void updateNickname(String nickname) {
        this.nickname = nickname;
    }

    public void updatePassword(String password) {
        this.password = password;
    }

    public void upgradeToPremium() {
        if (this.role == UserRole.USER) {
            this.role = UserRole.PREMIUM_USER;
        } else if (this.role == UserRole.COACH) {
            this.role = UserRole.PREMIUM_COACH;
        }
    }

    public void addPoints(Long points) {
        this.points += points;
        this.tier = UserTier.calculateTier(this.points);
    }
}
