package com.beaverdeveloper.site.crossfitplatform.domain.app;

import com.beaverdeveloper.site.crossfitplatform.domain.user.User;
import com.beaverdeveloper.site.crossfitplatform.domain.user.UserRepository;
import com.beaverdeveloper.site.crossfitplatform.global.common.ApiResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.RequiredArgsConstructor;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Repository;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@Repository
interface ReportRepository extends JpaRepository<Report, Long> {
}

@Tag(name = "Report", description = "User reporting and moderation APIs")
@RestController
@RequestMapping("/api/v1/reports")
@RequiredArgsConstructor
class ReportController {

    private final ReportRepository reportRepository;
    private final UserRepository userRepository;

    @Operation(summary = "Report a User")
    @PostMapping
    public ApiResponse<Void> report(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestBody ReportRequest request) {
        
        User reporter = userRepository.findByEmail(userDetails.getUsername())
                .orElseThrow(() -> new IllegalArgumentException("Reporter not found"));

        Report report = Report.builder()
                .reporterId(reporter.getId())
                .reportedUserId(request.getReportedUserId())
                .reason(request.getReason())
                .details(request.getDetails())
                .build();

        reportRepository.save(report);
        return ApiResponse.success(null);
    }

    @Getter
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ReportRequest {
        private Long reportedUserId;
        private String reason;
        private String details;
    }
}
