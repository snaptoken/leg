class Snaptoken::Commands::Ref < Snaptoken::Commands::BaseCommand
  def self.name
    "ref"
  end

  def self.summary
    "Get the commit hash in repo/ for a step\n" +
    "name or step number. `leg <step-number>`\n" +
    "can be used as a shortcut for\n" +
    "`leg ref <step-number>`."
  end

  def self.usage
    "[<step-name> | <step-number>]"
  end

  def setopts!(o)
  end

  def run
    needs! :config, :repo

    ref = @args.first
    is_num = (ref =~ /\A\d+\z/)

    FileUtils.cd(@config[:path]) do
      repo = Rugged::Repository.new("repo")
      empty_tree = Rugged::Tree.empty(repo)

      walker = Rugged::Walker.new(repo)
      walker.sorting(Rugged::SORT_TOPO | Rugged::SORT_REVERSE)
      walker.push(repo.branches.find { |b| b.name == "master" }.target)

      step_num = 1
      walker.each do |commit|
        commit_message = commit.message.strip
        summary = commit_message.lines.first.strip
        step_name = summary.split(' ').first # temporarararary
        last_commit = commit.parents.first
        diff = (last_commit || empty_tree).diff(commit)
        patches = diff.each_patch.reject { |p| p.delta.new_file[:path] == ".dummyleg" }
        next if patches.empty?

        if (is_num && ref.to_i == step_num) || (!is_num && ref == step_name)
          puts commit.oid
          exit
        end

        step_num += 1
      end

      puts "Error: reference not found"
      exit!
    end
  end
end

