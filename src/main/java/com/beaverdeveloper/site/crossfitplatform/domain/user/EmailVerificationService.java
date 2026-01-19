package com.beaverdeveloper.site.crossfitplatform.domain.user;

import com.beaverdeveloper.site.crossfitplatform.global.service.MailService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Random;

@Service
@RequiredArgsConstructor
public class EmailVerificationService {

    private final EmailVerificationRepository emailVerificationRepository;
    private final MailService mailService;

    @Transactional
    public void sendVerificationCode(String email) {
        // 기존 인증 정보가 있다면 삭제 (선택 사항)
        emailVerificationRepository.deleteByEmail(email);

        String code = generateCode();
        EmailVerification verification = EmailVerification.builder()
                .email(email)
                .code(code)
                .expiryDate(LocalDateTime.now().plusMinutes(5)) // 5분 유효
                .isVerified(false)
                .build();

        emailVerificationRepository.save(verification);

        String htmlContent = String.format(
                "<!DOCTYPE html>" +
                        "<html>" +
                        "<head>" +
                        "    <style>" +
                        "        .container { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; max-width: 600px; margin: 0 auto; padding: 40px; border: 1px solid #e0e0e0; border-radius: 12px; }"
                        +
                        "        .header { text-align: center; margin-bottom: 30px; }" +
                        "        .header h1 { color: #E31C25; margin: 0; font-size: 28px; }" +
                        "        .content { line-height: 1.6; color: #333; }" +
                        "        .footer { margin-top: 40px; font-size: 12px; color: #888; text-align: center; border-top: 1px solid #eee; padding-top: 20px; }"
                        +
                        "        .otp-box { background-color: #f8f9fa; border: 2px dashed #E31C25; border-radius: 10px; padding: 20px; text-align: center; margin: 30px 0; }"
                        +
                        "        .otp-code { font-size: 42px; font-weight: bold; color: #E31C25; letter-spacing: 12px; margin: 0; }"
                        +
                        "        .highlight { color: #E31C25; font-weight: bold; }" +
                        "    </style>" +
                        "</head>" +
                        "<body>" +
                        "    <div class='container'>" +
                        "        <div class='header'>" +
                        "            <h1>CROSSFIT PLATFORM</h1>" +
                        "        </div>" +
                        "        <div class='content'>" +
                        "            <p>안녕하세요! <strong>크로스핏 플랫폼</strong>에 오신 것을 환영합니다.</p>" +
                        "            <p>본인 확인을 위해 아래의 인증 번호를 회원가입 화면에 입력해 주세요.</p>" +
                        "            <div class='otp-box'>" +
                        "                <p class='otp-code'>%s</p>" +
                        "            </div>" +
                        "            <p>인증 번호는 <span class='highlight'>5분 동안만 유효</span>합니다.</p>" +
                        "            <p>만약 본인이 요청하지 않은 메일이라면, 이 메일을 무시해 주시기 바랍니다.</p>" +
                        "        </div>" +
                        "        <div class='footer'>" +
                        "            <p>© 2026 Beaver Developer. All rights reserved.</p>" +
                        "            <p>본 메일은 발신 전용입니다.</p>" +
                        "        </div>" +
                        "    </div>" +
                        "</body>" +
                        "</html>",
                code);

        mailService.sendHtmlEmail(email, "[Crossfit Platform] 이메일 인증 번호 안내", htmlContent);
    }

    @Transactional
    public boolean verifyCode(String email, String code) {
        EmailVerification verification = emailVerificationRepository.findByEmailAndCode(email, code)
                .orElseThrow(() -> new IllegalArgumentException("Invalid email or code"));

        if (verification.isExpired()) {
            throw new IllegalArgumentException("Verification code has expired");
        }

        verification.verify();
        return true;
    }

    private String generateCode() {
        return String.format("%06d", new Random().nextInt(1000000));
    }
}
