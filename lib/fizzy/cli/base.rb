# frozen_string_literal: true

require "thor"

module Fizzy
  class CLI < Thor
    module Base
      def self.included(base)
        base.class_eval do
          def self.exit_on_failure? = true
        end
      end

      private

      def global_options
        parent_options || options
      end

      def account
        @account ||= Auth.resolve(global_options[:account])
      end

      def client
        @client ||= Client.new(
          token: account["access_token"],
          account_slug: account["account_slug"]
        )
      end

      def slug
        "/#{client.account_slug}"
      end

      def paginator
        @paginator ||= Paginator.new(client)
      end

      def json?
        global_options[:json]
      end

      def build_body(*keys)
        keys.each_with_object({}) do |key, body|
          val = options[key]
          body[key] = val unless val.nil?
        end
      end

      def output_list(data, headers:, &row_mapper)
        if json?
          Formatter.json(data)
        else
          rows = Array(data).map(&row_mapper)
          Formatter.table(rows, headers: headers)
        end
      end

      def output_detail(data, pairs:)
        if json?
          Formatter.json(data)
        else
          Formatter.detail(pairs)
        end
      end
    end
  end
end
