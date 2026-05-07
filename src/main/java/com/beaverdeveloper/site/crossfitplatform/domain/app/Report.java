package com.beaverdeveloper.site.crossfitplatform.domain.app;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;

@Entity
@Table(name = "reports")
@Getter
@Builder
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor
@EntityListeners(AuditingEntityListener.class)
public class Report {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private Long reporterId;

    @Column(nullable = false)
    private Long reportedUserId;

    @Column(nullable = false)
    private String reason; // SPAM, OFFENSIVE_LANGUAGE, INAPPROPRIATE_CONTENT, etc.

    private String details;

    @CreatedDate
    @Column(updatable = false)
    private LocalDateTime createdAt;
}
