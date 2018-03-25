class Snaptoken::Commands::Step < Snaptoken::Commands::BaseCommand
  def self.name
    "step"
  end

  def self.summary
    "Select a step for editing."
  end

  def self.usage
    "<step-number>"
  end

  def setopts!(o)
  end

  def run
    needs! :config, :repo

    step_number = @args.first.to_i

    FileUtils.cd(@git.repo_path) do
      repo = Rugged::Repository.new(".")
      empty_tree = Rugged::Tree.empty(repo)

      walker = Rugged::Walker.new(repo)
      walker.sorting(Rugged::SORT_TOPO | Rugged::SORT_REVERSE)
      walker.push(repo.branches.find { |b| b.name == "master" }.target)

      cur_step = 1
      walker.each do |commit|
        next if commit.message.strip == "-"
        last_commit = commit.parents.first
        diff = (last_commit || empty_tree).diff(commit)
        patches = diff.each_patch.to_a
        next if patches.empty?

        if step_number == cur_step
          `git checkout #{commit.oid}`
          @git.copy_repo_to_step!
          exit
        end

        cur_step += 1
      end

      puts "Error: Step not found."
      exit 1
    end
  end
end
