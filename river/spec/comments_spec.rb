require File.join(File.dirname(__FILE__),"spec_helper")

describe "comments" do
  include RiverSpecHelper

  it "same line comment" do
    test_eval "1 #this is a comment", 1
  end

  it "multiline comment and then more code" do
    test_eval <<ENDCODE, 2
      1 # my comment
      2
ENDCODE
  end

end
