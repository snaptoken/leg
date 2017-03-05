class Leg::Commands::Edit < Leg::Commands::BaseCommand
  def self.name
    "edit"
  end

  def self.summary
    "Open a file in a text editor"
  end

  def run
    needs! :config
    needs! :config_editor

    step = current_or_latest_step

    files = Dir[File.join(step_path(step), "**/*")].reject { |f| File.directory? f }
    if files.length == 0
      puts "Error: No files to edit."
      exit!
    elsif files.length == 1
      file_path = files[0]
    elsif @config[:default_file]
      file_path = @config[:default_file]
    else
      puts "Error: You'll need to choose a file to edit."
      exit!
    end

    select_step(step) do
      shell_command("#{@config[:editor]}", file_path, exec: true)
    end
  end
end

