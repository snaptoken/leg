$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "leg"

require "minitest/autorun"
require "minitest/pride"

def leg_command(*args)
  Leg::CLI.new(force_quiet: true).run(args)
end
