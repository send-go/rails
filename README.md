# sendgo-rails

> **Rails에서 카카오 알림톡, 친구톡, SMS를 가장 쉽게 발송하는 공식 Rails 확장 젬**

[![Gem Version](https://img.shields.io/gem/v/sendgo-rails)](https://rubygems.org/gems/sendgo-rails)
[![Rails](https://img.shields.io/badge/Rails-6.1%2B-CC0000?logo=rubyonrails)](https://rubyonrails.org)
[![Ruby](https://img.shields.io/badge/Ruby-3.0%2B-CC342D?logo=ruby)](https://ruby-lang.org)
[![License](https://img.shields.io/badge/license-MIT-blue)](LICENSE)

`sendgo-rails`는 [`sendgo`](https://github.com/send-go/ruby) 코어 젬을 확장한 **Rails 전용 확장 젬**입니다.
Railtie 자동 등록, `config.sendgo` 설정 바인딩, 초기화 파일 제너레이터, 메모이즈된 클라이언트를 제공합니다.

---

## 목차

- [설치](#설치)
- [빠른 시작](#빠른-시작)
- [상세 사용법](#상세-사용법)
  - [알림톡](#알림톡)
  - [친구톡](#친구톡)
  - [SMS / LMS / MMS](#sms--lms--mms)
- [Active Job 비동기 발송](#active-job-비동기-발송)
- [예외 처리](#예외-처리)
- [설정 옵션](#설정-옵션)
- [자주 묻는 질문 (FAQ)](#자주-묻는-질문-faq)
- [관련 패키지](#관련-패키지)
- [라이선스](#라이선스)

---

## 설치

Gemfile에 추가합니다.

```ruby
gem "sendgo-rails", "~> 1.0"
```

그리고 설치합니다.

```bash
bundle install
```

---

## 빠른 시작

### 1단계 — 초기화 파일 생성

```bash
bin/rails g sendgo:install
```

`config/initializers/sendgo.rb` 파일이 생성됩니다.

### 2단계 — 환경변수 설정 (`.env` 또는 배포 환경)

```env
SENDGO_ACCESS_KEY=your_access_key
SENDGO_SECRET_KEY=your_secret_key
SENDGO_KAKAO_SENDER_KEY=your_kakao_key
SENDGO_SMS_SENDER_KEY=your_sms_key
SENDGO_API_VERSION=v2
```

### 3단계 — 초기화 파일 확인 (`config/initializers/sendgo.rb`)

```ruby
Rails.application.config.sendgo.tap do |config|
  config.access_key       = ENV["SENDGO_ACCESS_KEY"]
  config.secret_key       = ENV["SENDGO_SECRET_KEY"]
  config.kakao_sender_key = ENV["SENDGO_KAKAO_SENDER_KEY"]
  config.sms_sender_key   = ENV["SENDGO_SMS_SENDER_KEY"]
  config.api_version      = ENV.fetch("SENDGO_API_VERSION", "v2")
  config.url              = ENV.fetch("SENDGO_URL", "https://sendgo.io")
end
```

> 설정값을 지정하지 않으면 동일한 이름의 ENV 환경변수로 자동 폴백합니다.
> 즉, 초기화 파일 없이 환경변수만으로도 동작합니다.

### 4단계 — 컨트롤러에서 알림톡 발송

```ruby
class OrdersController < ApplicationController
  def confirm
    order = Order.find(params[:id])

    Sendgo::Rails.client.alimtalk.send(
      template_code: "ORDER_CONFIRM_001",
      contacts: [
        { contact: order.user.phone, name: order.user.name,
          var1: order.number, var2: "#{order.total}원" }
      ]
    )

    render json: { success: true }
  end
end
```

---

## 상세 사용법

`Sendgo::Rails.client`는 코어 `Sendgo::Client` 인스턴스를 메모이즈하여 반환합니다.
`.alimtalk`, `.friendtalk`, `.sms` 서비스를 그대로 사용할 수 있습니다.

### 알림톡

```ruby
# 다건 발송
Sendgo::Rails.client.alimtalk.send(
  template_code: "ORDER_CONFIRM_001",
  contacts: [
    { contact: "01011111111", name: "홍길동", var1: "ORD-001", var2: "29,000원" },
    { contact: "01022222222", name: "김철수", var1: "ORD-002", var2: "15,000원" },
    { contact: "01033333333", name: "이영희", var1: "ORD-003", var2: "52,000원" }
  ]
)

# 예약 발송
Sendgo::Rails.client.alimtalk.send(
  template_code: "PROMO_SUMMER_2026",
  schedule_type: "SCHEDULED",
  at:            "2026-07-28 09:00:00",
  contacts:      [{ contact: "01012345678", var1: "여름 한정 50% 할인" }]
)

# SMS 자동 대체 발송
Sendgo::Rails.client.alimtalk.send(
  template_code: "DELIVERY_START_001",
  replace_sms:   "Y",
  sms_subject:   "[배송 시작 안내]",
  sms_content:   "주문하신 상품이 출고되었습니다.",
  contacts:      [{ contact: "01012345678", var1: "ORD-001", var2: "1234567890" }]
)
```

### 친구톡

```ruby
# 텍스트형
Sendgo::Rails.client.friendtalk.send(
  content:  "안녕하세요! 7월 한정 특가 이벤트를 확인해보세요.",
  contacts: [{ contact: "01012345678" }]
)

# 이미지형
Sendgo::Rails.client.friendtalk.send(
  message_type: "FI",
  content:      "이번 주 특가 상품을 확인하세요!",
  image_url:    "https://cdn.example.com/banner.jpg",
  image_link:   "https://example.com/event",
  contacts:     [{ contact: "01012345678" }]
)

# 버튼 포함
Sendgo::Rails.client.friendtalk.send(
  content:  "7월 쿠폰이 도착했습니다! 지금 바로 사용하세요.",
  buttons:  [{ name: "쿠폰 받기", type: "WL", link_mo: "https://example.com/coupon" }],
  contacts: [{ contact: "01012345678" }]
)
```

### SMS / LMS / MMS

```ruby
# SMS (90자 이하)
Sendgo::Rails.client.sms.send_sms(
  content:  "[Sendgo] 인증번호: 123456 (5분 이내 입력)",
  contacts: [{ contact: "01012345678" }]
)

# LMS (장문, 2,000자 이하)
Sendgo::Rails.client.sms.send_lms(
  subject:  "[중요] 서비스 점검 안내",
  content:  "안녕하세요. 서비스 점검이 예정되어 있습니다.\n■ 일시: 2026-07-25 02:00 ~ 06:00",
  contacts: [{ contact: "01012345678" }]
)

# MMS (이미지 포함)
Sendgo::Rails.client.sms.send_mms(
  subject:  "[이벤트] 7월 특가",
  content:  "이번 달 특가 상품을 확인하세요!",
  contacts: [{ contact: "01011111111" }, { contact: "01022222222" }]
)
```

---

## Active Job 비동기 발송

발송은 외부 API 호출이므로 백그라운드 잡으로 처리하는 것을 권장합니다.

```ruby
# app/jobs/send_alimtalk_job.rb
class SendAlimtalkJob < ApplicationJob
  queue_as :notifications
  retry_on Sendgo::Error, wait: 10.seconds, attempts: 3

  def perform(template_code, contacts)
    Sendgo::Rails.client.alimtalk.send(
      template_code: template_code,
      contacts:      contacts
    )
  end
end

# 디스패치 예시
SendAlimtalkJob.perform_later("ORDER_CONFIRM_001", [
  { contact: "01012345678", var1: "ORD-001" }
])
```

서비스 클래스 패턴도 자연스럽게 사용할 수 있습니다.

```ruby
# app/services/notification_service.rb
class NotificationService
  def initialize(client = Sendgo::Rails.client)
    @client = client
  end

  def send_order_confirm(phone:, order_no:, amount:)
    @client.alimtalk.send(
      template_code: "ORDER_CONFIRM_001",
      contacts:      [{ contact: phone, var1: order_no, var2: amount }]
    )
  end
end
```

---

## 예외 처리

```ruby
begin
  Sendgo::Rails.client.alimtalk.send(template_code: "ORDER_CONFIRM_001", contacts: [...])
rescue Sendgo::Error => e
  Rails.logger.error "Sendgo 발송 실패: HTTP #{e.status_code} [#{e.error_code}]"

  case e.error_code
  when "INVALID_ACCESS_KEY", "INVALID_SECRET_KEY"
    alert_ops("Sendgo 인증키를 확인하세요.")
  when "INVALID_TEMPLATE_CODE"
    Rails.logger.warn("존재하지 않는 템플릿: #{e.message}")
  when "PAYMENT_REQUIRED"
    alert_ops("Sendgo 크레딧이 부족합니다.")
  when "IP_NOT_ALLOWED"
    alert_ops("허용되지 않은 IP")
  end
end
```

---

## 설정 옵션

`config/initializers/sendgo.rb`에서 `Rails.application.config.sendgo`로 설정합니다.
각 값이 비어 있으면 동일 이름의 환경변수로 폴백합니다.

| 키 | 환경변수 | 기본값 | 설명 |
|----|---------|--------|------|
| `access_key` | `SENDGO_ACCESS_KEY` | — | Sendgo 액세스 키 |
| `secret_key` | `SENDGO_SECRET_KEY` | — | Sendgo 시크릿 키 |
| `kakao_sender_key` | `SENDGO_KAKAO_SENDER_KEY` | `nil` | 카카오 발신프로필 키 |
| `sms_sender_key` | `SENDGO_SMS_SENDER_KEY` | `nil` | SMS 발신자 키 |
| `api_version` | `SENDGO_API_VERSION` | `"v2"` | API 버전 |
| `url` | `SENDGO_URL` | `"https://sendgo.io"` | API 기본 URL |

> 테스트에서 설정을 바꾼 뒤에는 `Sendgo::Rails.reset!`을 호출해 메모이즈된 클라이언트를 초기화하세요.

---

## 자주 묻는 질문 (FAQ)

**Q. `sendgo`(코어 젬)와의 차이는 무엇인가요?**
A. `sendgo`는 프레임워크 독립적인 순수 Ruby 코어 젬입니다. `sendgo-rails`는 이를 확장해 Railtie 자동 등록, `config.sendgo` 설정 바인딩, 초기화 제너레이터, 메모이즈된 `Sendgo::Rails.client`를 추가합니다.

**Q. 어떤 Rails 버전을 지원하나요?**
A. `railties >= 6.1`을 지원합니다. (Rails 6.1, 7.x 이상)

**Q. 초기화 파일 없이 환경변수만으로 쓸 수 있나요?**
A. 네. 설정값이 없으면 `SENDGO_*` 환경변수로 자동 폴백하므로 `bin/rails g sendgo:install` 없이도 동작합니다.

**Q. 테스트 시 클라이언트를 초기화하려면?**
A. `Sendgo::Rails.reset!`을 호출하면 메모이즈된 클라이언트가 초기화되어 다음 호출 시 다시 생성됩니다.

---

## 관련 패키지

| 언어/프레임워크 | 패키지 | GitHub |
|----------------|--------|--------|
| Ruby (코어) | `sendgo` | [ruby](https://github.com/send-go/ruby) |
| PHP (Laravel) | `sendgo/laravel` | [laravel](https://github.com/send-go/laravel) |
| Spring Boot | `io.sendgo:sendgo-spring` | [spring](https://github.com/send-go/spring) |
| Node.js | `@sendgo/node` | [node](https://github.com/send-go/node) |
| Python | `sendgo-python` | [python](https://github.com/send-go/python) |
| 전체 목록 | — | [send-go GitHub 조직](https://github.com/send-go) |

---

## 브랜드메시지 · 짧은 URL

이 패키지는 코어(`sendgo`)의 클라이언트를 그대로 노출하므로, 코어에 있는 채널이
모두 그대로 쓸 수 있습니다. 두 기능 모두 **v2 전용**입니다.

| 기능 | 접근 |
|------|------|
| 카카오 브랜드메시지 (친구톡의 후속 채널) | `client.brand_message` |
| 짧은 URL (단축 + 클릭 반응 분석) | `client.short_url` |

브랜드메시지는 채널 친구가 아닌 수신자에게도 보낼 수 있고(`targeting` = `N`),
수신 동의한 전체 채널 친구에게 동보 발송할 수도 있습니다(`targeting` = `F`).

짧은 URL 은 메시지 본문의 링크를 줄이고 클릭 반응(일별 추이·디바이스·유입경로·국가)을
집계합니다.

사용 예시와 파라미터는 [코어 README](https://github.com/send-go) 와
[SDK 가이드](https://sendgo.io/ko/sdk) 를 참고하세요.

## 변경 사항

### 1.1.0 (2026-08-11)

- `Sendgo::Rails.client.short_url` 사용법 문서화

## 라이선스

MIT License © 2026 [Sendgo](https://sendgo.io)

---

*키워드: 카카오 알림톡 Rails, 카카오 친구톡 Rails, SMS 발송 Rails, 알림톡 Rails gem, Rails 카카오 API 연동, Rails Railtie, Sendgo Rails SDK*
