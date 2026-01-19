# Technical Requirements Document (TRD) - Crossfit Competition Platform

## 1. 기술 스택 (Tech Stack)

### 1.1. Backend (Java)
- **Framework**: Spring Boot 3.x
- **Language**: Java 17+
- **Build Tool**: Gradle
- **Database**:
    - **Main DB**: MySQL 8.0 (Entities, Records, Rankings)
    - **Cache/Session**: Redis (OTP, Verification codes, Ranking snapshots)
- **Security**: Spring Security + JWT + OAuth2 (Google, Kakao)
- **Persistence**: Spring Data JPA (Hibernate)

### 1.2. Frontend (Flutter)
- **Language**: Dart
- **State Management**: Provider (or basic StatefulWidget for simple screens)
- **Network**: Dio (HTTP Client)
- **Storage**: Flutter Secure Storage (JWT management)

### 1.3. AI 서비스
- **Model**: Google Gemini API (`gemini-3-flash-preview`)
- **Library**: Spring RestTemplate

## 2. 시스템 아키텍처 (Architecture)

### 2.1. DDD 기반 패키지 구조
Domain-Driven Design(DDD) 원칙을 따라 도메인 피처별로 패키지를 구성합니다.
- `domain.user`: 회원가입, 로그인, 프로필 관리
- `domain.box`: 박스 등록, 멤버십, 승인 로직
- `domain.wod`: WOD 생성(수동/AI), 조회
- `domain.record`: 운동 기록 입력, 랭킹 산출 로직
- `global`: 공통 설정 (시큐리티, 에러 핸들링, API 응답 규격)

### 2.2. 데이터베이스 스키마 (Major Entities)
- **User**: id, email, password, nickname, role(USER, COACH, ADMIN), box_id
- **Box**: id, name, location, business_number, owner_id, is_auto_wod_enabled
- **BoxMember**: id, box_id, user_id, status(PENDING, APPROVED, REJECTED)
- **Wod**: id, title, description, type(AMRAP, FOR_TIME, etc.), box_id(nullable for global), date, time_cap
- **Record**: id, user_id, wod_id, score(reps, seconds, etc.), is_rxd, created_at

## 3. 핵심 기술 구현 전략

### 3.1. 랭킹 시스템 (Ranking Engine)
- **Strategy Pattern**: WOD 타입에 따라 랭킹 정렬 기준을 동적으로 변경합니다.
- **Rx'd 우선 순위**: 데이터베이스 쿼리 레벨에서 `is_rxd DESC`를 최우선 정렬 조건으로 부여합니다.
- **캐싱**: 실시간 랭킹 요청 부하를 줄이기 위해 Redis를 활용하여 랭킹 목록을 캐싱하거나 스냅샷을 생성합니다.

### 3.2. AI WOD 서비스
- **Prompt Engineering**: 박스 이름, 운동 타입, 사용자 요구사항을 조합하여 Gemini API에 전달합니다.
- **JSON Parsing**: AI 응답을 정형화된 JSON으로 유도하고 이를 Jackson Object Mapper를 통해 도메인 객체로 파싱합니다.

### 3.3. 보안 (Security)
- **JWT**: Stateless 인증 방식을 채택하며 Access Token 기반으로 API 접근 권한을 관리합니다.
- **BCrypt**: 사용자의 비밀번호는 `BCryptPasswordEncoder`를 통해 난독화하여 저장합니다.

## 4. 인프라 및 배포 (Deployment)
- **Containerization**: Docker & Docker Compose를 활용하여 서버(JAR), DB(MySQL), 캐시(Redis), 웹서버(Nginx)를 마이크로서비스 형태로 관리합니다.
- **Nginx**: 리버스 프록시 설정을 통해 API 요청을 백엔드 컨테이너로 전달하고 HTTPS 처리를 담당합니다.

## 5. API 명세 핵심 원칙
- 모든 응답은 `ApiResponse<T>` 규격으로 감싸서 전달합니다.
- HTTP 상태 코드를 준수하되, 비즈니스 로직 에러는 별도의 에러 코드를 포함합니다.
- Swagger(OpenAPI)를 통해 실시간 API 명세서를 제공합니다.
