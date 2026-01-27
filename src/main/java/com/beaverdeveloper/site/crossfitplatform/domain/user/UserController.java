package com.beaverdeveloper.site.crossfitplatform.domain.user;

import com.beaverdeveloper.site.crossfitplatform.global.common.ApiResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.Builder;
import lombok.Getter;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

@Tag(name = "User", description = "User profile and management APIs")
@RestController
@RequestMapping("/api/v1/users")
@RequiredArgsConstructor
public class UserController {

    private final UserRepository userRepository;
    private final UserService userService;

    @Operation(summary = "Get Current User Profile")
    @GetMapping("/me")
    public ApiResponse<UserProfileResponse> getProfile(@AuthenticationPrincipal UserDetails userDetails) {
        User user = userRepository.findByEmail(userDetails.getUsername())
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        return ApiResponse.success(UserProfileResponse.builder()
                .id(user.getId())
                .email(user.getEmail())
                .nickname(user.getNickname())
                .role(user.getRole())
                .boxId(user.getBoxId())
                .points(user.getPoints())
                .tier(user.getTier())
                .build());
    }

    @Operation(summary = "Update Nickname")
    @PatchMapping("/nickname")
    public ApiResponse<Void> updateNickname(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestBody UpdateNicknameRequest request) {
        userService.updateNickname(userDetails.getUsername(), request.getNickname());
        return ApiResponse.success(null);
    }

    @Operation(summary = "Update Password")
    @PatchMapping("/password")
    public ApiResponse<Void> updatePassword(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestBody UpdatePasswordRequest request) {
        userService.updatePassword(userDetails.getUsername(), request.getOldPassword(), request.getNewPassword());
        return ApiResponse.success(null);
    }

    @Operation(summary = "Upgrade to Premium")
    @PostMapping("/upgrade")
    public ApiResponse<Void> upgrade(@AuthenticationPrincipal UserDetails userDetails) {
        userService.upgradeToPremium(userDetails.getUsername());
        return ApiResponse.success(null);
    }

    @Getter
    public static class UpdateNicknameRequest {
        private String nickname;
    }

    @Getter
    public static class UpdatePasswordRequest {
        private String oldPassword;
        private String newPassword;
    }

    @Getter
    @Builder
    public static class UserProfileResponse {
        private Long id;
        private String email;
        private String nickname;
        private UserRole role;
        private Long boxId;
        private Long points;
        private UserTier tier;
    }
}
