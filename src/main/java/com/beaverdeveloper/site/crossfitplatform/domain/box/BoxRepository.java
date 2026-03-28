package com.beaverdeveloper.site.crossfitplatform.domain.box;

import com.beaverdeveloper.site.crossfitplatform.domain.user.User;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface BoxRepository extends JpaRepository<Box, Long> {
    Page<Box> findByNameContainingIgnoreCase(String name, Pageable pageable);

    List<Box> findByOwner(User owner);
}
