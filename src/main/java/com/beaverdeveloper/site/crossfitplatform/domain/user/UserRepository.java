package com.beaverdeveloper.site.crossfitplatform.domain.user;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByEmail(String email);

    boolean existsByEmail(String email);

    Page<User> findByNicknameContaining(String nickname, Pageable pageable);

    Page<User> findByBoxIdAndNicknameContaining(Long boxId, String nickname, Pageable pageable);

    Long countByBoxId(Long boxId);
    
    java.util.List<User> findAllByBoxId(Long boxId);
}
