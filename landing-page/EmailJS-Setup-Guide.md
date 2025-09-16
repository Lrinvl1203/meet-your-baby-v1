# EmailJS 설정 가이드 - Meet Your Baby 랜딩페이지

EmailJS를 사용하여 랜딩페이지에서 수집한 이메일을 `lrinvl1203@gmail.com`으로 자동 전송하는 설정 방법입니다.

## 1. EmailJS 계정 생성 및 설정

### 1.1 계정 생성
1. [EmailJS 웹사이트](https://www.emailjs.com/)에 접속
2. "Sign Up" 클릭하여 계정 생성
3. 이메일 인증 완료

### 1.2 Email Service 연결
1. Dashboard → "Email Services" → "Add New Service"
2. "Gmail" 선택
3. `lrinvl1203@gmail.com` 계정으로 연결
4. Service ID 확인 (예: `service_gmail123`)

### 1.3 Email Template 생성
1. Dashboard → "Email Templates" → "Create New Template"
2. 다음 템플릿 사용:

```
From: {{from_name}} ({{from_email}})
Subject: 🍼 Meet Your Baby - 새 베타 테스터 등록

{{message}}

---
Meet Your Baby Landing Page
자동 알림 시스템
```

3. Template ID 확인: `template_oux9mo6`

## 2. 코드 업데이트

`index.html` 파일에서 다음 부분을 수정:

```javascript
// EmailJS 초기화
(function(){
    emailjs.init("YOUR_PUBLIC_KEY"); // 여기에 Public Key 입력
})();

// 이메일 전송 부분
// await emailjs.send('YOUR_SERVICE_ID', 'template_oux9mo6', templateParams);
await emailjs.send('YOUR_SERVICE_ID', 'template_oux9mo6', templateParams);
```

### 실제 설정값:
- `YOUR_PUBLIC_KEY`: `LskYXC4NfFvgvIXJx` ✅ (설정 완료)
- `YOUR_SERVICE_ID`: `service_z0baz5r` ✅ (설정 완료)
- `YOUR_TEMPLATE_ID`: `template_oux9mo6` ✅ (설정 완료)

## 3. 테스트

1. 랜딩페이지에서 이메일 등록 테스트
2. `lrinvl1203@gmail.com`으로 알림 이메일 도착 확인
3. 브라우저 콘솔에서 오류 확인

## 4. 방문자 통계 확인 방법

### 실시간 확인:
1. 브라우저 개발자 도구 열기 (F12)
2. Console 탭에서 통계 자동 출력 확인

### 수동 확인:
콘솔에서 `stats()` 입력하면 상세 통계 표시:
- 총 방문자 수
- 구독자 수
- 전환율
- 구독자 목록 (이름, 이메일, 등록시간)

## 5. 대안 (EmailJS 없이)

EmailJS 설정이 어려운 경우, 현재는 로컬 스토리지에 데이터가 저장됩니다:
- 브라우저 콘솔에서 `stats()` 명령어로 모든 데이터 확인 가능
- 나중에 백엔드 구축 시 이 데이터를 활용할 수 있습니다

## 6. 향후 개선 사항

1. **백엔드 서버 구축**: Node.js/Express로 이메일 수집 API 구현
2. **데이터베이스 연동**: MongoDB/PostgreSQL로 구독자 정보 저장
3. **이메일 마케팅 도구 연동**: Mailchimp, ConvertKit 등과 연동
4. **분석 도구 추가**: Google Analytics, Hotjar 등 추가

## 문의
설정 관련 문의: lrinvl1203@gmail.com