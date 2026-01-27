package com.beaverdeveloper.site.crossfitplatform.domain.wod;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;

@Repository
public interface WodRepository extends JpaRepository<Wod, Long> {
    List<Wod> findAllByDate(LocalDate date);

    List<Wod> findAllByBoxIdAndDate(Long boxId, LocalDate date);

    List<Wod> findByBoxIdIsNull();
}
