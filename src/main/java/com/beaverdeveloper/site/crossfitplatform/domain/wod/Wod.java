package com.beaverdeveloper.site.crossfitplatform.domain.wod;

import com.beaverdeveloper.site.crossfitplatform.global.common.BaseEntity;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDate;

@Entity
@Table(name = "wods")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor
@Builder
public class Wod extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private WodType type;

    @Column(nullable = false)
    private String title;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(name = "time_cap")
    private Integer timeCap; // 단위: 초

    @Column(name = "box_id")
    private Long boxId; // Null이면 글로벌 공통 WOD

    @Column(nullable = false)
    private LocalDate date;
}
