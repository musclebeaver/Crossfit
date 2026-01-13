package com.beaverdeveloper.site.crossfitplatform.domain.box;

import com.beaverdeveloper.site.crossfitplatform.domain.user.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface BoxRepository extends JpaRepository<Box, Long> {
    List<Box> findByNameContainingIgnoreCase(String name);

    List<Box> findByOwner(User owner);
}
