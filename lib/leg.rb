require 'erb'
require 'fileutils'
require 'optparse'
require 'redcarpet'
require 'rouge'
require 'rouge/plugins/redcarpet'
require 'rugged'
require 'yaml'

module Leg
end

require 'leg/cli'
require 'leg/commands'
require 'leg/default_templates'
require 'leg/diff'
require 'leg/diff_line'
require 'leg/diff_transformers'
require 'leg/markdown'
require 'leg/page'
require 'leg/representations'
require 'leg/step'
require 'leg/template'
require 'leg/tutorial'
