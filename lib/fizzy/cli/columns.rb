# frozen_string_literal: true

module Fizzy
  class CLI < Thor
    class Columns < Thor
      include Base

      desc "list", "List columns for a board"
      option :board, desc: "Board ID"
      def list
        data = paginator.all("boards/#{require_board!}/columns")
        output_list(data, headers: %w[ID Name Position]) do |c|
          [c["id"], c["name"], c["position"]]
        end
      end

      desc "get COLUMN_ID", "Show a column"
      option :board, desc: "Board ID"
      def get(column_id)
        resp = client.get("boards/#{require_board!}/columns/#{column_id}")
        c = resp.body
        output_detail(c, pairs: [
                        ["ID", c["id"]],
                        ["Name", c["name"]],
                        ["Position", c["position"]],
                        ["Created", c["created_at"]]
                      ])
      end

      desc "create NAME", "Create a column"
      option :board, desc: "Board ID"
      def create(name)
        resp = client.post("boards/#{require_board!}/columns", body: { name: name })
        c = resp.body
        output_detail(c, pairs: [
                        ["ID", c["id"]],
                        ["Name", c["name"]]
                      ])
      end

      desc "update COLUMN_ID", "Update a column"
      option :board, desc: "Board ID"
      option :name, required: true, desc: "New column name"
      def update(column_id)
        resp = client.put("boards/#{require_board!}/columns/#{column_id}", body: { name: options[:name] })
        c = resp.body
        output_detail(c, pairs: [
                        ["ID", c["id"]],
                        ["Name", c["name"]]
                      ])
      end

      desc "delete COLUMN_ID", "Delete a column"
      option :board, desc: "Board ID"
      def delete(column_id)
        client.delete("boards/#{require_board!}/columns/#{column_id}")
        puts "Column #{column_id} deleted."
      end
    end
  end
end
