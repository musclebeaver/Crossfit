package com.beaverdeveloper.site.crossfitplatform.domain.box;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class BoxService {

    private final BoxRepository boxRepository;
    private final BoxMemberRepository boxMemberRepository;

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

    public List<Box> searchBoxes(String name) {
        return boxRepository.findByNameContainingIgnoreCase(name);
    }
}
