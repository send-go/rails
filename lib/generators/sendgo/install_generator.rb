require "rails/generators/base"

module Sendgo
  module Generators
    # `bin/rails g sendgo:install` 제너레이터.
    #
    # config/initializers/sendgo.rb 초기화 파일을 생성한다.
    class InstallGenerator < ::Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      desc "Sendgo 초기화 파일(config/initializers/sendgo.rb)을 생성합니다."

      # 초기화 파일 템플릿을 복사한다.
      def copy_initializer
        template "sendgo.rb.tt", "config/initializers/sendgo.rb"
      end
    end
  end
end
