class Snaptoken::Commands::Fancy < Snaptoken::Commands::BaseCommand
  def self.name
    "fancy"
  end

  def self.summary
    "Run steps.diff through colordiff, diff-so-fancy, and less"
  end

  def run
    needs! :config, :diff

    FileUtils.cd(@config[:path]) do
      exec("cat steps.diff | colordiff | diff-so-fancy | less --tabs=4 -RFX")
    end
  end
end

