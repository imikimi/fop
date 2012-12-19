#!/usr/bin/env ruby
require File.expand_path(File.join(File.dirname(__FILE__),"../lib/river.rb"))

runtime = River::Runtime::Stack.new
BabelBridge::Shell.new(River::Parser.new).start do |root,shell|
  shell.puts_result root.to_model.evaluate(runtime)
end
