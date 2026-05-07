package com.beaverdeveloper.site.crossfitplatform.domain.user;

import com.beaverdeveloper.site.crossfitplatform.global.common.ApiResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.Builder;
import lombok.Getter;
import lombok.RequiredArgsConstructor;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import org.springframework.web.bind.annotation.*;

@Tag(name = "Authentication", description = "Signup and Login APIs")
@RestController
@RequestMapping("/api/v1/auth")
@RequiredArgsConstructor
public class AuthController {

    private final UserService userService;
    private final SocialAuthService socialAuthService;

    @Operation(summary = "User Signup")
    @PostMapping("/signup")
    public ApiResponse<String> signup(@Valid @RequestBody SignupRequest request) {
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
    public ApiResponse<TokenResponse> login(@Valid @RequestBody LoginRequest request) {
        TokenResponse response = userService.login(request.getEmail(), request.getPassword());
        return ApiResponse.success(response);
    }

    @Operation(summary = "Refresh Token Rotation")
    @PostMapping("/refresh")
    public ApiResponse<TokenResponse> refresh(@Valid @RequestBody RefreshTokenRequest request) {
        TokenResponse response = userService.refresh(request.getRefreshToken());
        return ApiResponse.success(response);
    }

    @Operation(summary = "Social Login with Native SDK Token")
    @PostMapping("/social-login")
    public ApiResponse<TokenResponse> socialLogin(@Valid @RequestBody SocialAuthRequest request) {
        SocialAuthService.OAuth2UserInfo userInfo = socialAuthService.getUserInfo(request.getProvider(), request.getAccessToken());
        TokenResponse response = userService.socialLogin(userInfo);
        return ApiResponse.success(response);
    }

    @Getter
    @Builder
    public static class SignupRequest {
        @NotBlank(message = "Email is required")
        @Email(message = "Invalid email format")
        private String email;

        @NotBlank(message = "Password is required")
        @Size(min = 8, message = "Password must be at least 8 characters")
        private String password;

        @NotBlank(message = "Nickname is required")
        private String nickname;

        private UserRole role;
    }

    @Getter
    @Builder
    public static class LoginRequest {
        @NotBlank(message = "Email is required")
        private String email;

        @NotBlank(message = "Password is required")
        private String password;
    }

    @Getter
    public static class RefreshTokenRequest {
        @NotBlank(message = "Refresh token is required")
        private String refreshToken;
    }

    @Getter
    @lombok.AllArgsConstructor
    public static class TokenResponse {
        private String accessToken;
        private String refreshToken;
    }

    @Getter
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class SocialAuthRequest {
        @jakarta.validation.constraints.NotNull(message = "Provider is required")
        private AuthProvider provider;

        @NotBlank(message = "Access token is required")
        private String accessToken;
    }
}
