package com.beaverdeveloper.site.crossfitplatform.domain.box;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface BoxMemberRepository extends JpaRepository<BoxMember, Long> {
    List<BoxMember> findAllByBoxIdAndStatus(Long boxId, BoxMemberStatus status);

    java.util.Optional<BoxMember> findFirstByUserIdOrderByCreatedAtDesc(Long userId);
}
