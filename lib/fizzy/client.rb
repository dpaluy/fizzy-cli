# frozen_string_literal: true

module Fizzy
  Response = Data.define(:body, :headers, :status)

  class Client
    BASE_URL = "https://app.fizzy.do"

    def initialize(token:, account_slug:)
      @token = token
      @account_slug = account_slug
    end

    def get(path, params: {})
      request(:get, path, params: params)
    end

    def post(path, body: nil)
      request(:post, path, body: body)
    end

    def put(path, body: nil)
      request(:put, path, body: body)
    end

    def delete(path)
      request(:delete, path)
    end

    private

    def connection
      @connection ||= begin
        uri = URI(BASE_URL)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.open_timeout = 5
        http.read_timeout = 30
        http.start
        at_exit do
          http.finish
        rescue StandardError
          nil
        end
        http
      end
    end

    def request(method, path, body: nil, params: {})
      full_path = path.start_with?("/") ? path : "/#{@account_slug}/#{path}"
      uri = URI("#{BASE_URL}#{full_path}")
      uri.query = URI.encode_www_form(params) unless params.empty?

      req = build_request(method, uri)
      req["Authorization"] = "Bearer #{@token}"
      req["Accept"] = "application/json"

      if body
        req["Content-Type"] = "application/json"
        req.body = body.to_json
      end

      response = connection.request(req)
      handle_response(response)
    rescue Net::OpenTimeout, Net::ReadTimeout, SocketError, Errno::ECONNREFUSED => e
      raise NetworkError, "Network error: #{e.message}"
    end

    def build_request(method, uri)
      case method
      when :get    then Net::HTTP::Get.new(uri)
      when :post   then Net::HTTP::Post.new(uri)
      when :put    then Net::HTTP::Put.new(uri)
      when :delete then Net::HTTP::Delete.new(uri)
      end
    end

    def handle_response(response)
      status = response.code.to_i
      parsed_body = parse_body(response)

      case status
      when 200..299
        # Follow Location header on 201 to fetch the created resource
        if status == 201 && parsed_body.nil? && response["location"]
          location = response["location"].sub(/\.json$/, "")
          return get(location)
        end

        Response.new(body: parsed_body, headers: response.to_hash, status: status)
      when 301, 302
        raise AuthError.new("Redirected to #{response["location"]} — endpoint may require session auth",
                            status: status, body: parsed_body)
      when 401
        raise AuthError.new("Authentication failed (401)", status: 401, body: parsed_body)
      when 403
        raise ForbiddenError.new("Forbidden (403)", status: 403, body: parsed_body)
      when 404
        raise NotFoundError.new("Not found (404)", status: 404, body: parsed_body)
      when 422
        raise ValidationError.new(parse_error(response), status: 422, body: parsed_body)
      when 429
        raise RateLimitError.new("Rate limited (429)", status: 429, body: parsed_body)
      else
        raise ServerError.new("HTTP #{response.code}: #{response.body}", status: status, body: parsed_body)
      end
    end

    def parse_body(response)
      body = response.body&.strip
      body.nil? || body.empty? ? nil : JSON.parse(body)
    rescue JSON::ParserError
      nil
    end

    def parse_error(response)
      data = JSON.parse(response.body)

      if data["errors"].is_a?(Array) && data["errors"].any?
        items = data["errors"].map do |e|
          e.is_a?(Hash) ? "#{e["field"]}: #{e["message"]}" : e.to_s
        end
        "Validation failed\n  - #{items.join("\n  - ")}"
      else
        data["error"] || response.body
      end
    rescue JSON::ParserError
      response.body
    end
  end
end
