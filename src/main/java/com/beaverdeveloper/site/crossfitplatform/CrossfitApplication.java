package com.beaverdeveloper.site.crossfitplatform;

import com.beaverdeveloper.site.crossfitplatform.domain.user.User;
import com.beaverdeveloper.site.crossfitplatform.domain.user.UserRepository;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.util.List;

@EnableJpaAuditing
@org.springframework.scheduling.annotation.EnableScheduling
@SpringBootApplication
public class CrossfitApplication {
    public static void main(String[] args) {
        SpringApplication.run(CrossfitApplication.class, args);
    }

    @Bean
    public CommandLineRunner runner(UserRepository userRepository, PasswordEncoder passwordEncoder) {
        return args -> {
            List<User> users = userRepository.findAll();
            // 패스워드 다 test로 변경 테스트
            String encodedPassword = passwordEncoder.encode("test");
            for (User user : users) {
                user.updatePassword(encodedPassword);
                userRepository.save(user);
            }
            System.out.println("DEBUG: All user passwords reset to 'test' for " + users.size() + " users.");
        };
    }
}
