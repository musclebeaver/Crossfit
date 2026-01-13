package com.beaverdeveloper.site.crossfitplatform.domain.wod;

import com.beaverdeveloper.site.crossfitplatform.global.common.ApiResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.Builder;
import lombok.Getter;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDate;
import java.util.List;
import java.util.stream.Collectors;

@Tag(name = "WOD", description = "Workout of the Day APIs")
@RestController
@RequestMapping("/api/v1/wods")
@RequiredArgsConstructor
public class WodController {

    private final WodRepository wodRepository;
    private final WodAiService wodAiService;

    @Operation(summary = "Get WODs by date and box")
    @GetMapping
    public ApiResponse<List<WodResponse>> getWods(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date,
            @RequestParam(required = false) Long boxId) {

        List<Wod> wods;
        if (boxId != null) {
            wods = wodRepository.findAllByBoxIdAndDate(boxId, date);
        } else {
            wods = wodRepository.findAllByDate(date);
        }

        List<WodResponse> response = wods.stream()
                .map(WodResponse::from)
                .collect(Collectors.toList());

        return ApiResponse.success(response);
    }

    @Operation(summary = "Get AI WOD Recommendation (Coach/Admin Only)")
    @GetMapping("/ai-recommend")
    public ApiResponse<String> suggestAiWod(
            @RequestParam String boxName,
            @RequestParam String type) {
        return ApiResponse.success(wodAiService.suggestWod(boxName, type));
    }

    @Getter
    @Builder
    public static class WodResponse {
        private Long id;
        private WodType type;
        private String title;
        private String description;
        private Integer timeCap;
        private Long boxId;
        private LocalDate date;

        public static WodResponse from(Wod wod) {
            return WodResponse.builder()
                    .id(wod.getId())
                    .type(wod.getType())
                    .title(wod.getTitle())
                    .description(wod.getDescription())
                    .timeCap(wod.getTimeCap())
                    .boxId(wod.getBoxId())
                    .date(wod.getDate())
                    .build();
        }
    }
}
