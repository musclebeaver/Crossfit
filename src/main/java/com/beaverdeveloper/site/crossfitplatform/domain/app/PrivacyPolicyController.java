package com.beaverdeveloper.site.crossfitplatform.domain.app;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class PrivacyPolicyController {

    @GetMapping("/privacy-policy")
    public String getPrivacyPolicy() {
        return """
                <html>
                <head><title>Privacy Policy - CrossFit Platform</title></head>
                <body style="font-family: sans-serif; padding: 20px; line-height: 1.6;">
                    <h1>개인정보 처리방침 (Privacy Policy)</h1>
                    <p>본 CROSSFIT PLATFORM 서비스는 사용자의 개인정보를 소중히 다루며, 관련 법령을 준수합니다.</p>
                    
                    <h2>1. 수집하는 개인정보 항목</h2>
                    <ul>
                        <li>필수 항목: 이메일, 닉네임, 프로필 사진(소셜 로그인 시)</li>
                        <li>자동 수집 항목: 서비스 이용 기록, 접속 로그, 쿠키, FCM 토큰</li>
                    </ul>

                    <h2>2. 개인정보의 수집 및 이용 목적</h2>
                    <ul>
                        <li>서비스 제공 및 회원 관리</li>
                        <li>와드 기록 저장 및 랭킹 시스템 운영</li>
                        <li>푸시 알림 발송 (WOD 등록, 랭킹 변동 등)</li>
                    </ul>

                    <h2>3. 개인정보의 보유 및 이용 기간</h2>
                    <p>회원 탈퇴 시까지 보유하며, 탈퇴 시 지체 없이 파기합니다. 단, 관련 법령에 의해 보존할 필요가 있는 경우 해당 기간 동안 보관합니다.</p>

                    <h2>4. 사용자의 권리 (회원 탈퇴)</h2>
                    <p>사용자는 앱 내 '회원 탈퇴' 기능을 통해 언제든지 자신의 계정과 데이터를 영구적으로 삭제할 수 있습니다.</p>

                    <p>마지막 업데이트: 2026년 4월 15일</p>
                </body>
                </html>
                """;
    }

    @GetMapping("/terms-of-service")
    public String getTermsOfService() {
        return """
                <html>
                <head><title>Terms of Service - CrossFit Platform</title></head>
                <body style="font-family: sans-serif; padding: 20px; line-height: 1.6;">
                    <h1>서비스 이용약관 (Terms of Service)</h1>
                    <p>본 CROSSFIT PLATFORM 서비스를 이용해 주셔서 감사합니다.</p>
                    
                    <h2>1. 서비스의 목적</h2>
                    <p>본 서비스는 크로스핏 와드(WOD) 관리, 기록 저장 및 박스 내 랭킹 시스템을 제공합니다.</p>

                    <h2>2. 사용자 생성 콘텐츠 (UGC) 정책</h2>
                    <ul>
                        <li>사용자는 타인에게 불쾌감을 주는 닉네임, 기록, 이미지 등을 게시해서는 안 됩니다.</li>
                        <li>부적절한 콘텐츠 게시 시, 관리자에 의해 삭제되거나 서비스 이용이 제한될 수 있습니다.</li>
                        <li>사용자는 부적절한 사용자나 콘텐츠를 신고 및 차단할 수 있는 기능을 사용할 수 있습니다.</li>
                    </ul>

                    <h2>3. 책임의 제한</h2>
                    <p>본 서비스는 운동 기록 관리 도구이며, 실제 운동 시 발생하는 부상이나 사고에 대해서는 책임을 지지 않습니다. 안전에 유의하여 이용해 주시기 바랍니다.</p>

                    <h2>4. 약관의 개정</h2>
                    <p>서비스 운영상 필요한 경우 약관을 개정할 수 있으며, 개정 시 공지사항을 통해 알립니다.</p>

                    <p>마지막 업데이트: 2026년 4월 15일</p>
                </body>
                </html>
                """;
    }
}
