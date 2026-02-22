# frozen_string_literal: true

module Fizzy
  class CLI < Thor
    class Comments < Thor
      include Base

      desc "list", "List comments on a card"
      option :card, required: true, type: :numeric, desc: "Card number"
      def list
        data = paginator.all("#{slug}/cards/#{options[:card]}/comments")
        output_list(data, headers: %w[ID Author Created]) do |c|
          [c["id"], c.dig("creator", "name"), c["created_at"]]
        end
      end

      desc "get COMMENT_ID", "Show a comment"
      option :card, required: true, type: :numeric, desc: "Card number"
      def get(comment_id)
        resp = client.get("#{slug}/cards/#{options[:card]}/comments/#{comment_id}")
        c = resp.body
        output_detail(c, pairs: [
                        ["ID", c["id"]],
                        ["Author", c.dig("creator", "name")],
                        ["Body", c["body"]],
                        ["Created", c["created_at"]]
                      ])
      end

      desc "create BODY", "Add a comment to a card"
      option :card, required: true, type: :numeric, desc: "Card number"
      def create(body_text)
        resp = client.post("#{slug}/cards/#{options[:card]}/comments", body: { body: body_text })
        c = resp.body
        output_detail(c, pairs: [
                        ["ID", c["id"]],
                        ["Body", c["body"]]
                      ])
      end

      desc "update COMMENT_ID", "Update a comment"
      option :card, required: true, type: :numeric, desc: "Card number"
      option :body, required: true, desc: "New body"
      def update(comment_id)
        resp = client.put("#{slug}/cards/#{options[:card]}/comments/#{comment_id}", body: build_body(:body))
        c = resp.body
        output_detail(c, pairs: [
                        ["ID", c["id"]],
                        ["Body", c["body"]]
                      ])
      end

      desc "delete COMMENT_ID", "Delete a comment"
      option :card, required: true, type: :numeric, desc: "Card number"
      def delete(comment_id)
        client.delete("#{slug}/cards/#{options[:card]}/comments/#{comment_id}")
        puts "Comment #{comment_id} deleted."
      end
    end
  end
end
