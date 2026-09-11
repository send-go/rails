# sendgo-rails

> **Rails에서 카카오 알림톡, 브랜드메시지, SMS를 가장 쉽게 발송하는 공식 Rails 확장 젬**

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

> ⚠️ **Deprecated — 친구톡은 카카오 정책에 따라 2025-12-31 종료되었습니다.**
> 2026-01-01 부터 친구톡 발송 요청은 카카오 측에서 **브랜드메시지(자유형)** 로 자동 대체 발송됩니다.
> 호출은 계속 성공하며, 자유 본문 타입(`FT`/`FI`/`FW`)을 개별 수신자에게 보내는 경로는
> 현재 이것뿐이므로 기존 코드를 당장 바꿀 필요는 없습니다.
>
> 다음의 경우에는 **브랜드메시지**를 사용하세요.
> - 템플릿 기반 리치 타입 (`FL`/`FC`/`FM`/`FP`/`FA`)
> - 채널 친구가 **아닌** 수신자 (`targeting` = `N` / `I`)
> - 수신 동의한 전체 채널 친구 동보 (`targeting` = `F`)
>
> 메시지 타입은 1:1 대응되며 변환은 서버가 처리합니다 — `FT`→`BT`, `FI`→`BI`, `FW`→`BW`,
> `FL`→`BL`, `FC`→`BC`, `FM`→`BM`, `FP`→`BP`, `FA`→`BA`.

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

## 관리 API — 채널·템플릿·발신번호 등록 (v2 전용)

`Sendgo::Rails.client` 에 코어의 관리 서비스가 그대로 붙어 있습니다.
콘솔에서만 되던 등록·심사를 컨트롤러나 rake 태스크에서 처리할 수 있습니다.

| 접근 | 하는 일 | 계정 |
| --- | --- | --- |
| `.kakao_senders` | 카카오 채널 인증·등록·동기화, 브랜드메시지 M/N 신청 | 기업 |
| `.notice_templates` | 알림톡 템플릿 CRUD, 검수 요청·취소, 승인 취소, 휴면 해제 | 기업 |
| `.brand_templates` | 브랜드메시지 템플릿 CRUD, 동기화, 가져오기 | 기업 |
| `.sender_registration` | 발신번호 등록 신청, 중복 확인, 유형 안내 | 개인·기업 |
| `.message_templates` | 문자 상용구 템플릿 CRUD | 개인·기업 |
| `.kakao_images` | 카카오 이미지 업로드 — 템플릿용 URL 발급 | 기업 |
| `.rejected_numbers` | 수신거부(080) 번호 조회 | 개인·기업 |
| `.webhook` | 이벤트 웹훅 구독 — 심사 결과 수신 | 개인·기업 |

> **sendgo.io 콘솔에 들어올 일이 없습니다.** 고객의 채널·발신번호·템플릿을
> 여러분 화면만으로 끝까지 처리할 수 있습니다. 휴대폰 발신번호는 콘솔의 PASS
> 본인인증 대신 **신분증 사본(`identityDocument`)을 받아 sendgo 운영자가 대신
> 심사**합니다.
>
> 사람이 개입하는 지점은 **카카오 채널 인증번호 하나**뿐이고, 그마저도
> 여러분 화면에서 입력받으면 됩니다 — 카카오가 관리자 휴대폰으로 직접 보내는
> 확인이라 없앨 수 없습니다.
>
> 심사가 붙는 것들은 **비동기**입니다. 등록 호출이 성공했다는 건 "접수됐다"는
> 뜻이지 "쓸 수 있다"는 뜻이 아닙니다 — 웹훅을 구독해 결과를 받으세요.

```ruby
# app/controllers/onboarding_controller.rb
class OnboardingController < ApplicationController
  # 1단계 — 카카오가 관리자 휴대폰으로 인증번호를 SMS 발송한다
  def request_channel_code
    Sendgo::Rails.client.kakao_senders.request_token(params[:yellow_id], params[:phone])
    render json: { message: "인증번호를 발송했습니다." }
  end

  # 2단계 — 사용자가 입력한 인증번호로 발신프로필 생성
  def create_channel
    created = Sendgo::Rails.client.kakao_senders.create(
      token: params[:code],
      yellow_id: params[:yellow_id],
      phone_number: params[:phone],
      category_code: "001001"
    )

    render json: created.dig("data", "sender")
  end
end
```

