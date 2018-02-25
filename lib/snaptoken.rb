require 'erb'
require 'fileutils'
require 'optparse'
require 'redcarpet'
require 'rouge'
require "rouge/plugins/redcarpet"
require 'rugged'
require 'yaml'

module Snaptoken
end

require 'snaptoken/cli'
require 'snaptoken/commands'
require 'snaptoken/default_templates'
require 'snaptoken/diff'
require 'snaptoken/diff_line'
require 'snaptoken/markdown'
require 'snaptoken/page'
require 'snaptoken/step'
