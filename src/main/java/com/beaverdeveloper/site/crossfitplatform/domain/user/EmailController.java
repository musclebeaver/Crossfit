package com.beaverdeveloper.site.crossfitplatform.domain.user;

import com.beaverdeveloper.site.crossfitplatform.global.common.ApiResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.Getter;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

@Tag(name = "Email Verification", description = "Email OTP Verification APIs")
@RestController
@RequestMapping("/api/v1/auth/email")
@RequiredArgsConstructor
public class EmailController {

    private final EmailVerificationService emailVerificationService;

    @Operation(summary = "Send Verification Code to Email")
    @PostMapping("/send")
    public ApiResponse<String> sendVerificationCode(@RequestBody EmailRequest request) {
        emailVerificationService.sendVerificationCode(request.getEmail());
        return ApiResponse.success("인증 번호가 발송되었습니다.");
    }

    @Operation(summary = "Verify Email with Code")
    @PostMapping("/verify")
    public ApiResponse<Boolean> verifyCode(@RequestBody EmailVerifyRequest request) {
        boolean result = emailVerificationService.verifyCode(request.getEmail(), request.getCode());
        return ApiResponse.success(result);
    }

    @Getter
    public static class EmailRequest {
        private String email;
    }

    @Getter
    public static class EmailVerifyRequest {
        private String email;
        private String code;
    }
}
