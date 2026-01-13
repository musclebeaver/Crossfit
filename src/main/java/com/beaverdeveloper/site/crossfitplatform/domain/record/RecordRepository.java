package com.beaverdeveloper.site.crossfitplatform.domain.record;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface RecordRepository extends JpaRepository<Record, Long> {
    List<Record> findAllByWodId(Long wodId);

    List<Record> findAllByUserId(Long userId);
}
