class Snaptoken::Step
  attr_accessor :number, :name, :data

  def initialize(number, name, data)
    @number, @name, @data = number, name, data
  end

  def folder_name
    name = "#{@number}"
    name << "-#{@name}" if @name
    name << "+#{@data.join('+')}" if @data.length > 0
    name
  end

  def commit_msg
    if @data.empty?
      @name
    else
      "#{@name} #{@data.join(' ')}"
    end
  end

  def self.from_folder_name(folder)
    if folder =~ /\A(\d+)-([\w-]+)(\+([\+\w-]*))?\z/
      Snaptoken::Step.new($1.to_i, $2, $4.to_s.split('+'))
    end
  end

  def self.from_commit_msg(number, msg)
    if msg =~ /\A([\w-]+)(\s([\s\w-]*))?\z/
      Snaptoken::Step.new(number, $1, $2.to_s.split)
    end
  end
end

