package com.beaverdeveloper.site.crossfitplatform.domain.record;

import com.beaverdeveloper.site.crossfitplatform.domain.wod.Wod;
import com.beaverdeveloper.site.crossfitplatform.global.common.BaseEntity;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "records", indexes = {
        @Index(name = "idx_record_wod", columnList = "wod_id, is_rx DESC, is_capped ASC, result_value DESC"),
        @Index(name = "idx_record_user", columnList = "user_id")
})
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor
@Builder
public class Record extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "wod_id", nullable = false)
    private Wod wod;

    @Column(name = "result_value", nullable = false)
    private Double resultValue;

    @Column(name = "is_rx", nullable = false)
    private boolean isRx;

    @Column(name = "is_capped", nullable = false)
    private boolean isCapped;

    @Column(name = "media_url")
    private String mediaUrl;
}
