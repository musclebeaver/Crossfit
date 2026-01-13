# 이메일 발송 인프라 및 소셜 로그인 설정 가이드

본 가이드는 백엔드에서 이메일을 발송하고, 소셜 로그인을 연동하기 위해 필요한 인프라 설정을 안내합니다.

## 1. 이메일 발송 (Mail Server vs SMTP Service)

직접 메일 서버(MX 레코드 설정 등)를 구축하는 것은 스팸 차단 이슈 등으로 인해 매우 어렵고 복잡합니다. 따라서 전문 **SMTP 서비스**를 사용하는 것을 강력히 추천합니다.

### 추천 서비스
- **개발용**: Gmail SMTP (App Password 사용)
- **운영용 (무료 티어 존재)**: 
  - **AWS SES**: 도메인 인증 후 저렴하고 안정적으로 대량 발송 가능.
  - **SendGrid / Mailgun**: 개발자 친화적인 API와 대시보드 제공.

### 필요한 도메인 설정 (DNS)
이메일 도출 신뢰도를 높이기 위해 다음 레코드를 등록해야 합니다:
- **SPF (Sender Policy Framework)**: 내 도메인에서 메일을 보낼 수 있는 IP를 지정.
- **DKIM (DomainKeys Identified Mail)**: 메일에 디지털 서명을 하여 위조 방지.
- **DMARC**: SPF/DKIM 인증 실패 시 처리 규칙 정의.
- *참고: MX 레코드는 메일을 **받을 때**만 필요합니다.*

---

## 2. 소셜 로그인 연동 (클라이언트 설정)

로그인 버튼을 구현한 후, 각 플랫폼의 개발자 센터에서 앱을 등록하고 API 키를 발급받아야 합니다.

### 플랫폼별 개발자 도구
- **Google**: [Google Cloud Console](https://console.cloud.google.com/)
- **Kakao**: [Kakao Developers](https://developers.kakao.com/)
- **Naver**: [Naver Developers](https://developers.naver.com/)

### 발급 필수 정보
- **Client ID & Client Secret** (백엔드용)
- **Redirect URI**: 인증 후 토큰을 전달받을 콜백 주소.
- **SHA-1 지문**: 안드로이드 앱 등록 시 필수.

---

## 3. 백엔드 설정 (application.yml)

```yaml
spring:
  mail:
    host: smtp.gmail.com
    port: 587
    username: your-email@gmail.com
    password: your-app-password
    properties:
      mail:
        smtp:
          auth: true
          starttls:
            enable: true
```
