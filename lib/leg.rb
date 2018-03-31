require 'erb'
require 'fileutils'
require 'open3'
require 'optparse'
require 'redcarpet'
require 'rouge'
require 'rouge/plugins/redcarpet'
require 'rugged'
require 'yaml'

require 'leg/cli'
require 'leg/commands'
require 'leg/default_templates'
require 'leg/diff'
require 'leg/diff_transformers'
require 'leg/line'
require 'leg/markdown'
require 'leg/page'
require 'leg/representations'
require 'leg/step'
require 'leg/template'
require 'leg/tutorial'
require 'leg/version'

module Leg
end
