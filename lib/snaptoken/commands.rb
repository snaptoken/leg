module Snaptoken::Commands
  LIST = []
end

require 'snaptoken/commands/base_command'

require 'snaptoken/commands/doc'
require 'snaptoken/commands/sync'
require 'snaptoken/commands/diff'
require 'snaptoken/commands/repo'
require 'snaptoken/commands/status'
require 'snaptoken/commands/ref'
require 'snaptoken/commands/help'
