# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "fizzy"

require "minitest/autorun"
require "webmock/minitest"

module TestConfig
  def setup_config
    WebMock.reset!
  end

  def teardown_config
    WebMock.reset!
  end
end
