# frozen_string_literal: true

module Fizzy
  class ProjectConfig
    FILENAME = ".fizzy.yml"

    attr_reader :path

    def initialize(start_dir = Dir.pwd)
      @path = find_config(start_dir)
      data = @path ? YAML.safe_load_file(@path) : {}
      @data = data.is_a?(Hash) ? data : {}
    rescue Psych::SyntaxError => e
      raise Thor::Error, "Bad .fizzy.yml at #{@path}: #{e.message}"
    end

    def found? = !@path.nil?

    def account = @data["account"]

    def board = @data["board"]

    private

    def find_config(dir)
      candidate = File.join(dir, FILENAME)
      return candidate if File.exist?(candidate)

      parent = File.dirname(dir)
      return nil if parent == dir

      find_config(parent)
    end
  end
end
