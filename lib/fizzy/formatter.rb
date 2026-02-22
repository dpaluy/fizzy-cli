# frozen_string_literal: true

module Fizzy
  class Formatter
    def self.table(rows, headers:, io: $stdout)
      return if rows.empty?

      all_rows = [headers] + rows
      widths = headers.each_index.map do |i|
        all_rows.map { |r| r[i].to_s.length }.max
      end

      io.puts headers.each_with_index.map { |h, i| h.to_s.ljust(widths[i]) }.join("  ")
      io.puts widths.map { |w| "-" * w }.join("  ")
      rows.each do |row|
        io.puts row.each_with_index.map { |c, i| c.to_s.ljust(widths[i]) }.join("  ")
      end
    end

    def self.json(data, io: $stdout)
      io.puts JSON.pretty_generate(data)
    end

    def self.detail(pairs, io: $stdout)
      width = pairs.map { |k, _| k.to_s.length }.max
      pairs.each do |key, value|
        io.puts "#{key.to_s.rjust(width)}  #{value}"
      end
    end

    def self.truncate(str, max)
      return "" unless str

      str.length > max ? "#{str[0...(max - 1)]}…" : str
    end
  end
end