```ruby
# lib/tasks/sendgo.rake
namespace :sendgo do
  desc "표준 알림톡 템플릿을 등록하고 검수를 요청한다"
  task :provision_templates, [:kakao_sender_key] => :environment do |_t, args|
    created = Sendgo::Rails.client.notice_templates.create(
      kakao_sender_key: args[:kakao_sender_key],
      template_name: "주문 접수 안내",
      template_content: "\#{name}님, 주문 \#{orderNo}이 접수되었습니다.",
      template_message_type: "BA",
      template_emphasize_type: "NONE",
      category_code: "001001",
      message_purpose: "order_delivery",
      legal_basis: "transaction",
      benefit_origin: "none",
      expiry_type: "none"
    )

    code = created.dig("data", "template", "templateCode")
    Sendgo::Rails.client.notice_templates.request_inspection(code)

    puts "검수 요청 완료: #{code}"
  end

  desc "검수 결과를 확인한다 — 30분마다 돌린다"
  task poll_inspections: :environment do
    PendingTemplate.where(approved_at: nil).find_each do |pending|
      result = Sendgo::Rails.client.notice_templates.sync(pending.template_code)
      status = result.dig("data", "template", "inspectionStatus")

      pending.update!(approved_at: Time.current) if status == "APR"
      pending.update!(rejected_reason: result.dig("data", "template", "comments")) if status == "REJ"
    end
  end
end
```

검수는 30분~1영업일 걸립니다. 배포 파이프라인 안에서 동기적으로 기다리지 말고
`solid_queue` 나 cron 으로 폴링하세요.

전체 파라미터는 [sendgo gem README](https://github.com/send-go/ruby) 를 참고하세요.

---

## 변경 사항

### 1.3.0 (2026-09-11)

- **관리 API 노출** — 코어 1.3.0 의 `kakao_senders` · `notice_templates` ·
  `brand_templates` · `sender_registration` · `message_templates` 를
  `Sendgo::Rails.client` 에서 그대로 쓸 수 있습니다. 콘솔에서만 되던 채널 등록,
  알림톡 템플릿 검수 요청, 발신번호 심사 접수를 컨트롤러나 rake 태스크에서
  처리합니다.
- `sendgo` 젬 의존성을 `~> 1.3` 으로 올렸습니다.
- **이벤트 웹훅** 추가 — 발신번호 승인, 알림톡 검수 결과, 채널 차단,
  브랜드메시지 타겟팅 결과를 구독해 받습니다. 서명은 받은 원본 바이트로
  검증합니다(SDK 에 검증 헬퍼 포함).
- **카카오 이미지 업로드** 추가 — 브랜드메시지 템플릿의 `imageUrl` 은 카카오가
  호스팅하는 URL 이어야 하는데, 그 URL 을 얻는 길이 콘솔에만 있었습니다.
- **수신거부(080) 조회** 추가 — 자기 DB 의 수신 상태를 맞출 수 있습니다.

### 1.2.1 (2026-08-14)

- 레지스트리 목록에 노출되는 패키지 설명에서 친구톡을 브랜드메시지로 교체했습니다.
  npm/PyPI/Packagist/Maven/NuGet/RubyGems 검색 결과에 그대로 찍히는 문자열이라
  종료된 채널을 계속 홍보하고 있었습니다.
- 검색 키워드에 `brand-message` 를 추가했습니다 (`friendtalk` 은 유입 검색어라 유지).

### 1.2.0 (2026-08-14)

- **친구톡 Deprecated 표기** — 친구톡은 카카오 정책에 따라 2025-12-31 종료되었고,
  2026-01-01 부터 발송 요청이 브랜드메시지(자유형)로 자동 대체 발송됩니다.
  관련 API 에 각 언어의 표준 deprecation 표기를 달았습니다.
- 자유 본문 타입(`FT`/`FI`/`FW`)의 개별 발송 경로는 아직 친구톡 API 뿐이라는 점을
  문서에 명시했습니다 — 브랜드메시지 API 는 그 조합에 `NOT_A_BRAND_MESSAGE` 를 반환합니다.
- 브랜드메시지 전환 안내와 메시지 타입 1:1 대응표를 README 에 추가했습니다.

### 1.1.0 (2026-08-11)

- `Sendgo::Rails.client.short_url` 사용법 문서화

## 라이선스

MIT License © 2026 [Sendgo](https://sendgo.io)

---

*키워드: 카카오 알림톡 Rails, 카카오 친구톡 Rails, SMS 발송 Rails, 알림톡 Rails gem, Rails 카카오 API 연동, Rails Railtie, Sendgo Rails SDK*
