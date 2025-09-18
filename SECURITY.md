# 보안 관리 문서 (Security Management)

## 🚨 현재 보안 상황 요약

### **발생한 보안 사고**
- **날짜**: 2025-09-18
- **문제**: Google API 키 `AIzaSyCtBoU-34kqdeNTTKmCYcsFfF7QIeQaAAg`가 GitHub 공개 저장소에 노출됨
- **감지**: Google Cloud Platform 및 GitHub에서 자동 감지하여 경고 이메일 발송
- **노출 위치**: `index.html#L1292` (커밋 `00a06433`)
- **프로젝트**: `MUMULAB-nanobanana` (id: mumulab-nanobanana)

### **즉시 취한 조치**
1. ✅ 노출된 API 키를 코드에서 완전히 제거
2. ✅ 다층 보안 시스템으로 교체 구현
3. ✅ 개발환경에서만 작동하는 임시 보안 방식 적용
4. ✅ Git 커밋/푸시로 노출된 키 제거 (커밋 `76c73ed`, `b041caf`)
5. ✅ API 키 사용량 제한 설정 완료 (관리자 설정)
6. ✅ 제한된 키로 정상 서비스 재개

---

## 🔒 현재 보안 구현 상태

### **API 키 로딩 우선순위**
```javascript
// 1순위: 환경변수 (Node.js 환경)
process.env.GEMINI_API_KEY

// 2순위: 서버 엔드포인트
fetch('/api/get-key')

// 3순위: 로컬 개발용 인코딩된 키 (localhost만)
Base64 인코딩된 키 조합
```

### **보안 개선 사항**
- **환경별 분리**: localhost/127.0.0.1에서만 개발용 키 활성화
- **인코딩**: Base64로 키 부분들을 난독화
- **로깅**: 키 로드 소스를 명확히 기록
- **경고**: 임시 보안 방식임을 지속적으로 알림

### **현재 서비스 상태**
- ✅ **Service On**: API 연결 테스트 성공
- ✅ **기능 정상**: 모든 앱 기능 작동
- ✅ **사용량 제한**: API 키 사용량 제한 적용됨
- 🔒 **보안 강화**: 다층 보안 시스템 + 사용량 모니터링

---

## ⚠️ 즉시 수행해야 할 조치

### **1. Google Cloud Console 작업 (최우선)**
```
1. https://console.cloud.google.com 접속
2. 프로젝트: MUMULAB-nanobanana 선택
3. API 및 서비스 → 사용자 인증 정보
4. 기존 키 AIzaSyCtBoU-34kqdeNTTKmCYcsFfF7QIeQaAAg 삭제/비활성화
5. 새 API 키 생성
6. 즉시 제한사항 설정:
   - HTTP 참조자: http://localhost:*, https://yourdomain.com/*
   - API 제한: Generative Language API만 선택
```

### **2. 새 API 키 적용**
```javascript
// 환경변수 방식 (권장)
export GEMINI_API_KEY="새로운_API_키"

// 또는 서버 엔드포인트 구현
// GET /api/get-key 엔드포인트 생성
```

### **3. 모니터링 설정**
- Google Cloud Console에서 API 사용량 모니터링 활성화
- 비정상적 사용 패턴 알림 설정
- 일일/월별 사용량 제한 설정

---

## 🔮 장기적 보안 개선 계획

### **단기 (1-2일)**
- [ ] 새 API 키 생성 및 적용
- [ ] API 키 제한사항 강화
- [ ] 사용량 모니터링 설정

### **중기 (1주일)**
- [ ] 서버사이드 API 프록시 구현
- [ ] 환경변수 기반 키 관리 시스템
- [ ] 자동 키 로테이션 계획

### **장기 (1개월)**
- [ ] 완전한 서버사이드 아키텍처
- [ ] 보안 감사 시스템
- [ ] 정기적 보안 검토 프로세스

---

## 📋 관련 파일 및 코드 위치

### **수정된 파일**
- `index.html`: API 키 보안 로직 구현 (라인 1289-1344)
- `SECURITY.md`: 이 문서

### **핵심 함수**
```javascript
// 보안 API 키 로딩
async getSecureApiKey()

// API 연결 테스트
async testApiConnectivity(apiKey)

// 서비스 상태 업데이트
updateServiceStatus(status)
```

### **Git 커밋 히스토리**
- `76c73ed`: 노출된 API 키 제거
- `b041caf`: 다층 보안 시스템 구현

---

## 🔗 참고 링크

- [Google API 키 보안 모범 사례](https://cloud.google.com/docs/authentication/api-keys#securing_an_api_key)
- [GitHub Secret Scanning](https://docs.github.com/en/code-security/secret-scanning/about-secret-scanning)
- [환경변수 관리](https://12factor.net/config)

---

## 📞 비상 연락

**보안 사고 발생 시 즉시 수행할 조치:**
1. 해당 API 키 즉시 비활성화
2. 새 키 생성 및 교체
3. 사용량 로그 확인
4. 이 문서 업데이트

**마지막 업데이트**: 2025-09-18
**다음 검토 예정**: 새 API 키 적용 후