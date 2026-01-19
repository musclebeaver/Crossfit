package com.beaverdeveloper.site.crossfitplatform.domain.wod;

import com.beaverdeveloper.site.crossfitplatform.domain.box.Box;
import com.beaverdeveloper.site.crossfitplatform.domain.box.BoxRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.LocalDate;
import java.util.List;

@Slf4j
@Component
@RequiredArgsConstructor
public class WodScheduler {

    private final WodService wodService;
    private final BoxRepository boxRepository;
    private final WodRepository wodRepository;

    /**
     * 매일 자정(00:00)에 글로벌 공통 와드 및 박스별 와드를 자동 생성합니다.
     */
    @Scheduled(cron = "0 0 0 * * *")
    public void generateDailyWods() {
        log.info("Starting automated daily WOD generation for {}", LocalDate.now());

        // 1. 글로벌 공통 와드 생성 (boxId = null)
        try {
            if (wodRepository.findAllByDate(LocalDate.now()).stream().noneMatch(w -> w.getBoxId() == null)) {
                wodService.createAiWod(null, "Global Community", "RANDOM", "Balanced workout for everyone",
                        LocalDate.now());
                log.info("Global WOD generated successfully");
            } else {
                log.info("Global WOD already exists for today");
            }
        } catch (Exception e) {
            log.error("Failed to generate Global WOD", e);
        }

        // 2. 각 박스별 와드 생성
        List<Box> boxes = boxRepository.findAll();
        for (Box box : boxes) {
            if (!box.isAutoWodEnabled()) {
                log.info("Automatic WOD generation skip for box: {}", box.getName());
                continue;
            }
            try {
                if (wodRepository.findAllByDate(LocalDate.now()).stream()
                        .noneMatch(w -> box.getId().equals(w.getBoxId()))) {
                    wodService.createAiWod(box.getId(), box.getName(), "RANDOM", null, LocalDate.now());
                    log.info("WOD generated for box: {}", box.getName());
                } else {
                    log.info("WOD already exists for box: {}", box.getName());
                }
            } catch (Exception e) {
                log.error("Failed to generate WOD for box: {}", box.getName(), e);
            }
        }
    }
}
