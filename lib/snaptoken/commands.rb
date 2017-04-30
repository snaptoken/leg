module Snaptoken::Commands
  LIST = []
end

require 'snaptoken/commands/base_command'

require 'snaptoken/commands/doc'
require 'snaptoken/commands/fancy'
require 'snaptoken/commands/diff'
require 'snaptoken/commands/repo'
require 'snaptoken/commands/undiff'
require 'snaptoken/commands/unrepo'
require 'snaptoken/commands/ref'
require 'snaptoken/commands/deploy'
require 'snaptoken/commands/help'

