package com.beaverdeveloper.site.crossfitplatform.global.init;

import com.beaverdeveloper.site.crossfitplatform.domain.box.Box;
import com.beaverdeveloper.site.crossfitplatform.domain.box.BoxRepository;
import com.beaverdeveloper.site.crossfitplatform.domain.record.Record;
import com.beaverdeveloper.site.crossfitplatform.domain.record.RecordService;
import com.beaverdeveloper.site.crossfitplatform.domain.user.User;
import com.beaverdeveloper.site.crossfitplatform.domain.user.UserRepository;
import com.beaverdeveloper.site.crossfitplatform.domain.user.UserRole;
import com.beaverdeveloper.site.crossfitplatform.domain.wod.Wod;
import com.beaverdeveloper.site.crossfitplatform.domain.wod.WodRepository;
import com.beaverdeveloper.site.crossfitplatform.domain.wod.WodType;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Profile;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Random;

@Slf4j
@Component
@Profile({ "local", "dev", "prod" })
@RequiredArgsConstructor
public class DummyDataInit implements CommandLineRunner {

    private final UserRepository userRepository;
    private final BoxRepository boxRepository;
    private final WodRepository wodRepository;
    private final RecordService recordService;
    private final PasswordEncoder passwordEncoder;

    @Override
    @Transactional
    public void run(String... args) throws Exception {
        if (userRepository.count() > 0) {
            log.info("Dummy data already exists. Skipping initialization.");
            return;
        }

        log.info("Generating dummy data for DB and Redis Rankings...");
        Random random = new Random();
        String defaultPassword = passwordEncoder.encode("1234");

        // 1. Admin 계정 3명 생성
        List<User> admins = new ArrayList<>();
        for (int i = 1; i <= 3; i++) {
            User admin = User.builder()
                    .email("admin" + i + "@test.com")
                    .password(defaultPassword)
                    .nickname("PlatformAdmin" + i)
                    .role(UserRole.ADMIN)
                    .build();
            admins.add(userRepository.save(admin));
        }

        // 2. Coach 계정 10명 생성
        List<User> coaches = new ArrayList<>();
        for (int i = 1; i <= 10; i++) {
            User coach = User.builder()
                    .email("coach" + i + "@test.com")
                    .password(defaultPassword)
                    .nickname("MasterCoach" + i)
                    .role(UserRole.COACH)
                    .build();
            coaches.add(userRepository.save(coach));
        }

        // 3. 체육관(Box) 10개 생성 (코치당 1개씩)
        List<Box> boxes = new ArrayList<>();
        for (int i = 0; i < 10; i++) {
            Box box = Box.builder()
                    .name("CrossFit Box " + (i + 1))
                    .location("City Zone " + (i + 1))
                    .description("The best box number " + (i + 1))
                    .owner(coaches.get(i))
                    .build();
            box = boxRepository.save(box);
            boxes.add(box);
            
            // 코치의 소속 Box 지정
            coaches.get(i).updateBox(box.getId());
            userRepository.save(coaches.get(i));
        }

        // 4. 일반 유저 30명 생성 (각 박스당 3명씩)
        List<User> users = new ArrayList<>();
        for (int i = 1; i <= 30; i++) {
            User u = User.builder()
                    .email("user" + i + "@test.com")
                    .password(defaultPassword)
                    .nickname("Athlete" + i)
                    .role(UserRole.USER)
                    .build();
            
            // 박스 분산 배치: (i - 1) / 3 으로 박스 인덱스 계산 (0 ~ 9)
            int boxIndex = (i - 1) / 3;
            u.updateBox(boxes.get(boxIndex).getId());
            users.add(userRepository.save(u));
        }

        // 5. WOD (오늘의 운동) 2개 생성
        // WOD 1: 글로벌 AMRAP
        Wod wod1 = Wod.builder()
                .title("Cindy (Global AMRAP)")
                .description("AMRAP 20 mins: 5 pull-ups, 10 push-ups, 15 squats")
                .type(WodType.AMRAP)
                .timeCap(1200)
                .date(LocalDate.now().minusDays(1)) // 어제 날짜로 세팅하여 스케줄러 정산 테스트용으로 사용
                .isAiGenerated(false)
                .build();
        wod1 = wodRepository.save(wod1);

        // WOD 2: 특정 박스 (Box 1) 전용 FOR TIME
        Box targetBoxForWod2 = boxes.get(0);
        Wod wod2 = Wod.builder()
                .title("Fran (Box Only)")
                .description("21-15-9 Thrusters(95lb), Pull-ups")
                .type(WodType.FOR_TIME)
                .timeCap(600)
                .date(LocalDate.now())
                .boxId(targetBoxForWod2.getId())
                .isAiGenerated(false)
                .build();
        wod2 = wodRepository.save(wod2);

        // 6. 유저들의 기록 생성 (RecordService)
        for (User u : users) {
             // 글로벌 WOD 1 기록
            double reps = 100 + random.nextInt(200);
            boolean rx = random.nextBoolean();

            Record r1 = Record.builder()
                    .wod(wod1)
                    .resultValue(reps)
                    .isRx(rx)
                    .isCapped(false)
                    .userId(u.getId())
                    .build();
            recordService.registerRecord(r1);

            // 박스 WOD 2 기록 (Box 1 소속 유저만 참여)
            if (u.getBoxId() != null && u.getBoxId().equals(targetBoxForWod2.getId())) {
                double time = 180 + random.nextInt(300);
                boolean rx2 = random.nextBoolean();
                boolean capped = random.nextInt(10) > 8;
                if (capped) time = 600;

                Record r2 = Record.builder()
                        .wod(wod2)
                        .resultValue(time)
                        .isRx(rx2)
                        .isCapped(capped)
                        .userId(u.getId())
                        .build();
                recordService.registerRecord(r2);
            }
        }

        log.info("Successfully generated Test Data! (3 Admins, 10 Coaches, 30 Users, 10 Boxes, 2 WODs)");
    }
}
