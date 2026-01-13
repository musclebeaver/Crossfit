package com.beaverdeveloper.site.crossfitplatform.domain.record;

import com.beaverdeveloper.site.crossfitplatform.global.common.BaseEntity;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDate;

@Entity
@Table(name = "ranking_histories")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor
@Builder
public class RankingHistory extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "wod_id", nullable = false)
    private Long wodId;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "rank_value", nullable = false)
    private Integer rank;

    @Column(nullable = false)
    private Double score;

    @Column(name = "is_rx", nullable = false)
    private boolean isRx;

    @Column(nullable = false)
    private LocalDate date;
}
