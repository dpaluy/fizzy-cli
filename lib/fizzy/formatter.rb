# frozen_string_literal: true

module Fizzy
  class Formatter
    def self.table(rows, headers:, io: $stdout)
      return if rows.empty?

      all_rows = [headers] + rows
      widths = headers.each_index.map do |i|
        all_rows.map { |r| display_width(r[i].to_s) }.max
      end

      io.puts headers.each_with_index.map { |h, i| display_ljust(h.to_s, widths[i]) }.join("  ")
      io.puts widths.map { |w| "-" * w }.join("  ")
      rows.each do |row|
        io.puts row.each_with_index.map { |c, i| display_ljust(c.to_s, widths[i]) }.join("  ")
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

    def self.display_width(str)
      str = str.to_s
      str.each_char.sum { |c| wide_char?(c) ? 2 : 1 }
    end

    def self.display_ljust(str, width)
      str = str.to_s
      padding = width - display_width(str)
      padding.positive? ? "#{str}#{" " * padding}" : str
    end

    WIDE_RANGES = [
      0x1100..0x115F, 0x2E80..0xA4CF, 0xAC00..0xD7AF, 0xF900..0xFAFF,
      0xFE10..0xFE6F, 0xFF00..0xFF60, 0x1F000..0x1FFFF, 0x20000..0x2FA1F
    ].freeze

    def self.wide_char?(char)
      WIDE_RANGES.any? { |r| r.cover?(char.ord) }
    end

    private_class_method :display_width, :display_ljust, :wide_char?
  end
end
