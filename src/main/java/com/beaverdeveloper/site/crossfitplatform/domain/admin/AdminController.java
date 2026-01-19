package com.beaverdeveloper.site.crossfitplatform.domain.admin;

import com.beaverdeveloper.site.crossfitplatform.domain.box.Box;
import com.beaverdeveloper.site.crossfitplatform.domain.box.BoxRepository;
import com.beaverdeveloper.site.crossfitplatform.domain.user.User;
import com.beaverdeveloper.site.crossfitplatform.domain.user.UserRepository;
import com.beaverdeveloper.site.crossfitplatform.domain.user.UserRole;
import com.beaverdeveloper.site.crossfitplatform.global.common.ApiResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.stream.Collectors;

@Tag(name = "Admin", description = "Platform Administration APIs")
@RestController
@RequestMapping("/api/v1/admin")
@RequiredArgsConstructor
public class AdminController {

    private final BoxRepository boxRepository;
    private final UserRepository userRepository;

    @Operation(summary = "Get all boxes for verification")
    @GetMapping("/boxes")
    public ApiResponse<List<BoxAdminResponse>> getAllBoxes() {
        return ApiResponse.success(boxRepository.findAll().stream()
                .map(BoxAdminResponse::from)
                .collect(Collectors.toList()));
    }

    @Operation(summary = "Verify Box (Business Registration)")
    @PatchMapping("/boxes/{boxId}/verify")
    public ApiResponse<String> verifyBox(@PathVariable Long boxId, @RequestParam boolean verify) {
        Box box = boxRepository.findById(boxId)
                .orElseThrow(() -> new IllegalArgumentException("Box not found"));

        Box updatedBox = Box.builder()
                .id(box.getId())
                .name(box.getName())
                .location(box.getLocation())
                .businessNumber(box.getBusinessNumber())
                .owner(box.getOwner())
                .isVerified(verify)
                .build();

        boxRepository.save(updatedBox);
        return ApiResponse.success("Box verification status updated to: " + verify);
    }

    @Operation(summary = "Get all users")
    @GetMapping("/users")
    public ApiResponse<List<UserAdminResponse>> getAllUsers() {
        return ApiResponse.success(userRepository.findAll().stream()
                .map(UserAdminResponse::from)
                .collect(Collectors.toList()));
    }

    @Getter
    @AllArgsConstructor
    public static class BoxAdminResponse {
        private Long id;
        private String name;
        private String businessNumber;
        private boolean isVerified;
        private String ownerEmail;

        public static BoxAdminResponse from(Box box) {
            return new BoxAdminResponse(box.getId(), box.getName(), box.getBusinessNumber(),
                    box.isVerified(), box.getOwner().getEmail());
        }
    }

    @Getter
    @AllArgsConstructor
    public static class UserAdminResponse {
        private Long id;
        private String email;
        private String nickname;
        private String role;

        public static UserAdminResponse from(User user) {
            return new UserAdminResponse(user.getId(), user.getEmail(), user.getNickname(), user.getRole().name());
        }
    }
}
