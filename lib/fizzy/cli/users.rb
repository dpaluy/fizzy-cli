# frozen_string_literal: true

module Fizzy
  class CLI < Thor
    class Users < Thor
      include Base

      desc "list", "List users"
      def list
        data = paginator.all("#{slug}/users")
        output_list(data, headers: %w[ID Name Email Role Active]) do |u|
          [u["id"], u["name"], u["email_address"], u["role"], u["active"]]
        end
      end

      desc "get USER_ID", "Show a user"
      def get(user_id)
        resp = client.get("#{slug}/users/#{user_id}")
        u = resp.body
        output_detail(u, pairs: [
                        ["ID", u["id"]],
                        ["Name", u["name"]],
                        ["Email", u["email_address"]],
                        ["Role", u["role"]],
                        ["Active", u["active"]],
                        ["Created", u["created_at"]]
                      ])
      end

      desc "update USER_ID", "Update a user"
      option :name, desc: "New name"
      option :role, desc: "New role"
      def update(user_id)
        resp = client.put("#{slug}/users/#{user_id}", body: build_body(:name, :role))
        u = resp.body
        output_detail(u, pairs: [
                        ["ID", u["id"]],
                        ["Name", u["name"]],
                        ["Role", u["role"]]
                      ])
      end

      desc "deactivate USER_ID", "Deactivate a user"
      def deactivate(user_id)
        client.delete("#{slug}/users/#{user_id}")
        puts "User #{user_id} deactivated."
      end
    end
  end
end
