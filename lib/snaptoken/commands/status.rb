class Snaptoken::Commands::Status < Snaptoken::Commands::BaseCommand
  def self.name
    "status"
  end

  def self.summary
    "Show whether diff/ and /repo were\n" +
    "last modified since the last sync."
  end

  def self.usage
    ""
  end

  def setopts!(o)
  end

  def run
    needs! :config

    last_synced_at = @tutorial.last_synced_at
    diff_modified_at = @tutorial.diff_modified_at
    repo_modified_at = @tutorial.repo_modified_at

    diff_status = ""
    if last_synced_at && diff_modified_at
      if diff_modified_at > last_synced_at
        diff_status = "[modified]"
      else
        diff_status = "[synced]"
      end
    end

    repo_status = ""
    if last_synced_at && repo_modified_at
      if repo_modified_at > last_synced_at
        repo_status = "[modified]"
      else
        repo_status = "[synced]"
      end
    end

    puts "Last sync: #{last_synced_at || 'n/a'}"
    puts
    puts "diff/ last modified at: #{diff_modified_at || 'n/a'} #{diff_status}"
    puts "repo/ last modified at: #{repo_modified_at || 'n/a'} #{repo_status}"
  end
end
