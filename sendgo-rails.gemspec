require_relative "lib/sendgo/rails/version"

Gem::Specification.new do |spec|
  spec.name          = "sendgo-rails"
  spec.version       = Sendgo::Rails::VERSION
  spec.authors       = ["Sendgo"]
  spec.email         = ["dev@sendgo.io"]
  spec.summary       = "Sendgo Rails 통합 — 카카오 알림톡/친구톡, SMS/LMS/MMS"
  spec.description   = "Sendgo Ruby SDK를 Rails에 통합하는 공식 확장 젬입니다. Railtie 자동 등록, 설정 초기화 제너레이터, ENV 폴백 클라이언트를 제공합니다."
  spec.homepage      = "https://sendgo.io"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.0"

  spec.metadata["source_code_uri"] = "https://github.com/send-go/rails"
  spec.metadata["homepage_uri"]    = "https://sendgo.io"

  spec.files         = Dir["lib/**/*", "README.md", "LICENSE"]
  spec.require_paths = ["lib"]

  spec.add_dependency "sendgo", "~> 1.0"
  spec.add_dependency "railties", ">= 6.1"
end
