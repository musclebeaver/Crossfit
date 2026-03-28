package com.beaverdeveloper.site.crossfitplatform.domain.user;

import lombok.RequiredArgsConstructor;
import org.springframework.data.redis.core.RedisTemplate;
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
    private final RedisTemplate<String, Object> redisTemplate;

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

    public AuthController.TokenResponse login(String email, String password) {
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

            String accessToken = jwtProvider.createAccessToken(user.getEmail(), user.getRole());
            String refreshToken = jwtProvider.createRefreshToken(user.getEmail());
            saveRefreshToken(user.getEmail(), refreshToken);

            return new AuthController.TokenResponse(accessToken, refreshToken);
        } catch (IllegalArgumentException e) {
            loginAttemptService.loginFailed(email);
            throw e;
        }
    }

    private void saveRefreshToken(String email, String refreshToken) {
        long expirationMs = jwtProvider.getRemainingTimeMs(refreshToken);
        redisTemplate.opsForValue().set("RT:" + email, refreshToken, expirationMs,
                java.util.concurrent.TimeUnit.MILLISECONDS);
    }

    public AuthController.TokenResponse refresh(String refreshToken) {
        if (!jwtProvider.validateToken(refreshToken)) {
            throw new IllegalArgumentException("Invalid refresh token");
        }
        if (jwtProvider.isAccessToken(refreshToken)) {
            throw new IllegalArgumentException("Access token cannot be used to refresh");
        }

        String email = jwtProvider.getEmail(refreshToken);
        String redisToken = (String) redisTemplate.opsForValue().get("RT:" + email);

        if (redisToken == null || !redisToken.equals(refreshToken)) {
            // Compromised token detected
            redisTemplate.delete("RT:" + email);
            throw new IllegalArgumentException("Compromised or missing refresh token. Please login again.");
        }

        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        // Rotation
        String newAccessToken = jwtProvider.createAccessToken(email, user.getRole());
        String newRefreshToken = jwtProvider.createRefreshToken(email);

        saveRefreshToken(email, newRefreshToken);

        return new AuthController.TokenResponse(newAccessToken, newRefreshToken);
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
