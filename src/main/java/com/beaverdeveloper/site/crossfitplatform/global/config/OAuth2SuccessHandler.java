package com.beaverdeveloper.site.crossfitplatform.global.config;

import com.beaverdeveloper.site.crossfitplatform.domain.user.JwtProvider;
import com.beaverdeveloper.site.crossfitplatform.domain.user.User;
import com.beaverdeveloper.site.crossfitplatform.domain.user.UserRepository;
import com.beaverdeveloper.site.crossfitplatform.domain.user.UserRole;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.core.Authentication;
import org.springframework.security.oauth2.core.user.OAuth2User;
import org.springframework.security.web.authentication.SimpleUrlAuthenticationSuccessHandler;
import org.springframework.stereotype.Component;
import org.springframework.web.util.UriComponentsBuilder;
import org.springframework.data.redis.core.RedisTemplate;

import java.io.IOException;

@Slf4j
@Component
@RequiredArgsConstructor
public class OAuth2SuccessHandler extends SimpleUrlAuthenticationSuccessHandler {

    private final JwtProvider jwtProvider;
    private final UserRepository userRepository;
    private final RedisTemplate<String, Object> redisTemplate;

    @org.springframework.beans.factory.annotation.Value("${app.redirect-url}")
    private String redirectUrl;

    @Override
    public void onAuthenticationSuccess(HttpServletRequest request, HttpServletResponse response,
            Authentication authentication) throws IOException, ServletException {
        OAuth2User oAuth2User = (OAuth2User) authentication.getPrincipal();
        String email = (String) oAuth2User.getAttributes().get("email");

        // Naver: email is inside 'response' map
        if (email == null) {
            java.util.Map<String, Object> responseMap = (java.util.Map<String, Object>) oAuth2User.getAttributes()
                    .get("response");
            if (responseMap != null) {
                email = (String) responseMap.get("email");
            }
        }

        // Kakao: email is inside 'kakao_account' map
        if (email == null) {
            java.util.Map<String, Object> kakaoAccount = (java.util.Map<String, Object>) oAuth2User.getAttributes()
                    .get("kakao_account");
            if (kakaoAccount != null) {
                email = (String) kakaoAccount.get("email");
            }
        }

        if (email == null) {
            log.error("Could not find email from OAuth2User attributes: {}", oAuth2User.getAttributes());
            throw new ServletException("Email not found from OAuth2 provider");
        }

        // DB에서 사용자 조회하여 실제 Role 가져오기
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new ServletException("User not found after OAuth2 login"));

        String accessToken = jwtProvider.createAccessToken(email, user.getRole());
        String refreshToken = jwtProvider.createRefreshToken(email);

        long expirationMs = jwtProvider.getRemainingTimeMs(refreshToken);
        redisTemplate.opsForValue().set("RT:" + email, refreshToken, expirationMs,
                java.util.concurrent.TimeUnit.MILLISECONDS);

        // 프론트엔드의 OAuth2 리다이렉트 처리 주소로 토큰 전달
        String targetUrl = UriComponentsBuilder.fromUriString(redirectUrl)
                .queryParam("token", accessToken)
                .queryParam("refreshToken", refreshToken)
                .build().toUriString();

        log.info("OAuth2 login successful for email: {}. Redirecting to: {}", email, targetUrl);
        getRedirectStrategy().sendRedirect(request, response, targetUrl);
    }
}
