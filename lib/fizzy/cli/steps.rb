# frozen_string_literal: true

module Fizzy
  class CLI < Thor
    class Steps < Thor
      include Base

      desc "get STEP_ID", "Show a step"
      option :card, required: true, type: :numeric, desc: "Card number"
      def get(step_id)
        resp = client.get("cards/#{options[:card]}/steps/#{step_id}")
        s = resp.body
        output_detail(s, pairs: [
                        ["ID", s["id"]],
                        ["Description", s["description"]],
                        ["Completed", s["completed"]],
                        ["Position", s["position"]]
                      ])
      end

      desc "create DESCRIPTION", "Add a step to a card"
      option :card, required: true, type: :numeric, desc: "Card number"
      def create(description)
        resp = client.post("cards/#{options[:card]}/steps", body: { description: description })
        s = resp.body
        output_detail(s, pairs: [
                        ["ID", s["id"]],
                        ["Description", s["description"]]
                      ])
      end

      desc "update STEP_ID", "Update a step"
      option :card, required: true, type: :numeric, desc: "Card number"
      option :description, desc: "New description"
      option :completed, type: :boolean, desc: "Mark completed"
      def update(step_id)
        path = "cards/#{options[:card]}/steps/#{step_id}"
        resp = client.put(path, body: build_body(:description, :completed))
        s = resp.body
        output_detail(s, pairs: [
                        ["ID", s["id"]],
                        ["Description", s["description"]],
                        ["Completed", s["completed"]]
                      ])
      end

      desc "delete STEP_ID", "Delete a step"
      option :card, required: true, type: :numeric, desc: "Card number"
      def delete(step_id)
        client.delete("cards/#{options[:card]}/steps/#{step_id}")
        puts "Step #{step_id} deleted."
      end
    end
  end
end
