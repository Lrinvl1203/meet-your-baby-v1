// Meet Your Baby - Advanced Analytics System
// 방문자 추적 및 분석 시스템

class LandingAnalytics {
    constructor() {
        this.sessionId = this.generateSessionId();
        this.startTime = Date.now();
        this.events = [];
        this.init();
    }

    generateSessionId() {
        return Date.now().toString(36) + Math.random().toString(36).substr(2);
    }

    init() {
        this.trackPageView();
        this.setupEventListeners();
        this.setupBeforeUnload();
        this.trackScrollDepth();
    }

    // 페이지 방문 추적
    trackPageView() {
        const visitorData = {
            sessionId: this.sessionId,
            timestamp: new Date().toISOString(),
            url: window.location.href,
            referrer: document.referrer || 'direct',
            userAgent: navigator.userAgent,
            language: navigator.language,
            screen: `${screen.width}x${screen.height}`,
            viewport: `${window.innerWidth}x${window.innerHeight}`,
            timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
            device: this.getDeviceType(),
            browser: this.getBrowserInfo(),
            os: this.getOSInfo()
        };

        this.saveVisitor(visitorData);
        this.logEvent('page_view', visitorData);
        console.log('📊 새 방문자 추적:', visitorData);
    }

    // 디바이스 타입 감지
    getDeviceType() {
        const width = window.innerWidth;
        if (width <= 768) return 'mobile';
        if (width <= 1024) return 'tablet';
        return 'desktop';
    }

    // 브라우저 정보 감지
    getBrowserInfo() {
        const ua = navigator.userAgent;
        if (ua.includes('Chrome')) return 'Chrome';
        if (ua.includes('Firefox')) return 'Firefox';
        if (ua.includes('Safari')) return 'Safari';
        if (ua.includes('Edge')) return 'Edge';
        return 'Unknown';
    }

    // 운영체제 정보 감지
    getOSInfo() {
        const platform = navigator.platform;
        const ua = navigator.userAgent;

        if (platform.includes('Win')) return 'Windows';
        if (platform.includes('Mac')) return 'macOS';
        if (platform.includes('Linux')) return 'Linux';
        if (/Android/.test(ua)) return 'Android';
        if (/iPhone|iPad/.test(ua)) return 'iOS';
        return 'Unknown';
    }

    // 이벤트 리스너 설정
    setupEventListeners() {
        // 이메일 폼 클릭 추적
        const emailForm = document.getElementById('emailForm');
        if (emailForm) {
            emailForm.addEventListener('click', () => {
                this.logEvent('form_click', { element: 'email_form' });
            });

            const emailInput = document.getElementById('email');

            if (emailInput) {
                emailInput.addEventListener('focus', () => {
                    this.logEvent('input_focus', { field: 'email' });
                });
            }

            emailForm.addEventListener('submit', () => {
                this.logEvent('form_submit', {
                    form: 'email_signup',
                    timeOnPage: Date.now() - this.startTime
                });
            });
        }

        // 특징 카드 클릭 추적
        document.querySelectorAll('.feature-card').forEach((card, index) => {
            card.addEventListener('click', () => {
                this.logEvent('feature_card_click', {
                    cardIndex: index,
                    cardTitle: card.querySelector('h3').textContent
                });
            });
        });

        // 스크롤 이벤트
        let scrollTimer = null;
        window.addEventListener('scroll', () => {
            if (scrollTimer) clearTimeout(scrollTimer);
            scrollTimer = setTimeout(() => {
                this.trackScrollPosition();
            }, 150);
        });
    }

    // 스크롤 깊이 추적
    trackScrollDepth() {
        let maxScrollDepth = 0;
        let scrollDepthMarkers = [25, 50, 75, 90, 100];
        let trackedMarkers = [];

        const trackScroll = () => {
            const scrollTop = window.pageYOffset || document.documentElement.scrollTop;
            const docHeight = document.documentElement.scrollHeight - window.innerHeight;
            const scrollPercent = Math.round((scrollTop / docHeight) * 100);

            if (scrollPercent > maxScrollDepth) {
                maxScrollDepth = scrollPercent;
            }

            scrollDepthMarkers.forEach(marker => {
                if (scrollPercent >= marker && !trackedMarkers.includes(marker)) {
                    trackedMarkers.push(marker);
                    this.logEvent('scroll_depth', {
                        depth: marker,
                        timeToReach: Date.now() - this.startTime
                    });
                }
            });
        };

        window.addEventListener('scroll', trackScroll);
    }

    trackScrollPosition() {
        const scrollTop = window.pageYOffset || document.documentElement.scrollTop;
        const docHeight = document.documentElement.scrollHeight - window.innerHeight;
        const scrollPercent = Math.round((scrollTop / docHeight) * 100);

        if (scrollPercent >= 25) {
            this.logEvent('scroll_position', { position: scrollPercent });
        }
    }

    // 페이지 떠나기 전 추적
    setupBeforeUnload() {
        window.addEventListener('beforeunload', () => {
            const sessionData = {
                sessionId: this.sessionId,
                duration: Date.now() - this.startTime,
                events: this.events.length,
                timestamp: new Date().toISOString()
            };

            this.saveSession(sessionData);
            this.logEvent('page_exit', sessionData);
        });

        // 비활성화 추적
        document.addEventListener('visibilitychange', () => {
            if (document.hidden) {
                this.logEvent('page_hidden', {
                    timeOnPage: Date.now() - this.startTime
                });
            } else {
                this.logEvent('page_visible', {
                    timeOnPage: Date.now() - this.startTime
                });
            }
        });
    }

