$:.unshift(File.join(File.expand_path(File.dirname(__FILE__)), "..", "..", "lib"))
$:.unshift(File.join(File.expand_path(File.dirname(__FILE__))))

require 'rubygems'
require 'test/unit'
require 'activesupport'
require 'active_support/test_case'
require 'test_base'

require 'mocha'
gem 'thoughtbot-shoulda'
require 'shoulda'
