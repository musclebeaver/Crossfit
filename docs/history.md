# History Log (구현 이력)

현재까지 해당 "Crossfit Competition Platform" 프로젝트 내에서 달성 및 구현이 완료된 핵심 개발 이력들입니다.

## 1. 프로젝트 및 기초 데이터베이스 세팅
- **Spring Boot 서버 구축**: 백엔드 RESTful API 설계를 위한 기본 스캐폴딩.
- **도메인 엔티티 확립**: 크로스핏 도메인에 걸맞는 `User`, `Box`, `Wod`, `Record` 엔티티 생성, JPA Entity 설계 적용 (Auditing 통한 BaseEntity 통합).

## 2. 보안 환경 및 인증(Auth) 시스템 연동
- **JWT & Spring Security 통합**: Stateless 토큰 인증 체제로 전환, `JwtAuthenticationFilter` 등 구현 적용 완료.
- **다중 소셜 인증**: OAuth2(Google, Kakao) 연동, 로그인 성공 시 동작하는 커스텀 핸들러(`OAuth2SuccessHandler`) 구성 완료.
- **이메일 인증**: SMTP 또는 외부 연동 구성을 통해 회원의 유효성 증명을 위한 OTP 시스템 도입(Redis 캐시 접목).

## 3. 핵심 비즈니스 로직 - WOD 및 랭킹 엔진
- **전략 패턴(Strategy Pattern) 적용**: WOD 종류(AMRAP, For Time, EMOM, Max Weight)별로 정수/타이머/라운드 등 기록 수집과 처리가 상이한 특수성을 해결하기 위해 유연한 `RankingStrategy` 아키텍처 도입.
- **Redis 기반 실시간 랭킹**: 기록 삽입과 동시에 Redis ZSet 스코어 가중치 연산(Rx'd 여부 우선순위 타켓팅 등)을 통해 N(1) 로직의 실시간 실력 랭킹 반영.
- **제한 시간(Time Capped) 처리 확장**: 완주자와 타임캡 차등 방식을 위해 Redis Score 연산 내 `finishedWeight` 로직 강화 및 DB `isCapped` 필드 반영 작업 적용.

## 4. AI(Gemini) 모델 연동 기능
- **WOD 자동 생성**: 단순히 타이핑하는 것을 넘어, 코치나 유저가 환경을 입력하면 AI가 크로스핏 WOD 루틴을 추천하고 생성해 주는 `WodAiService` 구축(Gemini API 연동).

## 5. 성능 고도화 및 인프라 표준화 작업
- **API 공통 규격 및 에러 핸들링**: 프론트엔드 연동 시 일관적 데이터 통신을 위한 `ApiResponse` 공통 래핑, `GlobalExceptionHandler`(글로벌 예외 처리기) 체계 마련 및 패키지 구조 DDD 기반 정렬.
- **데이터베이스 인덱스 매핑**: 조회(랭킹 검색) 시 테이블 풀 스캔 방지를 위해 Record Entity 내 `idx_record_wod` (종목, RxF/S 팩터, 완료여부 순) 복합 인덱싱 세팅.
- **Docker/Nginx 인프라 파이프라인**: (Deployment) 백엔드와 캐시, RDBMS를 개별 컨테이너 레벨로 오케스트레이션하고 리버스 프록시 연동을 수행할 수 있도록 Docker-Compose 배포 환경 마무리.

## 6. 어드민 통계, 페이징 및 보안 아키텍처 (최근 업데이트)
- **랭킹 시스템 커서 기반 페이징(Cursor-based Pagination)**: Redis `reverseRangeWithScores`와 `cursorRank`를 이용해 기존 Offset 기반 페이징의 O(N) 성능 저하 및 무한 스크롤 데이터 누락 문제를 완벽히 해결(`CursorResponse<T>` 래퍼 도입).
- **박스(Box) 통계 대시보드 API**: 코치 권한 사용자를 위해 박스 내 전체 가입자, 7일 내 활성 멤버(`countActiveMembersInBox` 서브쿼리), 누적 WOD 개수를 실시간 서빙.
- **Refresh Token 로테이션**: 단일 Access Token의 한계를 극복하고 수명이 긴 Refresh Token 발급 로직 신설. 사용 시마다 새 토큰 쌍으로 교체(Rotation)하며 Redis 대조를 통해 1회용 토큰 탈취 및 재사용 시 즉각적인 계정 차단 방어선 구축.
- **입력값 검증(`@Valid`) 및 예외 처리**: 클라이언트 단의 무분별한 형식을 막으려고 DTO에 제약조건(`@Email`, `@Size`, `@NotBlank`)을 걸고 `GlobalExceptionHandler`에서 400 에러를 정규화함.
- **WOD 엣지 케이스 처리**: `EmomRankingStrategy` 추가 및 `isCapped` 속성을 통해 'Time Capped(타임캡)' 기록이 완주자보다 하위에 랭크되도록 전략 패턴 고도화.

## 7. 트러블슈팅 및 환경 설정
- **Docker Build 504 Gateway Time-out**: Docker Hub 서버 혹은 네트워크 문제로 gradle 베이스 이미지 레이어를 다운로드하지 못해 발생하는 오류. (일시적인 현상으로 빌드 재시도 또는 Docker 재기동으로 해결 안내)
- **더미 데이터 및 엔티티 컴파일 오류 수정**: `User`, `Box`, `Wod`, `Record` 도메인 엔티티 내 누락된 필드(`description`, `isAiGenerated` 등) 및 메서드(`updateBox`)를 보강하고, `DailyRankingScheduler`의 커서 페이징 API 호출부 파라미터 타입 불일치를 해결하여 서버 빌드 정상화 완료.
- **AI WOD 생성 옵션 고도화**: 플러터 앱(`box_management_screen.dart`) 메뉴에 '참여 인원(Team Size)' 및 '팀 방식(Team Format)' 드롭다운 메뉴를 추가해, 사용자가 선택한 옵션이 자동으로 요구사항(`requirements`)에 포함되도록 UX/UI 개선.
- **버전 체크 API 파싱 에러 및 보안 예외 처리**: `/api/v1/app/version` 엔드포인트가 Spring Security에 의해 차단되어 로그인(HTML) 페이지를 반환하던 문제를 해결하기 위해 `SecurityConfig.java`의 `permitAll()` 지정 경로에 버전 검사 API를 추가함. 또한 핫 리스타트 시 HTML 문자열 응답으로 인해 발생하던 파싱 오류(TypeError)를 방지하기 위해 플러터의 `login_screen.dart` 측에 안전한 Map 타입 검사 로직을 추가하여 앱 진입 안정성을 확보.
- **더미 데이터(Dummy Data) 스케일업**: `DummyDataInit` 생성 로직을 개선하여 기존 1개이던 초기 박스 데이터를 3개(CrossFit Beaver, Tiger, Eagle)로 늘리고, 30명의 생성된 유저들을 각 박스에 고르게 분산 배치하도록 코드 업데이트.
- **My Box 탭 무한 스크롤 연동**: 클라이언트 최적화를 위해 My Box 화면 초기 로딩 성능 개선 및 `Pageable`(Backend) + `ScrollController`(Flutter) 연동을 통한 무한 스크롤 아키텍처 구현.
- **OAuth2 로그인 과정 무한 루프 대응 보완**: Spring Security `SecurityConfig.java` 옵션에서 백엔드 `OAuth2RedirectController`가 토큰을 들고 프론트단으로 라우팅할 때 루트(`/`)와 에러(`/error`) 페이지가 막혀있던 현상을 해결(`permitAll()`).
- **Minimalist Login Screen 디자인 마이그레이션**: "Stitch" 화면 설계 프로젝트로부터 발췌된 'Minimalist Login Screen' 스크린샷 렌더링에 영감을 받아, 플러터 앱(`login_screen.dart`)의 로그인 화면 전체를 `StadiumBorder`(알약 폼), `OutlineInputBorder`(여백 및 가는 선 폼), 순백색 배경 및 브랜드 포인트 컬러(Dark Forest Green)로 전면 개조하여 사용자 경험(UX) 개선.

## 8. 전면 UI 리디자인 및 디자인 시스템 통일
- **Stitch 미니멀리스트 테마 마이그레이션 (6종 스크린 통합 편)**: 로그인 화면에 이어 추가적으로 6개의 핵심 탭/스크린(`signup_screen.dart`, `wod_tab.dart`, `ranking_tab.dart`, `my_box_tab.dart`, `records_tab.dart`, `profile_tab.dart`)에 대하여 대대적인 UI 리팩토링 실시. 기존의 칙칙하고 일관되지 않았던 다크톤을 폐기하고, 순백색(`Colors.white`) 테마 베이스에 다크 그린(`Color(0xFF115D33)`) 메인 로고/버튼 색상을 채택. `app_colors.dart`에 종속되지 않는 깔끔한 `StadiumBorder` 버튼과 `OutlineInputBorder` (곡률 10) 레이아웃을 통해 전문적이고 세련된 앱 환경으로 업그레이드 완료.
- **최종 화면 디자인 일관성 확보 (Admin/Box 확장 편)**: 누락되었던 관리자 콘솔(`admin_main_screen.dart`), 박스 관리 화면(`box_management_screen.dart`), 박스 등록 화면(`box_registration_screen.dart`), 이메일 인증(`email_verification_screen.dart`), 일일 와드 화면(`wod_list_screen.dart`) 등 모든 내부 위젯에 대해 `docs/design.md`에 명시된 하드코딩 토큰 룰(배경 화이트, 투명 테두리, 그림자 없는 버튼 등)을 적용하여 전체 앱 생태계의 디자인 시스템을 완전히 통일함.

## 9. 프론트엔드 네이티브 SDK 기반 소셜 로그인(구조 2) 도입
- **네이티브 소셜 로그인 지원 개편**: 모바일 앱 확장에 대비하기 위해 기존 Web 쪽에 치우쳐저있던 `dart:html` 의 리다이렉트 체제를 완전히 버리고, `kakao_flutter_sdk_user`, `google_sign_in`, `flutter_naver_login` 플러그인을 도입하여 토큰만 직접 교환하는 방식으로 아키텍처를 변경함.
- **백엔드 `SocialAuthService` 릴레이 통신 구축**: 플러터가 보내준 네이티브 액세스 토큰을 기반으로 구글, 카카오, 네이버의 원격 리소스 서버에 검증 후 회원 정보를 획득하고 자체 JWT 인증서를 발급해주는 `POST /api/v1/auth/social-login` 엔드포인트를 수립 및 테스트함.
 
 ## 10. 박스 가입 승인 로직 권한 분리 및 FCM 푸시 알림 통합
 - **박스 멤버십 관리 및 권한 강화**: 코치가 유저의 가입 신청을 승인(`APPROVED`)해야만 해당 박스의 WOD와 랭킹을 열람할 수 있도록 보안 로직을 강화함. `BoxService` 승인 시 유저의 `boxId`를 즉시 업데이트하고, `WodController`, `RecordController`에서 접근 제어(Forbidden)를 수행함.
 - **FCM(Firebase Cloud Messaging) 푸시 인프라 구축**: `firebase-admin`을 서버에 통합하고, 비동기(`@Async`) 알림 발송 서비스(`NotificationService`)를 구축함.
 - **리텐션 향상 알림 트리거 연동**: 새로운 WOD 등록 시 박스 전체 멤버 알림, 본인의 순위가 밀렸을 때 개인 랭킹 하락 알림 등 핵심 리텐션 알림 기능을 백엔드 서비스 계층에 삽입함.
 - **플러터 푸시 알림 통합**: `PushNotificationService`를 구현하여 앱 초기화 시 권한 요청 및 FCM 토큰 획득 로직을 추가하고, 로그인 시 서버로 토큰을 전송하여 기기별 알림 발송이 가능하도록 프론트-백엔드 연동을 완료함.
 - **박스 관리 UI 최적화**: `box_management_screen.dart`에서 승인 대기자(Pending)를 섹션 상단에 별도로 그룹화하여 코치의 관리 가독성을 향상시킴.
 
 ## 11. 구글 애드몹(AdMob) 수익화 인프라 도입
 - **Google Mobile Ads SDK 통합**: `google_mobile_ads` 패키지를 도입하고 Android(`AndroidManifest.xml`) 및 iOS(`Info.plist`)에 테스트용 앱 식별자 설정을 완료함.
 - **광고 관리 아키텍처 수립**: 광고 단위 ID 관리 및 SDK 초기화를 전담하는 `AdService`를 구축하여 유지보수성을 확보함.
 - **공통 배너 위젯 및 UI 적용**: 모든 화면에서 재사용 가능한 `AdBannerWidget`을 구현하고, 유저 활동량이 가장 높은 **랭킹(Ranking) 화면 하단**에 배너를 우선적으로 배치하여 수익화 기반을 마련함.

## 12. 보상형 광고 및 프리미엄 광고 제거 기능 (Advanced Monetization)
 - **보상형 광고(Rewarded Ad) 연동**: AI WOD 생성 기능을 `RewardedAd`와 연동하여, 일반 유저가 광고 시청 완료 시에만 생성 보상을 획득하도록 구현함.
 - **프리미엄 무광고(Ad-Free) 환경**: 사용자의 Role(`PREMIUM_USER`, `PREMIUM_COACH`, `ADMIN`)을 전역으로 관리하는 `UserRoleService`를 도입하고, 프리미엄 유저에게는 배너 및 보상형 광고가 노출되지 않도록 최적화함.
 - **UX 개선**: 광고 시청 전 안내 팝업을 제공하여 사용자 경험을 배려함.

## 13. 애플 소셜 로그인 연동 및 오프라인 기록 동기화
- **애플 소셜 로그인(Sign in with Apple) 구현**: iOS 앱 출시의 필수 요건인 애플 로그인을 백엔드(`SocialAuthService`)의 JWT ID Token 검증 로직과 함께 통합 완료함.
- **오프라인-퍼스트 기록 저장 체계**: 체육관 지하 등 네트워크가 불량한 환경에 대비하여 `sqflite` 기반의 로컬 큐(`LocalRecordService`)를 구축함. 전송 실패 시 로컬에 기록을 캐싱하고 연결 회복 시 자동 동기화함.
- **동기화 매니저(SyncManager)**: 앱 진입 또는 메인 화면 복귀 시 미전송 데이터를 백그라운드에서 백엔드로 전송하는 자동 동기화 로직 구현 완료.

## 14. 앱 스토어 심사 대응 (Compliance) 및 UGC 보호
- **회원 탈퇴(Account Deletion) 기능**: 개인정보 보호 정책에 의거하여 유저의 계정 정보와 연관된 기록, 랭킹 데이터를 영구 삭제(Hard Delete)하는 탈퇴 API 및 UI를 구현함.
- **콘텐츠 모더레이션(UGC Protection)**: 부적절한 유저나 콘텐츠를 차단하고 관리자에게 신고할 수 있는 **신고(Report) 및 차단(Block)** 시스템을 도입함. 랭킹 리스트 아이템 롱탭을 통해 동작함.
- **iOS 앱 추적 투명성(ATT)**: AdMob 광고 사용을 승인받기 위한 iOS 전용 권한 요청 팝업을 앱 초기화 단계에 통합함.
- **이용약관(TOS) 및 문의하기(Support)**: 개인정보 처리방침과 별도로 서비스 이용 약관 웹페이지를 구성하고, 개발자에게 직접 문의할 수 있는 메일 연동(Contact) 기능을 추가함.