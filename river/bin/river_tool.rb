#!/usr/bin/env ruby
require File.expand_path(File.join(File.dirname(__FILE__),"../lib/river.rb"))
require "trollop"

def river(args)
  options = Trollop::options(args) do
    opt :transcode, "Output the text source-model"
    opt :json, "Output the json source-model"
  end

  files = args

  parser = River::Parser.new
  runtime = River::Runtime::Stack.new


  files.each do |file|
    src = File.read file
    parsed = parser.parse src

    model = parsed.to_model

    if options[:transcode]
      puts model.to_s
    elsif options[:json]
      puts JSON.pretty_generate(model.to_hash)
    else
      model.evaluate runtime
    end

  end

end

river(ARGV)
