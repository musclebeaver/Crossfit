package com.beaverdeveloper.site.crossfitplatform.global.config;

import com.beaverdeveloper.site.crossfitplatform.domain.user.AuthProvider;
import com.beaverdeveloper.site.crossfitplatform.domain.user.UserRole;
import lombok.Builder;
import lombok.Getter;

import java.util.Map;

@Getter
public class OAuth2Attributes {
    private Map<String, Object> attributes;
    private String nameAttributeKey;
    private String name;
    private String email;
    private String picture;
    private AuthProvider provider;

    @Builder
    public OAuth2Attributes(Map<String, Object> attributes, String nameAttributeKey, String name, String email,
            String picture, AuthProvider provider) {
        this.attributes = attributes;
        this.nameAttributeKey = nameAttributeKey;
        this.name = name;
        this.email = email;
        this.picture = picture;
        this.provider = provider;
    }

    public static OAuth2Attributes of(String registrationId, String userNameAttributeName,
            Map<String, Object> attributes) {
        if ("kakao".equals(registrationId)) {
            return ofKakao("id", attributes);
        } else if ("naver".equals(registrationId)) {
            return ofNaver("response", attributes);
        }
        return ofGoogle(userNameAttributeName, attributes);
    }

    private static OAuth2Attributes ofGoogle(String userNameAttributeName, Map<String, Object> attributes) {
        return OAuth2Attributes.builder()
                .name((String) attributes.get("name"))
                .email((String) attributes.get("email"))
                .picture((String) attributes.get("picture"))
                .attributes(attributes)
                .nameAttributeKey(userNameAttributeName)
                .provider(AuthProvider.GOOGLE)
                .build();
    }

    private static OAuth2Attributes ofKakao(String userNameAttributeName, Map<String, Object> attributes) {
        Map<String, Object> kakaoAccount = (Map<String, Object>) attributes.get("kakao_account");
        Map<String, Object> kakaoProfile = (Map<String, Object>) kakaoAccount.get("profile");

        return OAuth2Attributes.builder()
                .name((String) kakaoProfile.get("nickname"))
                .email((String) kakaoAccount.get("email"))
                .picture((String) kakaoProfile.get("thumbnail_image_url"))
                .attributes(attributes)
                .nameAttributeKey(userNameAttributeName)
                .provider(AuthProvider.KAKAO)
                .build();
    }

    private static OAuth2Attributes ofNaver(String userNameAttributeName, Map<String, Object> attributes) {
        Map<String, Object> response = (Map<String, Object>) attributes.get("response");

        String name = (String) response.get("nickname");
        if (name == null || name.isEmpty()) {
            name = (String) response.get("name");
        }

        return OAuth2Attributes.builder()
                .name(name)
                .email((String) response.get("email"))
                .picture((String) response.get("profile_image"))
                .attributes(attributes)
                .nameAttributeKey(userNameAttributeName)
                .provider(AuthProvider.NAVER)
                .build();
    }

    public com.beaverdeveloper.site.crossfitplatform.domain.user.User toEntity() {
        String finalNickname = name;
        if (finalNickname == null || finalNickname.isEmpty()) {
            finalNickname = email.split("@")[0];
        }

        return com.beaverdeveloper.site.crossfitplatform.domain.user.User.builder()
                .nickname(finalNickname)
                .email(email)
                .password(java.util.UUID.randomUUID().toString()) // 소셜 사용자는 랜덤 패스워드 설정
                .role(UserRole.USER)
                .provider(provider)
                .isVerified(true)
                .points(0L)
                .tier(com.beaverdeveloper.site.crossfitplatform.domain.user.UserTier.NEWBIE)
                .build();
    }
}
