module Leg
  module DiffTransformers
    class FoldSections < BaseTransformer
      def transform(diff)
        sections = @options[:section_types].map { [] }

        cur_sections = @options[:section_types].map { nil }
        diff.lines.each.with_index do |line, idx|
          @options[:section_types].each.with_index do |section_type, level|
            if line.source =~ Regexp.new(section_type[:start])
              if !section_type[:end] && cur_sections[level]
                cur_sections[level].end_line = idx - 1
                if @options[:unfold_before_new_section]
                  cur_sections[level].dirty! if [:added, :removed].include? line.type
                end
                sections[level] << cur_sections[level]
              end

              cur_sections[level] = Section.new(level, idx)

              if [:added, :removed].include? line.type
                cur_sections[level].dirty!
              end
            elsif section_type[:end] && line.source =~ Regexp.new(section_type[:end])
              if [:added, :removed].include? line.type
                cur_sections[level].dirty!
              end

              cur_sections[level].end_line = idx
              sections[level] << cur_sections[level]
              cur_sections[level] = nil
            elsif cur_sections[level]
              if [:added, :removed].include? line.type
                cur_sections[level].dirty!
              end
            end
          end
        end
        cur_sections.each.with_index do |section, level|
          unless section.nil?
            section.end_line = diff.lines.length - 1
            sections[level] << section
          end
        end

        new_diff = diff.clone
        sections.each.with_index do |level_sections, level|
          level_sections.each do |section|
            if !section.dirty? && !new_diff.lines[section.to_range].any?(&:nil?)
              start_line = new_diff.lines[section.start_line]
              end_line = new_diff.lines[section.end_line]

              summary_lines = [start_line]
              summary_lines << end_line if @options[:section_types][level][:end]
              summary = summary_lines.map(&:source).join(" … ")

              line_numbers = [start_line.line_number, end_line.line_number]

              folded_line = Leg::Line::Folded.new(:folded, summary, line_numbers)

              section.to_range.each do |idx|
                new_diff.lines[idx] = nil
              end

              new_diff.lines[section.start_line] = folded_line
            end
          end
        end
        new_diff.lines.compact!
        new_diff
      end

      class Section
        attr_accessor :level, :start_line, :end_line, :dirty

        def initialize(level, start_line, end_line = nil, dirty = false)
          @level, @start_line, @end_line, @dirty = level, start_line, end_line, dirty
        end

        def to_range
          start_line..end_line
        end

        def dirty?; @dirty; end
        def dirty!; @dirty = true; end
      end
    end
  end
end
