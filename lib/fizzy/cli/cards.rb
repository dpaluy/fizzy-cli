# frozen_string_literal: true

module Fizzy
  class CLI < Thor
    class Cards < Thor
      include Base

      desc "list", "List cards"
      option :board, desc: "Board ID (filter)"
      option :column, desc: "Column ID (filter)"
      option :status, desc: "Filter: open, closed, all", default: "open"
      option :assignee, desc: "Assignee user ID (filter)"
      option :tag, desc: "Tag ID (filter, repeatable)", type: :array
      def list
        params = {}
        params[:status] = options[:status] if options[:status]
        params[:board_id] = options[:board] if options[:board]
        params[:column_id] = options[:column] if options[:column]
        params[:assignee_id] = options[:assignee] if options[:assignee]
        options[:tag]&.each { |t| (params[:"tag_ids[]"] ||= []) << t }

        data = paginator.all("cards", params: params)
        output_list(data, headers: %w[# Title Board Status Column]) do |c|
          [
            c["number"],
            Formatter.truncate(c["title"], 50),
            c.dig("board", "name") || "",
            c["status"],
            c.dig("column", "name") || ""
          ]
        end
      end

      desc "get NUMBER", "Show a card"
      def get(number)
        resp = client.get("cards/#{number}")
        c = resp.body
        output_detail(c, pairs: [
                        ["Number", "##{c["number"]}"],
                        ["Title", c["title"]],
                        ["Board", c.dig("board", "name")],
                        ["Column", c.dig("column", "name")],
                        ["Status", c["status"]],
                        ["Creator", c.dig("creator", "name")],
                        ["Assignees", format_assignees(c["assignees"])],
                        ["Tags", format_tags(c["tags"])],
                        ["Steps", format_steps(c["steps"])],
                        ["Created", c["created_at"]],
                        ["URL", c["url"]]
                      ])
      end

      desc "create TITLE", "Create a card"
      option :board, desc: "Board ID"
      option :body, desc: "Card body (HTML)"
      option :column, desc: "Column ID"
      def create(title)
        body = { title: title }
        body[:body] = options[:body] if options[:body]
        body[:column_id] = options[:column] if options[:column]
        resp = client.post("boards/#{require_board!}/cards", body: body)
        c = resp.body
        output_detail(c, pairs: [
                        ["Number", "##{c["number"]}"],
                        ["Title", c["title"]],
                        ["URL", c["url"]]
                      ])
      end

      desc "update NUMBER", "Update a card"
      option :title, desc: "New title"
      option :body, desc: "New body (HTML)"
      def update(number)
        resp = client.put("cards/#{number}", body: build_body(:title, :body))
        c = resp.body
        output_detail(c, pairs: [
                        ["Number", "##{c["number"]}"],
                        ["Title", c["title"]]
                      ])
      end

      desc "delete NUMBER", "Delete a card"
      def delete(number)
        client.delete("cards/#{number}")
        puts "Card ##{number} deleted."
      end

      desc "close NUMBER", "Close a card"
      def close(number)
        client.post("cards/#{number}/closure")
        puts "Card ##{number} closed."
      end

      desc "reopen NUMBER", "Reopen a closed card"
      def reopen(number)
        client.delete("cards/#{number}/closure")
        puts "Card ##{number} reopened."
      end

      desc "not-now NUMBER", "Mark a card as not-now"
      map "not-now" => :not_now
      def not_now(number)
        client.post("cards/#{number}/not_now")
        puts "Card ##{number} marked not-now."
      end

      desc "triage NUMBER", "Triage a card into a column"
      option :column, required: true, desc: "Column ID"
      def triage(number)
        client.post("cards/#{number}/triage", body: { column_id: options[:column] })
        puts "Card ##{number} triaged."
      end

      desc "untriage NUMBER", "Remove a card from triage"
      def untriage(number)
        client.delete("cards/#{number}/triage")
        puts "Card ##{number} untriaged."
      end

      desc "tag NUMBER TAG_TITLE", "Add a tag to a card"
      def tag(number, tag_title)
        client.post("cards/#{number}/taggings", body: { tag_title: tag_title })
        puts "Tag '#{tag_title}' added to card ##{number}."
      end

      desc "assign NUMBER ASSIGNEE_ID", "Toggle assignment on a card"
      def assign(number, assignee_id)
        client.post("cards/#{number}/assignments", body: { assignee_id: assignee_id })
        puts "Assignment toggled for card ##{number}."
      end

      desc "watch NUMBER", "Watch a card"
      def watch(number)
        client.post("cards/#{number}/watch")
        puts "Watching card ##{number}."
      end

      desc "unwatch NUMBER", "Unwatch a card"
      def unwatch(number)
        client.delete("cards/#{number}/watch")
        puts "Unwatched card ##{number}."
      end

      desc "golden NUMBER", "Mark a card as golden"
      def golden(number)
        client.post("cards/#{number}/goldness")
        puts "Card ##{number} marked golden."
      end

      desc "ungolden NUMBER", "Remove golden from a card"
      def ungolden(number)
        client.delete("cards/#{number}/goldness")
        puts "Card ##{number} ungolden."
      end

      private

      def format_assignees(assignees)
        return "" unless assignees&.any?

        assignees.map { |a| a["name"] }.join(", ")
      end

      def format_tags(tags)
        return "" unless tags&.any?

        tags.map { |t| t["title"] || t["name"] }.join(", ")
      end

      def format_steps(steps)
        return "" unless steps&.any?

        done = steps.count { |s| s["completed"] }
        "#{done}/#{steps.size}"
      end
    end
  end
end
