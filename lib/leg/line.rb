module Leg
  class Line
    attr_accessor :source, :hl_source, :line_numbers

    def initialize(source, line_numbers)
      @source = source.chomp
      @line_numbers = line_numbers
    end

    def clone
      line = self.class.new(@source.dup, @line_numbers.dup)
      line.hl_source = @hl_source.dup
      line
    end

    def blank?
      @source.strip.empty?
    end

    def line_number
      raise NotImplementedError
    end

    def to_patch(options = {})
      raise NotImplementedError
    end

    class Added < Line
      def type
        :added
      end

      def line_number
        @line_numbers[1]
      end

      def to_patch(options = {})
        "+#{@source}\n"
      end
    end

    class Removed < Line
      def type
        :removed
      end

      def line_number
        @line_numbers[0]
      end

      def to_patch(options = {})
        "-#{@source}\n"
      end
    end

    class Unchanged < Line
      def type
        :unchanged
      end

      def line_number
        @line_numbers[1]
      end

      def to_patch(options = {})
        char = options[:unchanged_char] || " "
        "#{char}#{@source}\n"
      end
    end

    class Folded < Line
      def type
        :folded
      end

      def line_number
        @line_numbers[0]
      end

      def to_patch(options = {})
        raise "can't convert folded line to patch"
      end
    end
  end
end
