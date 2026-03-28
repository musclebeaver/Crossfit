# 🚀 Crossfit Platform 운영 배포 가이드 (AWS & 환경 설정)

## 1. 🌐 환경별 설정 방식 비교
운영 환경에 따라 설정을 다르게 가져가기 위해 **Flavor**와 **Environment Variables (`--dart-define`)** 중 아래 방식을 선택하여 구현했습니다.

### 📊 비교 분석
| 구분 | **Flavor** | **Environment Variables (`--dart-define`) [선택된 방식]** |
| :--- | :--- | :--- |
| **용도** | 다른 앱 아이콘, 리소스 등 네이티브 수준의 분리 | API URL, 키 값 등 런타임 설정값 변경 |
| **복잡도** | **높음** (안드로이드/iOS 네이티브 파일 수정 필수) | **낮음** (Dart 코드로만 제어 가능) |
| **유지보수** | 프로젝트가 커질수록 네이티브 설정 동기화가 어려움 | CI/CD 파이프라인에서 값 주입이 매우 간편함 |

**결정**: 현재 프로젝트 규모에서는 네이티브 복잡도를 낮추고 유지보수 효율을 높이기 위해 **`--dart-define`** 방식을 사용하여 `AppConfig` 클래스로 관리하도록 구현했습니다.

---

## 2. 📱 프론트엔드 (Flutter) 운영 빌드

빌드 시 환경 변수를 주입하여 운영 서버 주소를 설정합니다.

### 운영 빌드 명령어
```bash
# Web 빌드 예시
flutter build web --dart-define=BASE_URL=https://api.crossfit.beaverdeveloper.site/api/v1 --dart-define=IS_PROD=true

# Android 빌드 예시
flutter build apk --dart-define=BASE_URL=https://api.crossfit.beaverdeveloper.site/api/v1 --dart-define=IS_PROD=true
```

---

## 3. ☁️ AWS 백엔드 배포 가이드

### 🏗️ 추천 아키텍처 (MVP)
- **Compute**: AWS EC2 (t3.medium 권장)
- **Database**: AWS RDS (MySQL 8.0) - *프리티어 활용 가능*
- **Storage**: AWS S3 (사용자 프로필 이미지 등 저장용 - *필요 시 추가*)
- **Domain/SSL**: AWS Route53 + ACM (Nginx를 통한 SSL 적용)

### 🚀 배포 절차 (EC2 + Docker Compose)

1.  **EC2 인스턴스 준비**: Ubuntu 22.04 LTS 설치 및 Docker, Docker Compose 설치.
2.  **보안 그룹 설정**: 80(HTTP), 443(HTTPS), 22(SSH) 포트 개방.
3.  **코드 배포**: Git Clone 또는 CI/CD(Github Actions) 연동.
4.  **운영용 `.env` 작성**:
    ```bash
    DB_PASSWORD=RDS_비밀번호
    NAVER_CLIENT_ID=...
    NAVER_CLIENT_SECRET=...
    # [중요] REDIRECT_URL은 프론트엔드 도메인으로 설정
    REDIRECT_URL=https://crossfit.beaverdeveloper.site/oauth2/redirect
    ```
5.  **실행**:
    ```bash
    docker-compose -f docker-compose.yml up -d --build
    ```

---

## 🛡️ 운영 전환 시 필수 체크리스트

- [ ] **DB**: `hibernate.ddl-auto`를 `validate` 또는 `none`으로 변경 (데이터 유실 방지).
- [ ] **Redirect URL**: 각 소셜 개발자 센터(구글, 네이버, 카카오)의 리다이렉트 URI를 `api.domain.com` 형식으로 모두 교체.
- [ ] **CORS**: `SecurityConfig.java`의 허용 도메인에 운영 도메인 추가.
- [ ] **JWT**: `JWT_SECRET`을 매우 복잡한 문자열로 변경.
