#!/usr/bin/env ruby
require File.expand_path(File.join(File.dirname(__FILE__),"../lib/river.rb"))

src = File.read ARGV[0]
parser = River::Parser.new
parsed = parser.parse src
puts parsed.to_model.to_code
