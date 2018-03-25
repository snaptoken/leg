class Snaptoken::Commands::Status < Snaptoken::Commands::BaseCommand
  def self.name
    "status"
  end

  def self.summary
    "Show whether doc/ and repo/ were\n" +
    "last modified since the last sync."
  end

  def self.usage
    ""
  end

  def setopts!(o)
  end

  def run
    needs! :config
  end
end
