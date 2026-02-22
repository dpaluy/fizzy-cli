# frozen_string_literal: true

module Fizzy
  class CLI < Thor
    class Notifications < Thor
      include Base

      desc "list", "List notifications"
      def list
        data = paginator.all("#{slug}/notifications")
        output_list(data, headers: %w[ID Type Card Read Created]) do |n|
          [
            n["id"],
            n["event_type"],
            n.dig("card", "title") || "",
            n["read_at"] ? "yes" : "no",
            n["created_at"]
          ]
        end
      end

      desc "read ID", "Mark notification as read"
      def read(id)
        client.post("#{slug}/notifications/#{id}/reading")
        puts "Notification #{id} marked read."
      end

      desc "unread ID", "Mark notification as unread"
      def unread(id)
        client.delete("#{slug}/notifications/#{id}/reading")
        puts "Notification #{id} marked unread."
      end

      desc "mark-all-read", "Mark all notifications as read"
      map "mark-all-read" => :mark_all_read
      def mark_all_read
        client.post("#{slug}/notifications/bulk_reading")
        puts "All notifications marked read."
      end
    end
  end
end
