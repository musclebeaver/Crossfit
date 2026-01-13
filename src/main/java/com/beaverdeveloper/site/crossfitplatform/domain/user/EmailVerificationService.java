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

        mailService.sendEmail(email, "[Crossfit Platform] 이메일 인증 번호",
                "인증 번호: " + code + "\n5분 이내에 입력해 주세요.");
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
