package com.beaverdeveloper.site.crossfitplatform.domain.admin;

import com.beaverdeveloper.site.crossfitplatform.global.common.ApiResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.AllArgsConstructor;
import lombok.Getter;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@Tag(name = "App Version", description = "App version and update management APIs")
@RestController
@RequestMapping("/api/v1/app/version")
public class AppVersionController {

    @Value("${app.version.latest}")
    private String latestVersion;

    @Value("${app.version.min}")
    private String minVersion;

    @Value("${app.version.update-url}")
    private String updateUrl;

    @Operation(summary = "Get App Version Info")
    @GetMapping
    public ApiResponse<VersionResponse> getVersionInfo() {
        return ApiResponse.success(new VersionResponse(latestVersion, minVersion, updateUrl));
    }

    @Getter
    @AllArgsConstructor
    public static class VersionResponse {
        private String latestVersion;
        private String minVersion;
        private String updateUrl;
    }
}
