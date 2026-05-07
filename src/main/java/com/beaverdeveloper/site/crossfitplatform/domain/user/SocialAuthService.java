package com.beaverdeveloper.site.crossfitplatform.domain.user;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.Map;

@Slf4j
@Service
@RequiredArgsConstructor
public class SocialAuthService {

    private final RestTemplate restTemplate = new RestTemplate();

    public OAuth2UserInfo getUserInfo(AuthProvider provider, String accessToken) {
        return switch (provider) {
            case KAKAO -> getKakaoUserInfo(accessToken);
            case GOOGLE -> getGoogleUserInfo(accessToken);
            case NAVER -> getNaverUserInfo(accessToken);
            case APPLE -> getAppleUserInfo(accessToken);
            default -> throw new IllegalArgumentException("Unsupported provider: " + provider);
        };
    }

    private OAuth2UserInfo getKakaoUserInfo(String accessToken) {
        HttpHeaders headers = new HttpHeaders();
        headers.setBearerAuth(accessToken);
        HttpEntity<?> entity = new HttpEntity<>(headers);

        try {
            ResponseEntity<Map> response = restTemplate.exchange(
                    "https://kapi.kakao.com/v2/user/me",
                    HttpMethod.GET,
                    entity,
                    Map.class
            );

            Map<String, Object> attributes = response.getBody();
            if (attributes == null) throw new IllegalArgumentException("Failed to fetch Kakao user info");

            Map<String, Object> kakaoAccount = (Map<String, Object>) attributes.get("kakao_account");
            Map<String, Object> profile = (Map<String, Object>) kakaoAccount.get("profile");

            String email = (String) kakaoAccount.get("email");
            String nickname = (String) profile.get("nickname");
            String picture = (String) profile.get("thumbnail_image_url");

            return new OAuth2UserInfo(email, nickname, picture, AuthProvider.KAKAO);
        } catch (Exception e) {
            log.error("Kakao API error", e);
            throw new IllegalArgumentException("Invalid Kakao Access Token");
        }
    }

    private OAuth2UserInfo getGoogleUserInfo(String accessToken) {
        HttpHeaders headers = new HttpHeaders();
        headers.setBearerAuth(accessToken);
        HttpEntity<?> entity = new HttpEntity<>(headers);

        try {
            ResponseEntity<Map> response = restTemplate.exchange(
                    "https://www.googleapis.com/oauth2/v3/userinfo",
                    HttpMethod.GET,
                    entity,
                    Map.class
            );

            Map<String, Object> attributes = response.getBody();
            if (attributes == null) throw new IllegalArgumentException("Failed to fetch Google user info");

            String email = (String) attributes.get("email");
            String name = (String) attributes.get("name");
            String picture = (String) attributes.get("picture");

            return new OAuth2UserInfo(email, name, picture, AuthProvider.GOOGLE);
        } catch (Exception e) {
            log.error("Google API error", e);
            throw new IllegalArgumentException("Invalid Google Access Token");
        }
    }

    private OAuth2UserInfo getNaverUserInfo(String accessToken) {
        HttpHeaders headers = new HttpHeaders();
        headers.setBearerAuth(accessToken);
        HttpEntity<?> entity = new HttpEntity<>(headers);

        try {
            ResponseEntity<Map> response = restTemplate.exchange(
                    "https://openapi.naver.com/v1/nid/me",
                    HttpMethod.GET,
                    entity,
                    Map.class
            );

            Map<String, Object> body = response.getBody();
            if (body == null) throw new IllegalArgumentException("Failed to fetch Naver user info");

            Map<String, Object> responseData = (Map<String, Object>) body.get("response");
            String email = (String) responseData.get("email");
            String name = (String) responseData.get("name");
            if (name == null || name.isEmpty()) {
                name = (String) responseData.get("nickname");
            }
            String picture = (String) responseData.get("profile_image");

            return new OAuth2UserInfo(email, name, picture, AuthProvider.NAVER);
        } catch (Exception e) {
            log.error("Naver API error", e);
            throw new IllegalArgumentException("Invalid Naver Access Token");
        }
    }

    private OAuth2UserInfo getAppleUserInfo(String accessToken) {
        // Apple Identity Token은 JWT 형태입니다. 여기서는 accessToken 변수에 ID Token이 온다고 가정합니다.
        try {
            String[] chunks = accessToken.split("\\.");
            java.util.Base64.Decoder decoder = java.util.Base64.getUrlDecoder();
            String payload = new String(decoder.decode(chunks[1]));
            
            Map<String, Object> attributes = new com.fasterxml.jackson.databind.ObjectMapper().readValue(payload, Map.class);
            
            String email = (String) attributes.get("email");
            String sub = (String) attributes.get("sub"); // Unique identifier
            
            // Apple은 최초 로그인시에만 name을 보내주므로, 닉네임이 없으면 sub나 이메일 앞부분 사용
            String nickname = email != null ? email.split("@")[0] : "Apple_" + sub.substring(0, 6);
            
            return new OAuth2UserInfo(email, nickname, null, AuthProvider.APPLE);
        } catch (Exception e) {
            log.error("Apple Token parsing error", e);
            throw new IllegalArgumentException("Invalid Apple Identity Token");
        }
    }

    public record OAuth2UserInfo(String email, String name, String picture, AuthProvider provider) {}
}
