package com.beaverdeveloper.site.crossfitplatform.domain.wod;

import com.beaverdeveloper.site.crossfitplatform.global.common.ApiResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.Builder;
import lombok.Getter;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
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
    private final WodService wodService;

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
            @RequestParam String type,
            @RequestParam(required = false) String requirements) {
        return ApiResponse.success(wodAiService.suggestWod(boxName, type, requirements));
    }

    @Operation(summary = "Create and Save AI WOD (Coach/Admin Only)")
    @PostMapping("/ai-create")
    public ApiResponse<WodResponse> createAiWod(
            @RequestParam(required = false) Long boxId,
            @RequestParam String boxName,
            @RequestParam String type,
            @RequestParam(required = false) String requirements,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        Wod wod = wodService.createAiWod(boxId, boxName, type, requirements, date != null ? date : LocalDate.now());
        return ApiResponse.success(WodResponse.from(wod));
    }

    @Operation(summary = "Create or Update Manual WOD (Coach/Admin Only)")
    @PostMapping("/manual")
    public ApiResponse<WodResponse> upsertManualWod(@RequestBody WodManualRequest request) {
        Wod wod = wodService.upsertManualWod(request);
        return ApiResponse.success(WodResponse.from(wod));
    }

    @Operation(summary = "Delete WOD (Coach/Admin Only)")
    @DeleteMapping("/{id}")
    public ApiResponse<String> deleteWod(@PathVariable Long id) {
        wodRepository.deleteById(id);
        return ApiResponse.success("WOD deleted successfully");
    }

    public static class WodManualRequest {
        private Long id; // Null for new WOD
        private Long boxId;
        private WodType type;
        private String title;
        private String description;
        private Integer timeCap;
        private LocalDate date;

        public Long getId() {
            return id;
        }

        public Long getBoxId() {
            return boxId;
        }

        public WodType getType() {
            return type;
        }

        public String getTitle() {
            return title;
        }

        public String getDescription() {
            return description;
        }

        public Integer getTimeCap() {
            return timeCap;
        }

        public LocalDate getDate() {
            return date;
        }
    }

    public static class WodResponse {
        private Long id;
        private WodType type;
        private String title;
        private String description;
        private Integer timeCap;
        private Long boxId;
        private LocalDate date;

        public WodResponse(Long id, WodType type, String title, String description, Integer timeCap, Long boxId,
                LocalDate date) {
            this.id = id;
            this.type = type;
            this.title = title;
            this.description = description;
            this.timeCap = timeCap;
            this.boxId = boxId;
            this.date = date;
        }

        public static WodResponse from(Wod wod) {
            return new WodResponse(
                    wod.getId(),
                    wod.getType(),
                    wod.getTitle(),
                    wod.getDescription(),
                    wod.getTimeCap(),
                    wod.getBoxId(),
                    wod.getDate());
        }

        // Getters
        public Long getId() {
            return id;
        }

        public WodType getType() {
            return type;
        }

        public String getTitle() {
            return title;
        }

        public String getDescription() {
            return description;
        }

        public Integer getTimeCap() {
            return timeCap;
        }

        public Long getBoxId() {
            return boxId;
        }

        public LocalDate getDate() {
            return date;
        }
    }
}
