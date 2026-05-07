package com.beaverdeveloper.site.crossfitplatform.domain.wod;

import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;

@Slf4j
@Service
@RequiredArgsConstructor
public class WodService {

    private final WodRepository wodRepository;
    private final WodAiService wodAiService;
    private final ObjectMapper objectMapper;
    private final com.beaverdeveloper.site.crossfitplatform.domain.notification.NotificationService notificationService;
    private final com.beaverdeveloper.site.crossfitplatform.domain.user.UserRepository userRepository;

    @Transactional
    public Wod createAiWod(Long boxId, String boxName, String type, String requirements, LocalDate date) {
        try {
            String aiResponse = wodAiService.suggestWod(boxName, type, requirements);
            WodAiResponse response = objectMapper.readValue(aiResponse, WodAiResponse.class);

            Wod wod = Wod.builder()
                    .type(WodType.valueOf(response.getType()))
                    .title(response.getTitle())
                    .description(response.getDescription())
                    .timeCap(response.getTimeCap())
                    .boxId(boxId)
                    .date(date)
                    .build();

            Wod savedWod = wodRepository.save(wod);
            notifyBoxMembers(boxId, "오늘의 와드가 등록되었습니다!", response.getTitle());
            return savedWod;
        } catch (Exception e) {
            log.error("AI WOD creation failed for boxId: {}, type: {}", boxId, type, e);
            throw new RuntimeException("AI WOD 생성에 실패했습니다: " + e.getMessage());
        }
    }

    @Transactional
    public Wod upsertManualWod(WodController.WodManualRequest request) {
        Wod wod;
        if (request.getId() != null) {
            wod = wodRepository.findById(request.getId())
                    .orElseThrow(() -> new IllegalArgumentException("WOD not found"));

            wod = Wod.builder()
                    .id(wod.getId())
                    .type(request.getType())
                    .title(request.getTitle())
                    .description(request.getDescription())
                    .timeCap(request.getTimeCap())
                    .boxId(request.getBoxId())
                    .date(request.getDate())
                    .build();
        } else {
            wod = Wod.builder()
                    .type(request.getType())
                    .title(request.getTitle())
                    .description(request.getDescription())
                    .timeCap(request.getTimeCap())
                    .boxId(request.getBoxId())
                    .date(request.getDate())
                    .build();
        }
        Wod savedWod = wodRepository.save(wod);
        
        // Notify members if newly created (no ID previously or just notify update anyway)
        notifyBoxMembers(request.getBoxId(), "코치님이 와드를 업데이트했습니다!", request.getTitle());
        
        return savedWod;
    }
    
    private void notifyBoxMembers(Long boxId, String title, String body) {
        if (boxId == null) return;
        java.util.List<com.beaverdeveloper.site.crossfitplatform.domain.user.User> members = userRepository.findAllByBoxId(boxId);
        for (com.beaverdeveloper.site.crossfitplatform.domain.user.User user : members) {
            String token = user.getFcmToken();
            if (token != null && !token.isEmpty()) {
                notificationService.sendPushNotification(token, title, body);
            }
        }
    }

    @lombok.Getter
    @lombok.Setter
    @lombok.NoArgsConstructor
    public static class WodAiResponse {
        private String title;
        private String description;
        private String type;
        private Integer timeCap;
    }
}
