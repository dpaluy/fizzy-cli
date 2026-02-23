# frozen_string_literal: true

module Fizzy
  class CLI < Thor
    class Reactions < Thor
      include Base

      desc "list", "List reactions on a card"
      option :card, required: true, type: :numeric, desc: "Card number"
      option :comment, desc: "Comment ID (for comment reactions)"
      def list
        path = reaction_path(options[:card], options[:comment])
        data = paginator.all(path)
        output_list(data, headers: %w[ID Content User]) do |r|
          [r["id"], r["content"], r.dig("creator", "name")]
        end
      end

      desc "create CONTENT", "Add a reaction"
      option :card, required: true, type: :numeric, desc: "Card number"
      option :comment, desc: "Comment ID (for comment reactions)"
      def create(content)
        path = reaction_path(options[:card], options[:comment])
        resp = client.post(path, body: { content: content })
        r = resp.body
        output_detail(r, pairs: [
                        ["ID", r["id"]],
                        ["Content", r["content"]]
                      ])
      end

      desc "delete REACTION_ID", "Remove a reaction"
      option :card, required: true, type: :numeric, desc: "Card number"
      option :comment, desc: "Comment ID (for comment reactions)"
      def delete(reaction_id)
        path = "#{reaction_path(options[:card], options[:comment])}/#{reaction_id}"
        client.delete(path)
        puts "Reaction #{reaction_id} deleted."
      end

      private

      def reaction_path(card_number, comment_id = nil)
        base = "cards/#{card_number}"
        comment_id ? "#{base}/comments/#{comment_id}/reactions" : "#{base}/reactions"
      end
    end
  end
end
