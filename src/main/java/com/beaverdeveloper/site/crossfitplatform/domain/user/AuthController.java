package com.beaverdeveloper.site.crossfitplatform.domain.user;

import com.beaverdeveloper.site.crossfitplatform.global.common.ApiResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.Builder;
import lombok.Getter;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.bind.annotation.RestController;

@Tag(name = "Authentication", description = "Signup and Login APIs")
@RestController
@RequestMapping("/api/v1/auth")
@RequiredArgsConstructor
public class AuthController {

    private final UserService userService;

    @Operation(summary = "User Signup")
    @PostMapping("/signup")
    public ApiResponse<String> signup(@RequestBody SignupRequest request) {
        userService.signUp(request.getEmail(), request.getPassword(), request.getNickname(), request.getRole());
        return ApiResponse.success("Signup completed");
    }

    @Operation(summary = "Check Email Duplication")
    @GetMapping("/check-email")
    public ApiResponse<Boolean> checkEmail(@RequestParam String email) {
        return ApiResponse.success(userService.isEmailDuplicated(email));
    }

    @Operation(summary = "User Login")
    @PostMapping("/login")
    public ApiResponse<String> login(@RequestBody LoginRequest request) {
        String token = userService.login(request.getEmail(), request.getPassword());
        return ApiResponse.success(token);
    }

    @Getter
    @Builder
    public static class SignupRequest {
        private String email;
        private String password;
        private String nickname;
        private UserRole role;
    }

    @Getter
    @Builder
    public static class LoginRequest {
        private String email;
        private String password;
    }
}
