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

                User user = userRepository.findByEmail(userDetails.getUsername())
                                .orElseThrow(() -> new IllegalArgumentException("User not found"));

                Wod wod = wodRepository.findById(request.getWodId())
                                .orElseThrow(() -> new IllegalArgumentException("Wod not found"));

                Record record = Record.builder()
                                .userId(user.getId())
                                .wod(wod)
                                .resultValue(request.getResultValue())
                                .isRx(request.getIsRx())
                                .mediaUrl(request.getMediaUrl())
                                .build();

                return ApiResponse.success(recordService.registerRecord(record));
        }

        @Operation(summary = "Get Real-time Rankings for WOD")
        @GetMapping("/rankings/{wodId}")
        public ApiResponse<List<RankingResponse>> getRankings(
                        @PathVariable Long wodId,
                        @RequestParam(required = false) Long boxId,
                        @RequestParam(defaultValue = "10") int limit) {

                Set<ZSetOperations.TypedTuple<Object>> results = recordService.getTopRankings(wodId, boxId, limit);

                List<RankingResponse> response = results.stream()
                                .map(tuple -> {
                                        Long userId = Long.valueOf((String) tuple.getValue());
                                        String nickname = userRepository.findById(userId)
                                                        .map(User::getNickname)
                                                        .orElse("Unknown");
                                        return new RankingResponse(userId, nickname, tuple.getScore());
                                })
                                .collect(Collectors.toList());

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
        @AllArgsConstructor
        public static class RankingResponse {
                private Long userId;
                private String nickname;
                private Double score;
        }

        @Getter
        @Builder
        public static class RankingHistoryResponse {
                private Long id;
                private Long wodId;
                private Integer rank;
                private Double score;
                private boolean isRx;
                private LocalDate date;

                public static RankingHistoryResponse from(RankingHistory history) {
                        return RankingHistoryResponse.builder()
                                        .id(history.getId())
                                        .wodId(history.getWodId())
                                        .rank(history.getRank())
                                        .score(history.getScore())
                                        .isRx(history.isRx())
                                        .date(history.getDate())
                                        .build();
                }
        }
}
