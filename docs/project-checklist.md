# Crossfit Competition Platform - Project Checklist

본 문서는 PRD 및 TRD 요구사항을 바탕으로 프론트엔드와 백엔드 개발 영역을 분리하여 태스크를 관리합니다. 또한 시스템의 안정성을 위한 보안 체크리스트를 포함합니다.

---

## � 1. Backend (Spring Boot) Checklist

백엔드의 핵심 비즈니스 로직과 데이터 파이프라인 진행률입니다.

### ✅ 구현 완료 (Implemented)
- [x] **도메인 및 엔티티 설계**: `User`, `Box`, `Wod`, `Record` 등 핵심 엔티티 구조 설계 및 복합 인덱싱(`idx_record_wod`) 최적화
- [x] **인증 및 인가**: JWT 기반 Stateless 인증 로직 및 OAuth2(Google, Kakao) 소셜 로그인 통합 연동
- [x] **다형성 랭킹 엔진**: AMRAP, For Time, Max Weight, EMOM 특성을 반영한 전략 패턴(Strategy Pattern) 및 Time Capped 가중치 로직 적용 
- [x] **실시간 랭킹 시스템**: Redis ZSet 자료구조를 활용한 N(1) 속도의 Global 및 Box 랭킹 산출
- [x] **AI 기능 연동**: Google Gemini API(`gemini-3-flash-preview`)를 활용한 WOD 자동 생성 로직 (`WodAiService`) 구현
- [x] **공통 규격 및 예외 처리**: `ApiResponse<T>` 래퍼 통합 및 `GlobalExceptionHandler` 에러 핸들링
- [x] **인프라 배포**: Docker-Compose 기반 서버, DB, Redis 및 Nginx 리버스 프록시 연동 세팅
- [x] **어드민(Admin) 대시보드 API**: 코치/관리자가 박스 내 회원 통계 및 랭킹 추이를 한눈에 볼 수 있는 통계 API 구축
- [x] **페이징 및 무한 스크롤 최적화**: 랭킹 조회 시 커서 기반 페이징(Cursor-based Pagination) 추가 고도화

### ⏳ 추가 구현 필요 (Pending)
- [ ] **푸시 알림 서버 로직**: 특정 WOD 등록 시 또는 가입 승인 시 클라이언트로 Firebase Cloud Messaging(FCM) 푸시 알림 발송 연동

---

## 📱 2. Frontend (Flutter) Checklist

클라이언트 단(크로스플랫폼 모바일 앱)의 UI/UX 화면 및 네트워킹 진행률입니다.

### ✅ 구현 완료 (Implemented)
- [x] **프로젝트 코어 세팅**: Provider(상태관리), Dio(네트워크 통신), Flutter Secure Storage(안전 저장소), 패키지 구성 및 `ApiClient` 연동
- [x] **UI 퍼블리싱 (기본)**: `main_screen`, `admin_main_screen`, 하위 탭(WOD, Ranking, Profile 등) 파일 구조화 완성
- [x] **인증 및 온보딩 화면**: 이메일 로그인, 소셜 로그인 Hash 라우팅 처리를 포함한 JWT 파싱 및 UI 구현 (`login_screen.dart` 등)
- [x] **무중단 토큰 리프레시**: Access Token 만료 시 /refresh 엔드포인트를 호출하여 토큰을 자동 갱신하는 Dio Interceptor 로직
- [x] **홈 화면 및 운동 측정 뷰**: 오늘의 WOD 카드뷰 노출, 타이머(Stopwatch) 구동 로직, 기록(Rx'd/Scaled, Capped 여부) 전송 기능 연동 완료
- [x] **실시간 랭킹 뷰 (페이징 연동)**: Cursor-based Pagination API를 바탕으로 한 무한 스크롤 탭뷰 랭킹 로드 완료
- [x] **박스(Box) 탐색 및 가입 연결**: 자신이 소속될 '크로스핏 박스' 검색 및 가입 신청 폼 이벤트 완성 (`my_box_tab`)
- [x] **마이페이지 및 프로필 연동**: 닉네임 변경 API 및 플차트(FlChart)를 활용한 이전 WOD 랭킹 히스토리 조회 완료 (`profile_tab`, `records_tab`)
- [x] **코치/어드민 기능 1부**: 코치 전용 화면에서 'AI WOD 자동 생성(Team Size, Format 옵션 포함)' 기능 연결 완료

### 🚀 추가 구현 필요 (Pending / In Progress)
- [ ] **어드민(Admin) 대시보드 뷰 연결**: 전체 회원, 박스 통계 수치를 차트로 보여주는 통계 대시보드 UI 및 API 렌더링 추가 구현

---

## 🛡️ 3. 보안 점검 (Security Checklist)

시스템의 안정성과 유저 데이터 보호를 위해 런칭 전 반드시 점검해야 할 항목들입니다.

- [x] **CORS 정책 검증**: 허용된 도메인(앱 및 프론트 웹)에서만 API 호출과 소셜 로그인 리다이렉트가 가능하도록 `SecurityConfig` 내 Origin 검증 강화
- [x] **Refresh Token 로테이션/탈취 방지**: JWT Access 토큰 외에 Refresh Token을 Redis에 화이트리스트/블랙리스트 방식으로 관리하여 탈취 시 즉각 폐기할 수 있는 체계 구성
- [ ] **데이터 수평적 권한 제어(IDOR 방어)**: '유저 A'가 악의적으로 '유저 B'의 프라이빗 기록이나 개인정보 API를 호출(`api/v1/users/B_ID`)하지 못하도록, `@AuthenticationPrincipal` 검증 철저
- [x] **입력값 검증 및 XSS 방어**: 모든 API Request DTO에 `@Valid` (Size, NotBlank 등) 제약을 활성화하여 비정상적인 스크립트 인젝션 차단
- [ ] **Rate Limiting (API 호출 제한)**: 로그인, OTP 발송, 기록 입력 등 중요 API에 대해 초당/분당 호출 횟수를 제한하여 무차별 대입(Brute-force) 공격 방어
- [ ] **Swagger/API Docs 환경 분리**: 프로덕션(운영) 환경에서는 개발용 Swagger-UI(`v3/api-docs`) 엔드포인트 접근 차단
- [ ] **민감 정보(Secrets) 깃허브 노출 방지**: `.env` 파일과 OAuth2 Client Secret, Gemini API Key, DB 패스워드 등이 절대 `.gitignore` 연동을 누락하여 깃에 올라가지 않았는지 재확인
