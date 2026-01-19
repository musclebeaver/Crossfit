package com.beaverdeveloper.site.crossfitplatform.domain.record;

import com.beaverdeveloper.site.crossfitplatform.global.common.ApiResponse;
import com.beaverdeveloper.site.crossfitplatform.domain.user.User;
import com.beaverdeveloper.site.crossfitplatform.domain.user.UserRepository;
import com.beaverdeveloper.site.crossfitplatform.domain.wod.Wod;
import com.beaverdeveloper.site.crossfitplatform.domain.wod.WodRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.*;
import org.springframework.data.redis.core.ZSetOperations;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

@Tag(name = "Record & Ranking", description = "Workout Record and Ranking APIs")
@RestController
@RequestMapping("/api/v1/records")
@RequiredArgsConstructor
public class RecordController {

        private final RecordService recordService;
        private final WodRepository wodRepository;
        private final UserRepository userRepository;
        private final RankingHistoryRepository rankingHistoryRepository;

        @Operation(summary = "Register Exercise Record")
        @PostMapping
        public ApiResponse<Long> registerRecord(
                        @RequestBody RecordRequest request,
                        @AuthenticationPrincipal UserDetails userDetails) {

                if (request.getWodId() == null) {
                        throw new IllegalArgumentException("WOD ID must not be null");
                }

                User user = userRepository.findByEmail(userDetails.getUsername())
                                .orElseThrow(() -> new IllegalArgumentException(
                                                "User not found: " + userDetails.getUsername()));

                Wod wod = wodRepository.findById(request.getWodId())
                                .orElseThrow(() -> new IllegalArgumentException(
                                                "WOD not found with ID: " + request.getWodId()));

                Record record = Record.builder()
                                .userId(user.getId())
                                .wod(wod)
                                .resultValue(request.getResultValue())
                                .isRx(request.getIsRx())
                                .mediaUrl(request.getMediaUrl())
                                .build();

                return ApiResponse.success(recordService.registerRecord(record));
        }

        @Operation(summary = "Get Real-time Rankings for WOD (Paginated)")
        @GetMapping("/rankings/{wodId}")
        public ApiResponse<List<RankingResponse>> getRankings(
                        @PathVariable Long wodId,
                        @RequestParam(required = false) Long boxId,
                        @RequestParam(defaultValue = "0") int page,
                        @RequestParam(defaultValue = "20") int size,
                        @RequestParam(required = false) String nickname) {

                List<RankingResponse> response = recordService.getRankings(wodId, boxId, page, size, nickname);
                return ApiResponse.success(response);
        }

        @Operation(summary = "Get My Ranking History")
        @GetMapping("/history")
        public ApiResponse<List<RankingHistoryResponse>> getMyRankingHistory(
                        @AuthenticationPrincipal UserDetails userDetails) {

                User user = userRepository.findByEmail(userDetails.getUsername())
                                .orElseThrow(() -> new IllegalArgumentException("User not found"));

                List<RankingHistory> histories = rankingHistoryRepository.findAllByUserId(user.getId());

                List<RankingHistoryResponse> response = histories.stream()
                                .map(RankingHistoryResponse::from)
                                .collect(Collectors.toList());

                return ApiResponse.success(response);
        }

        @Getter
        @NoArgsConstructor
        @AllArgsConstructor
        @Builder
        public static class RecordRequest {
                private Long wodId;
                private Double resultValue;
                private Boolean isRx;
                private String mediaUrl;
        }

        @Getter
        public static class RankingResponse {
                private Long userId;
                private String nickname;
                private Double score;
                private Integer rank;
                private String displayValue;
                private boolean isRx;

                public RankingResponse(Long userId, String nickname, Double score, Integer rank, String displayValue,
                                boolean isRx) {
                        this.userId = userId;
                        this.nickname = nickname;
                        this.score = score;
                        this.rank = rank;
                        this.displayValue = displayValue;
                        this.isRx = isRx;
                }

                public RankingResponse() {
                }

                // Manual Getters
                public Long getUserId() {
                        return userId;
                }

                public String getNickname() {
                        return nickname;
                }

                public Double getScore() {
                        return score;
                }

                public Integer getRank() {
                        return rank;
                }

                public String getDisplayValue() {
                        return displayValue;
                }

                public boolean isRx() {
                        return isRx;
                }
        }

        @Getter
        public static class RankingHistoryResponse {
                private Long id;
                private Long wodId;
                private Integer rank;
                private Double score;
                private boolean isRx;
                private LocalDate date;

                public RankingHistoryResponse(Long id, Long wodId, Integer rank, Double score, boolean isRx,
                                LocalDate date) {
                        this.id = id;
                        this.wodId = wodId;
                        this.rank = rank;
                        this.score = score;
                        this.isRx = isRx;
                        this.date = date;
                }

                public static RankingHistoryResponse from(RankingHistory history) {
                        return new RankingHistoryResponse(
                                        history.getId(),
                                        history.getWodId(),
                                        history.getRank(),
                                        history.getScore(),
                                        history.isRx(),
                                        history.getDate());
                }

                // Manual Getters
                public Long getId() {
                        return id;
                }

                public Long getWodId() {
                        return wodId;
                }

                public Integer getRank() {
                        return rank;
                }

                public Double getScore() {
                        return score;
                }

                public boolean isRx() {
                        return isRx;
                }

                public LocalDate getDate() {
                        return date;
                }
        }
}
