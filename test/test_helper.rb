$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "leg"

require "minitest/autorun"
require "minitest/pride"

def leg_command(*args)
  Leg::CLI.new.run(args)
end
