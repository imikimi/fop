bb_dev_path = File.expand_path(File.join(File.dirname(__FILE__),"..","..","..","development","babel_bridge","lib","babel_bridge.rb"))

#require "babel_bridge"
require bb_dev_path
require "json"

%w{
  version
  model
  block_model
  parser
  object
  runtime
}.each do |src|
  require File.join(File.dirname(__FILE__),"river",src)
end
