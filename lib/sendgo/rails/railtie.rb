# Rails가 존재할 때만 Railtie를 정의한다.
# (순수 Ruby 환경에서 이 파일이 require되어도 안전하게 no-op)
if defined?(::Rails::Railtie)
  module Sendgo
    module Rails
      # Sendgo Rails 통합 Railtie.
      #
      # `config.sendgo`(ActiveSupport::OrderedOptions)를 기본 등록하여
      # `config/initializers/sendgo.rb`에서 설정값을 지정할 수 있게 한다.
      class Railtie < ::Rails::Railtie
        # config.sendgo 네임스페이스 초기화
        config.sendgo = ActiveSupport::OrderedOptions.new

        # 애플리케이션 부팅 시점에 추가 초기화가 필요하면 여기서 처리한다.
        initializer "sendgo.rails.setup" do
          # 현재는 config.sendgo 등록만으로 충분하므로 별도 동작 없음.
          # (지연 초기화: 클라이언트는 Sendgo::Rails.client 최초 호출 시 생성)
        end
      end
    end
  end
end
