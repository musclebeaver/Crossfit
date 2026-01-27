package com.beaverdeveloper.site.crossfitplatform.domain.user;

import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class UserService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtProvider jwtProvider;
    private final EmailVerificationRepository emailVerificationRepository;
    private final LoginAttemptService loginAttemptService;

    @org.springframework.beans.factory.annotation.Value("${app.auth.verify-email}")
    private boolean verifyEmailEnabled;

    @Transactional
    public void signUp(String email, String password, String nickname, UserRole role) {
        if (userRepository.existsByEmail(email)) {
            throw new IllegalArgumentException("Email already exists");
        }

        if (verifyEmailEnabled && !emailVerificationRepository.existsByEmailAndIsVerifiedTrue(email)) {
            throw new IllegalArgumentException("Email verification is required");
        }

        // 비밀번호 복잡도 검증 (8자 이상, 영문+숫자+특수문자)
        if (!isValidPassword(password)) {
            throw new IllegalArgumentException(
                    "Password must be at least 8 characters long and contain letters, numbers, and special characters.");
        }

        User user = User.builder()
                .email(email)
                .password(passwordEncoder.encode(password))
                .nickname(nickname)
                .role(role)
                .build();

        userRepository.save(user);
    }

    private boolean isValidPassword(String password) {
        if (password == null || password.length() < 8)
            return false;
        String regex = "^(?=.*[A-Za-z])(?=.*\\d)(?=.*[@$!%*#?&])[A-Za-z\\d@$!%*#?&]{8,}$";
        return password.matches(regex);
    }

    public boolean isEmailDuplicated(String email) {
        return userRepository.existsByEmail(email);
    }

    public String login(String email, String password) {
        if (loginAttemptService.isBlocked(email)) {
            throw new IllegalArgumentException("Too many login attempts. Please try again after 15 minutes.");
        }

        try {
            User user = userRepository.findByEmail(email)
                    .orElseThrow(() -> new IllegalArgumentException("Invalid email or password"));

            if (!passwordEncoder.matches(password, user.getPassword()) || user.getProvider() != AuthProvider.LOCAL) {
                throw new IllegalArgumentException("Invalid email or password");
            }

            loginAttemptService.loginSucceeded(email);
            return jwtProvider.createToken(user.getEmail(), user.getRole());
        } catch (IllegalArgumentException e) {
            loginAttemptService.loginFailed(email);
            throw e;
        }
    }

    @Transactional
    public void updateNickname(String email, String newNickname) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));
        user.updateNickname(newNickname);
    }

    @Transactional
    public void updatePassword(String email, String oldPassword, String newPassword) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        if (!passwordEncoder.matches(oldPassword, user.getPassword())) {
            throw new IllegalArgumentException("Invalid current password");
        }

        user.updatePassword(passwordEncoder.encode(newPassword));
    }

    @Transactional
    public void upgradeToPremium(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));
        user.upgradeToPremium();
    }
}
