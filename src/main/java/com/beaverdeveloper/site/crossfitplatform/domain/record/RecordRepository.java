package com.beaverdeveloper.site.crossfitplatform.domain.record;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface RecordRepository extends JpaRepository<Record, Long> {
        List<Record> findAllByWodId(Long wodId);

        List<Record> findAllByUserId(Long userId);

        @Query("SELECT COUNT(DISTINCT r.userId) FROM Record r WHERE r.userId IN (SELECT u.id FROM User u WHERE u.boxId = :boxId) AND r.createdAt >= :startDate")
        Long countActiveMembersInBox(@Param("boxId") Long boxId, @Param("startDate") java.time.LocalDateTime startDate);
}
