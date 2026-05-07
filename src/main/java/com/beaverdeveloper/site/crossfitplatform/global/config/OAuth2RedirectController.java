package com.beaverdeveloper.site.crossfitplatform.global.config;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.view.RedirectView;

@Controller
public class OAuth2RedirectController {

    @GetMapping("/oauth2/redirect")
    public RedirectView redirect(@RequestParam String token, @RequestParam(required = false) String refreshToken) {
        // 실제 운영 환경에서는 프론트엔드 URL로 변경해야 함
        // 현재는 로컬 개발 환경이므로 폼 로그인 등으로 리다이렉트되지 않도록
        // 토큰을 포함하여 프론트엔드가 실행 중인 주소로 보냅니다.
        // 만약 Flutter Web이 특정 포트에서 실행 중이라면 해당 주소로 리다이렉트가 필요할 수 있습니다.

        // 일단은 루트("/")로 리다이렉트하여 Flutter 앱이 토큰을 읽을 수 있게 시도합니다.
        // (Spring Boot가 Flutter build 결과물을 서빙하는 경우 유효)
        
        String redirectUrl = "/?token=" + token;
        if (refreshToken != null) {
            redirectUrl += "&refreshToken=" + refreshToken;
        }
        return new RedirectView(redirectUrl);
    }
}
