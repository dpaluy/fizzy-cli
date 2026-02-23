# frozen_string_literal: true

module Fizzy
  class Error < StandardError
    attr_reader :status, :body

    def initialize(message = nil, status: nil, body: nil)
      super(message)
      @status = status
      @body = body
    end
  end

  class BadRequestError < Error; end
  class AuthError < Error; end
  class NotFoundError < Error; end
  class ValidationError < Error; end
  class ForbiddenError < Error; end
  class ServerError < Error; end
  class RateLimitError < Error; end
  class NetworkError < Error; end
end
