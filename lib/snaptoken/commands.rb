module Snaptoken::Commands
  LIST = []
end

require 'snaptoken/commands/base_command'

require 'snaptoken/commands/build'
require 'snaptoken/commands/status'
require 'snaptoken/commands/commit'
require 'snaptoken/commands/amend'
require 'snaptoken/commands/resolve'
require 'snaptoken/commands/step'
require 'snaptoken/commands/help'
