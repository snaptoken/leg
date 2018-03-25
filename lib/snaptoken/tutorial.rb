class Snaptoken::Tutorial
  attr_accessor :config
  attr_accessor :page_template, :step_template
  attr_reader :pages

  def initialize(config = {})
    @config = config
    @page_template = Snaptoken::DefaultTemplates::PAGE
    @step_template = Snaptoken::DefaultTemplates::STEP
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

  def last_synced_at
    File.mtime(last_synced_path) if File.exist?(last_synced_path)
  end

  def synced!
    FileUtils.touch(last_synced_path)
  end

  private

  def last_synced_path
    File.join(@config[:path], ".leg/last_synced")
  end
end
