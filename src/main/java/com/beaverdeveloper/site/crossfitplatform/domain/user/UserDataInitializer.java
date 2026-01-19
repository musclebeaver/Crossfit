package com.beaverdeveloper.site.crossfitplatform.domain.user;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

@Slf4j
@Component
@RequiredArgsConstructor
public class UserDataInitializer implements CommandLineRunner {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    @Override
    @Transactional
    public void run(String... args) {
        String encodedPassword = passwordEncoder.encode("test");

        for (int i = 1; i <= 20; i++) {
            String email = "test" + i + "@naver.com";
            if (userRepository.findByEmail(email).isEmpty()) {
                UserRole role = (i <= 10) ? UserRole.USER : UserRole.COACH;
                User user = User.builder()
                        .email(email)
                        .password(encodedPassword)
                        .nickname("Tester " + i)
                        .role(role)
                        .isVerified(true)
                        .build();

                userRepository.save(user);
                log.info("Initialized test user: {} with role: {}", email, role);
            }
        }
        log.info("Test user initialization completed.");
    }
}
