package com.beaverdeveloper.site.crossfitplatform.domain.box;

import com.beaverdeveloper.site.crossfitplatform.domain.record.RecordRepository;
import com.beaverdeveloper.site.crossfitplatform.domain.user.UserRepository;
import com.beaverdeveloper.site.crossfitplatform.domain.wod.WodRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class BoxService {

    private final BoxRepository boxRepository;
    private final BoxMemberRepository boxMemberRepository;
    private final RecordRepository recordRepository;
    private final UserRepository userRepository;
    private final WodRepository wodRepository;

    @Transactional
    public void approveMember(Long boxMemberId) {
        BoxMember member = boxMemberRepository.findById(boxMemberId)
                .orElseThrow(() -> new IllegalArgumentException("Member request not found"));

        // TODO: Access Control (Check if requester is the box owner)

        member = BoxMember.builder()
                .id(member.getId())
                .box(member.getBox())
                .user(member.getUser())
                .status(BoxMemberStatus.APPROVED)
                .build();

        boxMemberRepository.save(member);
    }

    @Transactional
    public void rejectMember(Long boxMemberId) {
        BoxMember member = boxMemberRepository.findById(boxMemberId)
                .orElseThrow(() -> new IllegalArgumentException("Member request not found"));

        member = BoxMember.builder()
                .id(member.getId())
                .box(member.getBox())
                .user(member.getUser())
                .status(BoxMemberStatus.REJECTED)
                .build();

        boxMemberRepository.save(member);
    }

    public List<BoxMember> getAllMembers(Long boxId, String nickname) {
        if (nickname != null && !nickname.isEmpty()) {
            return boxMemberRepository.findByBoxIdAndUserNicknameContainingIgnoreCase(boxId, nickname);
        }
        return boxMemberRepository.findAllByBoxId(boxId);
    }

    public List<BoxMember> getPendingMembers(Long boxId) {
        return boxMemberRepository.findAllByBoxIdAndStatus(boxId, BoxMemberStatus.PENDING);
    }

    public BoxController.MemberStatusResponse getMembershipStatus(Long userId) {
        return boxMemberRepository.findFirstByUserIdOrderByCreatedAtDesc(userId)
                .map(m -> BoxController.MemberStatusResponse.builder()
                        .boxId(m.getBox().getId())
                        .boxName(m.getBox().getName())
                        .status(m.getStatus())
                        .build())
                .orElse(null);
    }

    @Transactional(readOnly = true)
    public BoxController.BoxStatisticsResponse getBoxStatistics(Long boxId, Long userId) {
        Box box = boxRepository.findById(boxId)
                .orElseThrow(() -> new IllegalArgumentException("Box not found"));

        if (!box.getOwner().getId().equals(userId)) {
            throw new org.springframework.security.access.AccessDeniedException("Only box owner can access statistics");
        }

        Long totalMembers = userRepository.countByBoxId(boxId);
        Long activeMembers = recordRepository.countActiveMembersInBox(boxId,
                java.time.LocalDateTime.now().minusDays(7));
        Long totalWods = wodRepository.countByBoxId(boxId);

        return new BoxController.BoxStatisticsResponse(boxId, totalMembers, activeMembers, totalWods);
    }

    public Page<Box> searchBoxes(String name, Pageable pageable) {
        return boxRepository.findByNameContainingIgnoreCase(name, pageable);
    }
}
