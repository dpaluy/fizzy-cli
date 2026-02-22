# frozen_string_literal: true

module Fizzy
  class Paginator
    def initialize(client)
      @client = client
    end

    def all(path, params: {})
      items = []
      each_page(path, params: params) { |page| items.concat(Array(page)) }
      items
    end

    def each_page(path, params: {})
      current_path = path
      current_params = params

      loop do
        response = @client.get(current_path, params: current_params)
        yield response.body if block_given?

        next_path = parse_next_link(response.headers)
        break unless next_path

        current_path = next_path
        current_params = {}
      end
    end

    private

    def parse_next_link(headers)
      link = headers["link"]&.first
      return unless link

      match = link.match(/<([^>]+)>;\s*rel="next"/)
      return unless match

      URI(match[1]).request_uri
    end
  end
end
