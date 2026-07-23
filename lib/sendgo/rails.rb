require "sendgo"
require "sendgo/rails/version"

# Rails가 로드된 환경에서만 Railtie를 등록한다.
# (순수 Ruby 환경에서 `require "sendgo/rails"`가 동작하도록 가드)
require "sendgo/rails/railtie" if defined?(::Rails::Railtie)

module Sendgo
  # Rails 통합 모듈.
  #
  # `Rails.application.config.sendgo`(ActiveSupport::OrderedOptions) 설정을
  # 우선 사용하고, 값이 없으면 ENV 환경변수로 폴백하여 `Sendgo::Client`를 생성한다.
  #
  # @example 컨트롤러에서 사용
  #   Sendgo::Rails.client.alimtalk.send(
  #     template_code: "ORDER_CONFIRM_001",
  #     contacts: [{ contact: "01012345678", var1: "ORD-001" }]
  #   )
  module Rails
    class << self
      # 메모이즈된 Sendgo::Client 인스턴스를 반환한다.
      #
      # @return [Sendgo::Client]
      def client
        @client ||= build_client
      end

      # 메모이즈된 클라이언트를 초기화한다. (주로 테스트에서 사용)
      #
      # @return [void]
      def reset!
        @client = nil
      end

      private

      # 설정(config.sendgo) + ENV 폴백으로 Sendgo::Client를 생성한다.
      def build_client
        Sendgo::Client.new(
          access_key:       config_value(:access_key,       "SENDGO_ACCESS_KEY"),
          secret_key:       config_value(:secret_key,       "SENDGO_SECRET_KEY"),
          kakao_sender_key: config_value(:kakao_sender_key, "SENDGO_KAKAO_SENDER_KEY"),
          sms_sender_key:   config_value(:sms_sender_key,   "SENDGO_SMS_SENDER_KEY"),
          api_version:      config_value(:api_version,      "SENDGO_API_VERSION") || "v2",
          base_url:         config_value(:url,              "SENDGO_URL") || "https://sendgo.io"
        )
      end

      # config.sendgo 값 → ENV 값 순으로 설정을 조회한다.
      def config_value(key, env_key)
        value = sendgo_config&.public_send(key)
        value.nil? ? ENV[env_key] : value
      end

      # Rails 애플리케이션의 config.sendgo(OrderedOptions)를 반환한다.
      # Rails가 없으면 nil을 반환하여 ENV 폴백만 사용한다.
      def sendgo_config
        return nil unless defined?(::Rails) && ::Rails.respond_to?(:application) && ::Rails.application

        ::Rails.application.config.sendgo
      end
    end
  end
end
