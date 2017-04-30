class Snaptoken::Commands::Deploy < Snaptoken::Commands::BaseCommand
  def self.name
    "deploy"
  end

  def self.summary
    "Push output files in doc/html_out/ to\n" +
    "production server (requires ftp.yml)."
  end

  def self.usage
    "[pattern...]"
  end

  def setopts!(o)
  end

  def run
    needs! :config, :doc, :doc_out, :ftp

    only = @args.empty? ? nil : @args

    FileUtils.cd(File.join(@config[:path], "doc/html_out")) do
      ftp_config = YAML.load(File.read(File.join(@config[:path], "ftp.yml")))
      Net::FTP.open(ftp_config[:host], ftp_config[:username], ftp_config[:password]) do |ftp|
        ftp.chdir(ftp_config[:root])
        Dir["**/*"].each do |f|
          if only.nil? || only.any? { |o| f[o] }
            puts f
            if File.directory?(f)
              ftp.mkdir(f) rescue Net::FTPPermError
            elsif File.file?(f)
              ftp.putbinaryfile(f, f)
            end
          end
        end
      end
    end
  end
end

