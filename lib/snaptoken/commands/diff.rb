class Snaptoken::Commands::Diff < Snaptoken::Commands::BaseCommand
  def self.name
    "diff"
  end

  def self.summary
    "Convert repo/ to steps.diff."
  end

  def self.usage
    "[-q]"
  end

  def setopts!(o)
    o.on("-q", "--quiet", "Don't output progress") do |q|
      @opts[:quiet] = q
    end
  end

  def run
    needs! :config, :repo

    FileUtils.cd(@config[:path]) do
      repo = Rugged::Repository.new("repo")
      empty_tree = Rugged::Tree.empty(repo)

      walker = Rugged::Walker.new(repo)
      walker.sorting(Rugged::SORT_TOPO | Rugged::SORT_REVERSE)
      walker.push(repo.branches.find { |b| b.name == "master" }.target)

      output = ""
      filename = "steps.leg"
      walker.each do |commit|
        commit_message = commit.message.strip
        next if commit_message == "-"
        last_commit = commit.parents.first
        diff = (last_commit || empty_tree).diff(commit)
        patches = diff.each_patch.reject { |p| p.delta.new_file[:path] == ".dummyleg" }

        if patches.empty? && commit_message =~ /\A~~~ (.+)\z/
          File.write(filename, output) unless output.empty?

          output = ""
          filename = "#{$1}.leg"
        else
          patch = patches.map(&:to_s).join("\n")
          patch.gsub!(/^ /, "|")

          output << "~~~\n\n" unless output.empty?
          output << commit_message << "\n\n" unless commit_message.empty?
          output << patch << "\n" unless patches.empty?
        end
      end

      File.write(filename, output) unless output.empty?
    end
  end
end

