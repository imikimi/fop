require "babel_bridge"

%w{
  version
  block_model
  model
  parser
  runtime
}.each do |src|
  require File.join(File.dirname(__FILE__),"river",src)
end
