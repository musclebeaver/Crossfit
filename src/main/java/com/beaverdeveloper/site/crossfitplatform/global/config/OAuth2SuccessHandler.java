package com.beaverdeveloper.site.crossfitplatform.global.config;

import com.beaverdeveloper.site.crossfitplatform.domain.user.JwtProvider;
import com.beaverdeveloper.site.crossfitplatform.domain.user.UserRole;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.security.oauth2.core.user.OAuth2User;
import org.springframework.security.web.authentication.SimpleUrlAuthenticationSuccessHandler;
import org.springframework.stereotype.Component;
import org.springframework.web.util.UriComponentsBuilder;

import java.io.IOException;

@Component
@RequiredArgsConstructor
public class OAuth2SuccessHandler extends SimpleUrlAuthenticationSuccessHandler {

    private final JwtProvider jwtProvider;

    @org.springframework.beans.factory.annotation.Value("${app.redirect-url}")
    private String redirectUrl;

    @Override
    public void onAuthenticationSuccess(HttpServletRequest request, HttpServletResponse response,
            Authentication authentication) throws IOException, ServletException {
        OAuth2User oAuth2User = (OAuth2User) authentication.getPrincipal();
        String email = (String) oAuth2User.getAttributes().get("email");

        // 카카오의 경우 email이 depth가 깊을 수 있으므로 OAuth2Attributes에서 가져오는 로직이 필요할 수 있으나
        // 여기서는 principal 정보를 통해 간단히 가져옵니다.
        // 실제로는 CustomOAuth2UserService에서 생성한 객체를 타입 캐스팅하여 쓰는 것이 정확합니다.

        // 간단한 구현을 위해 일단 attributes에서 직접 시도 (이후 필요시 수정)
        if (email == null) {
            java.util.Map<String, Object> kakaoAccount = (java.util.Map<String, Object>) oAuth2User.getAttributes()
                    .get("kakao_account");
            if (kakaoAccount != null) {
                email = (String) kakaoAccount.get("email");
            }
        }

        String token = jwtProvider.createToken(email, UserRole.USER);

        // 프론트엔드의 OAuth2 리다이렉트 처리 주소로 토큰 전달
        String targetUrl = UriComponentsBuilder.fromUriString(redirectUrl)
                .queryParam("token", token)
                .build().toUriString();

        getRedirectStrategy().sendRedirect(request, response, targetUrl);
    }
}
