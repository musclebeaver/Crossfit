package com.beaverdeveloper.site.crossfitplatform.domain.user;

import lombok.RequiredArgsConstructor;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Service;

import java.util.concurrent.TimeUnit;

@Service
@RequiredArgsConstructor
public class LoginAttemptService {

    private final RedisTemplate<String, Object> redisTemplate;
    private static final int MAX_ATTEMPT = 5;
    private static final long LOCK_TIME_DURATION = 15; // 15 minutes
    private static final String ATTEMPT_KEY_PREFIX = "login:attempt:";

    public void loginSucceeded(String email) {
        redisTemplate.delete(ATTEMPT_KEY_PREFIX + email);
    }

    public void loginFailed(String email) {
        String key = ATTEMPT_KEY_PREFIX + email;
        Integer attempts = (Integer) redisTemplate.opsForValue().get(key);

        if (attempts == null) {
            attempts = 0;
        }
        attempts++;

        redisTemplate.opsForValue().set(key, attempts, LOCK_TIME_DURATION, TimeUnit.MINUTES);
    }

    public boolean isBlocked(String email) {
        String key = ATTEMPT_KEY_PREFIX + email;
        Integer attempts = (Integer) redisTemplate.opsForValue().get(key);
        return attempts != null && attempts >= MAX_ATTEMPT;
    }
}
