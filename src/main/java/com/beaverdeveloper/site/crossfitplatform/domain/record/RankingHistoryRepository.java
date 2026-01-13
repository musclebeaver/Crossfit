package com.beaverdeveloper.site.crossfitplatform.domain.record;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface RankingHistoryRepository extends JpaRepository<RankingHistory, Long> {
    List<RankingHistory> findAllByUserId(Long userId);
}
