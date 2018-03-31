module Leg
  class Page
    attr_accessor :filename, :steps, :footer_text

    def initialize(filename = "tutorial")
      @filename = filename
      @steps = []
      @footer_text = nil
    end

    def <<(step)
      @steps << step
      self
    end

    def empty?
      @steps.empty?
    end

    def title
      first_line = @steps.first ? @steps.first.text.lines.first : (@footer_text ? @footer_text.lines.first : nil)
      if first_line && first_line.start_with?("# ")
        first_line[2..-1].strip
      end
    end
  end
end
