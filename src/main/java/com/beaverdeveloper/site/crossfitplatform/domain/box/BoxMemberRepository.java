package com.beaverdeveloper.site.crossfitplatform.domain.box;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface BoxMemberRepository extends JpaRepository<BoxMember, Long> {
    List<BoxMember> findAllByBoxId(Long boxId);

    List<BoxMember> findAllByBoxIdAndStatus(Long boxId, BoxMemberStatus status);

    List<BoxMember> findByBoxIdAndUserNicknameContainingIgnoreCase(Long boxId, String nickname);

    java.util.Optional<BoxMember> findFirstByUserIdOrderByCreatedAtDesc(Long userId);
}
