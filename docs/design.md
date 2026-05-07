# 🎨 Stitch Minimalist Design System

본 플랫폼(CrossFit Platform)은 Stitch 프로젝트의 UI 디자인 원칙을 계승한 **미니멀리스트 테마(Minimalist Theme)**를 글로벌 디자인 시스템으로 채택하여 적용 중입니다.

이 문서는 모든 Flutter 화면에 통일된 사용자 경험을 제공하기 위해 준수되어야 할 핵심 디자인 토큰(Design Tokens)과 컴포넌트 규격을 정의합니다.

---

## 1. 🎨 색상표 (Color Palette)

모든 위젯은 기존 `app_colors.dart`의 어둡고 무거운 색상을 폐기하고 아래의 직관적이고 밝은 하드코딩 토큰 규칙을 따릅니다.

| 용도 | 색상 코드 (Hex) | 설명 |
|---|---|---|
| **Background (배경)** | `Colors.white` (`#FFFFFF`) | 앱의 주 배경화면 및 카드 내부 배경 색상 |
| **Primary (브랜드 포인트)** | `Color(0xFF115D33)` | 다크 포레스트 그린. 주요 액션 버튼, 로고 텍스트 등에 사용 |
| **Primary Light (배경 포인트)**| `Color(0xFF115D33).withOpacity(0.1)`| Rx 뱃지 배경이나 선택된 항목 배경 등에 은은하게 들어가는 포인트 |
| **Text Primary (주요 텍스트)** | `Colors.black87` | 제목, 본문, 중요한 리스트 타이틀용 어두운 회색/블랙 |
| **Text Secondary (보조 텍스트)** | `Color(0xFF757575)` | 설명란, 힌트 텍스트(진한), 보조 문구 등에 사용 |
| **Borders (테두리/경계선)** | `Color(0xFFE0E0E0)` | 카드, 텍스트 입력창, 구분선 등의 깔끔한 아웃라인 |
| **Hint Text (비활성/힌트)** | `Color(0xFFBDBDBD)` | 완전히 옅은 힌트 텍스트나 비활성화 요소 |

---

## 2. 🟩 UI 핵심 컴포넌트(Components) 규칙

### 2.1 액션 버튼 (ElevatedButton)
버튼은 완전한 둥근 알약 형태(Stadium)를 취하며, 잡다한 그림자(Elevation)를 제거하여 플랫한 느낌을 줍니다.
- **Background Color**: `Color(0xFF115D33)`
- **Text Color**: `Colors.white`
- **Shape**: `StadiumBorder()`
- **Elevation**: `0`

### 2.2 공통 카드 (Card & Containers)
아이템 리스트나 정보를 보여주는 하얀 박스 형태는 그림자를 없애고 회색 테두리 라인으로 종이 같은 질감을 줍니다.
- **Background Color**: `Colors.white`
- **Shape Outline**: `RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Color(0xFFE0E0E0)))`
- **Elevation**: `0`

### 2.3 입력창 (TextField)
폼 필드는 투명한 배경에 둥근 선(OutlineInputBorder)을 사용하여 답답함을 줄입니다. 포커스 시 브랜드 색상으로 선이 강조됩니다.
- **Default Border**: `OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE0E0E0)))`
- **Focused Border**: `OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF115D33), width: 1.5))`
- **Filled**: `false` (투명하게)

---

## 3. 🎯 적용 요약 가이드 (개발자용)
* `Scaffold`의 backgroundColor는 무조건 `Colors.white`로 설정한다.
* `AppBar`의 title 글자는 `Color(0xFF115D33)`로 설정하고, 굵게(`FontWeight.bold`) 처리한다.
* 텍스트에 들어가는 기본 검정색상은 칠흑 같은 색(`Colors.black`)보다 약한 `Colors.black87`을 사용해 눈의 피로를 던다.
