package com.beaverdeveloper.site.crossfitplatform.domain.box;

import com.beaverdeveloper.site.crossfitplatform.global.common.ApiResponse;
import com.beaverdeveloper.site.crossfitplatform.domain.user.User;
import com.beaverdeveloper.site.crossfitplatform.domain.user.UserRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.stream.Collectors;

@Tag(name = "Box Management", description = "Box registration and membership management APIs")
@RestController
@RequestMapping("/api/v1/boxes")
@RequiredArgsConstructor
public class BoxController {

    private final BoxService boxService;
    private final UserRepository userRepository;
    private final BoxRepository boxRepository;
    private final BoxMemberRepository boxMemberRepository;

    @Operation(summary = "Get My Owned Boxes (Coach Only)")
    @GetMapping("/mine")
    public ApiResponse<List<BoxResponse>> getMyOwnedBoxes(@AuthenticationPrincipal UserDetails userDetails) {
        User user = userRepository.findByEmail(userDetails.getUsername())
                .orElseThrow(() -> new IllegalArgumentException("User not found"));
        List<Box> boxes = boxRepository.findByOwner(user);
        return ApiResponse.success(boxes.stream().map(BoxResponse::from).toList());
    }

    @Operation(summary = "Get My Membership Status")
    @GetMapping("/my-status")
    public ApiResponse<MemberStatusResponse> getMyMembershipStatus(@AuthenticationPrincipal UserDetails userDetails) {
        User user = userRepository.findByEmail(userDetails.getUsername())
                .orElseThrow(() -> new IllegalArgumentException("User not found"));
        return ApiResponse.success(boxService.getMembershipStatus(user.getId()));
    }

    @Operation(summary = "Search Boxes by Name")
    @GetMapping("/search")
    public ApiResponse<List<BoxResponse>> searchBoxes(@RequestParam String name) {
        List<Box> boxes = boxService.searchBoxes(name);
        List<BoxResponse> response = boxes.stream()
                .map(BoxResponse::from)
                .collect(Collectors.toList());
        return ApiResponse.success(response);
    }

    @Operation(summary = "Register a new Box (Coach Only)")
    @PostMapping
    public ApiResponse<Long> registerBox(
            @RequestBody BoxRegisterRequest request,
            @AuthenticationPrincipal UserDetails userDetails) {

        User user = userRepository.findByEmail(userDetails.getUsername())
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        Box box = Box.builder()
                .name(request.getName())
                .location(request.getLocation())
                .businessNumber(request.getBusinessNumber())
                .isVerified(false)
                .owner(user)
                .build();

        return ApiResponse.success(boxRepository.save(box).getId());
    }

    @Operation(summary = "Apply for Box Membership")
    @PostMapping("/{boxId}/apply")
    public ApiResponse<String> applyBox(
            @PathVariable Long boxId,
            @AuthenticationPrincipal UserDetails userDetails) {

        User user = userRepository.findByEmail(userDetails.getUsername())
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        Box box = boxRepository.findById(boxId)
                .orElseThrow(() -> new IllegalArgumentException("Box not found"));

        BoxMember member = BoxMember.builder()
                .box(box)
                .user(user)
                .status(BoxMemberStatus.PENDING)
                .build();

        boxMemberRepository.save(member);
        return ApiResponse.success("Application submitted");
    }

    @Operation(summary = "Get Pending Members (Box Owner Only)")
    @GetMapping("/{boxId}/members/pending")
    public ApiResponse<List<MemberResponse>> getPendingMembers(@PathVariable Long boxId) {
        List<BoxMember> members = boxService.getPendingMembers(boxId);
        List<MemberResponse> response = members.stream()
                .map(m -> new MemberResponse(m.getId(), m.getUser().getNickname(), m.getStatus()))
                .collect(Collectors.toList());
        return ApiResponse.success(response);
    }

    @Operation(summary = "Approve/Reject Member")
    @PostMapping("/members/{memberId}/approve")
    public ApiResponse<String> approveMember(
            @PathVariable Long memberId,
            @RequestParam boolean approve) {

        if (approve) {
            boxService.approveMember(memberId);
        } else {
            boxService.rejectMember(memberId);
        }
        return ApiResponse.success("Process completed");
    }

    @Getter
    public static class BoxRegisterRequest {
        private String name;
        private String location;
        private String businessNumber;
    }

    @Getter
    @Builder
    @AllArgsConstructor
    public static class BoxResponse {
        private Long id;
        private String name;
        private String location;
        private boolean isVerified;

        public static BoxResponse from(Box box) {
            return BoxResponse.builder()
                    .id(box.getId())
                    .name(box.getName())
                    .location(box.getLocation())
                    .isVerified(box.isVerified())
                    .build();
        }
    }

    @Getter
    @Builder
    @AllArgsConstructor
    public static class MemberStatusResponse {
        private Long boxId;
        private String boxName;
        private BoxMemberStatus status;
    }

    @Getter
    @AllArgsConstructor
    public static class MemberResponse {
        private Long memberId;
        private String nickname;
        private BoxMemberStatus status;
    }
}
