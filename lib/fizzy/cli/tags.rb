# frozen_string_literal: true

module Fizzy
  class CLI < Thor
    class Tags < Thor
      include Base

      desc "list", "List all tags"
      def list
        data = paginator.all("tags")
        output_list(data, headers: %w[ID Title Color]) do |t|
          [t["id"], t["title"] || t["name"], t["color"]]
        end
      end
    end
  end
end