    // 이벤트 로깅
    logEvent(eventType, data = {}) {
        const event = {
            type: eventType,
            timestamp: new Date().toISOString(),
            sessionId: this.sessionId,
            data
        };

        this.events.push(event);
        this.saveEvent(event);
    }

    // 데이터 저장 (로컬 스토리지)
    saveVisitor(visitorData) {
        let visitors = JSON.parse(localStorage.getItem('meetyourbaby_visitors') || '[]');
        visitors.push(visitorData);
        localStorage.setItem('meetyourbaby_visitors', JSON.stringify(visitors));
    }

    saveEvent(event) {
        let events = JSON.parse(localStorage.getItem('meetyourbaby_events') || '[]');
        events.push(event);

        // 최대 1000개 이벤트만 저장 (성능 고려)
        if (events.length > 1000) {
            events = events.slice(-1000);
        }

        localStorage.setItem('meetyourbaby_events', JSON.stringify(events));
    }

    saveSession(sessionData) {
        let sessions = JSON.parse(localStorage.getItem('meetyourbaby_sessions') || '[]');
        sessions.push(sessionData);
        localStorage.setItem('meetyourbaby_sessions', JSON.stringify(sessions));
    }

    // 통계 조회 메서드
    getStats() {
        const visitors = JSON.parse(localStorage.getItem('meetyourbaby_visitors') || '[]');
        const subscribers = JSON.parse(localStorage.getItem('subscribers') || '[]');
        const events = JSON.parse(localStorage.getItem('meetyourbaby_events') || '[]');
        const sessions = JSON.parse(localStorage.getItem('meetyourbaby_sessions') || '[]');

        // 오늘 방문자 수
        const today = new Date().toDateString();
        const todayVisitors = visitors.filter(v =>
            new Date(v.timestamp).toDateString() === today
        );

        // 평균 세션 시간
        const avgSessionTime = sessions.length > 0
            ? sessions.reduce((sum, s) => sum + s.duration, 0) / sessions.length / 1000
            : 0;

        // 디바이스별 통계
        const deviceStats = visitors.reduce((acc, v) => {
            acc[v.device] = (acc[v.device] || 0) + 1;
            return acc;
        }, {});

        // 브라우저별 통계
        const browserStats = visitors.reduce((acc, v) => {
            acc[v.browser] = (acc[v.browser] || 0) + 1;
            return acc;
        }, {});

        return {
            totalVisitors: visitors.length,
            todayVisitors: todayVisitors.length,
            totalSubscribers: subscribers.length,
            conversionRate: visitors.length > 0 ?
                ((subscribers.length / visitors.length) * 100).toFixed(1) : '0',
            avgSessionTimeSeconds: Math.round(avgSessionTime),
            totalEvents: events.length,
            deviceBreakdown: deviceStats,
            browserBreakdown: browserStats,
            recentVisitors: visitors.slice(-5).map(v => ({
                time: new Date(v.timestamp).toLocaleString('ko-KR'),
                device: v.device,
                referrer: v.referrer
            }))
        };
    }
}

// 분석 시스템 초기화
const analytics = new LandingAnalytics();

// 전역 함수로 통계 조회 가능하게 만들기
window.detailedStats = () => analytics.getStats();
window.exportData = () => {
    const data = {
        visitors: JSON.parse(localStorage.getItem('meetyourbaby_visitors') || '[]'),
        subscribers: JSON.parse(localStorage.getItem('subscribers') || '[]'),
        events: JSON.parse(localStorage.getItem('meetyourbaby_events') || '[]'),
        sessions: JSON.parse(localStorage.getItem('meetyourbaby_sessions') || '[]')
    };

    const blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `meetyourbaby-analytics-${new Date().toISOString().split('T')[0]}.json`;
    a.click();
    URL.revokeObjectURL(url);

    console.log('📁 데이터 내보내기 완료');
    return data;
};

// 실시간 대시보드 (콘솔)
window.dashboard = () => {
    const stats = analytics.getStats();

    console.clear();
    console.log(`
🍼 Meet Your Baby - 실시간 대시보드
═══════════════════════════════════

📊 핵심 지표:
• 총 방문자: ${stats.totalVisitors}명
• 오늘 방문자: ${stats.todayVisitors}명
• 구독자: ${stats.totalSubscribers}명
• 전환율: ${stats.conversionRate}%
• 평균 세션 시간: ${stats.avgSessionTimeSeconds}초

📱 디바이스별 방문:
${Object.entries(stats.deviceBreakdown).map(([device, count]) =>
    `• ${device}: ${count}명`).join('\n')}

🌐 브라우저별 방문:
${Object.entries(stats.browserBreakdown).map(([browser, count]) =>
    `• ${browser}: ${count}명`).join('\n')}

📝 최근 방문자 5명:
${stats.recentVisitors.map(v =>
    `• ${v.time} - ${v.device} (${v.referrer || 'direct'})`).join('\n')}

💡 콘솔 명령어:
• stats() - 기본 통계
• detailedStats() - 상세 통계
• dashboard() - 실시간 대시보드
• exportData() - 데이터 내보내기
    `);

    return stats;
};

console.log('🚀 Meet Your Baby 분석 시스템이 시작되었습니다!');
console.log('💡 dashboard() 명령어로 실시간 대시보드를 확인하세요.');