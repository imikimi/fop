#!/usr/bin/env ruby
require File.expand_path(File.join(File.dirname(__FILE__),"../lib/river.rb"))

runtime = River::Runtime::Stack.new
BabelBridge::Shell.new(River::Parser.new(:source_file => "iriver")).start do |root,shell|
  begin
    shell.puts_result root.to_model.evaluate(runtime)
  rescue River::Runtime::Error => e
  end
end
