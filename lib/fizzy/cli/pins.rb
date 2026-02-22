# frozen_string_literal: true

module Fizzy
  class CLI < Thor
    class Pins < Thor
      include Base

      desc "list", "List pinned cards"
      def list
        data = paginator.all("/my/pins")
        output_list(data, headers: %w[# Title Board]) do |p|
          card = p["card"] || p
          [card["number"], card["title"], card.dig("board", "name") || ""]
        end
      end

      desc "pin NUMBER", "Pin a card"
      def pin(number)
        client.post("#{slug}/cards/#{number}/pin")
        puts "Card ##{number} pinned."
      end

      desc "unpin NUMBER", "Unpin a card"
      def unpin(number)
        client.delete("#{slug}/cards/#{number}/pin")
        puts "Card ##{number} unpinned."
      end
    end
  end
end
