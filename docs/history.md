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

