bb_dev_path = File.expand_path(File.join(File.dirname(__FILE__),"..","..","..","development","babel_bridge","lib","babel_bridge.rb"))
puts "#{bb_dev_path} exists? #{File.exists? bb_dev_path}"
if File.exists?(bb_dev_path)
  puts "Using development version of Babel-Bridge: #{bb_dev_path}"
  require bb_dev_path
else
  require "babel_bridge"
end
puts "Babel-Bridge Version: #{BabelBridge::VERSION}"

require "json"

%w{
  version
  model
  block_model
  parser
  runtime
}.each do |src|
  require File.join(File.dirname(__FILE__),"river",src)
end
