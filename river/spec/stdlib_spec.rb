require File.join(File.dirname(__FILE__),"spec_helper")

describe "stdlib" do
  include RiverSpecHelper


  it "classes parses" do
    test_eval <<ENDCODE, 120
require "classes"
120
ENDCODE
  end

  it "define class" do
    test_eval <<ENDCODE, 120
require "classes"
class :Foo, do
  def bar
    120
  end
end
Classes.Foo.new.bar
ENDCODE
  end

end
