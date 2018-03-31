module Leg
  class Tutorial
    attr_accessor :config
    attr_accessor :page_template, :step_template
    attr_reader :pages

    def initialize(config = nil)
      @config = config
      @page_template = Leg::DefaultTemplates::PAGE
      @step_template = Leg::DefaultTemplates::STEP
      @pages = []
    end

    def <<(page)
      @pages << page
      self
    end

    def clear
      @pages.clear
    end

    def step(number)
      cur = 1
      @pages.each do |page|
        page.steps.each do |step|
          return step if cur == number
          cur += 1
        end
      end
    end

    def num_steps
      @pages.map(&:steps).map(&:length).sum
    end

    def transform_diffs(transformers, &progress_block)
      step_num = 1
      @pages.each do |page|
        page.steps.each do |step|
          step.diffs.map! do |diff|
            transformers.inject(diff) do |acc, transformer|
              transformer.transform(acc)
            end
          end
          progress_block.(step_num) if progress_block
          step_num += 1
        end
      end
    end
  end
end
