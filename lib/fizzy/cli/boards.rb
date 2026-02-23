# frozen_string_literal: true

module Fizzy
  class CLI < Thor
    class Boards < Thor
      include Base

      desc "list", "List all boards"
      def list
        data = paginator.all("boards")
        output_list(data, headers: %w[ID Name Cards Columns]) do |b|
          [b["id"], b["name"], b["open_cards_count"], b["columns_count"]]
        end
      end

      desc "get BOARD_ID", "Show a board"
      def get(board_id)
        resp = client.get("boards/#{board_id}")
        b = resp.body
        output_detail(b, pairs: [
                        ["ID", b["id"]],
                        ["Name", b["name"]],
                        ["Open cards", b["open_cards_count"]],
                        ["Columns", b["columns_count"]],
                        ["Created", b["created_at"]]
                      ])
      end

      desc "create NAME", "Create a board"
      def create(name)
        resp = client.post("boards", body: { name: name })
        b = resp.body
        output_detail(b, pairs: [
                        ["ID", b["id"]],
                        ["Name", b["name"]]
                      ])
      end

      desc "update BOARD_ID", "Update a board"
      option :name, required: true, desc: "New board name"
      def update(board_id)
        resp = client.put("boards/#{board_id}", body: { name: options[:name] })
        b = resp.body
        if b
          output_detail(b, pairs: [
                          ["ID", b["id"]],
                          ["Name", b["name"]]
                        ])
        else
          puts "Board #{board_id} updated."
        end
      end

      desc "delete BOARD_ID", "Delete a board"
      def delete(board_id)
        client.delete("boards/#{board_id}")
        puts "Board #{board_id} deleted."
      end
    end
  end
end
