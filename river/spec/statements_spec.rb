require File.join(File.dirname(__FILE__),"spec_helper")

describe "statements" do
  include RiverSpecHelper

  it "int constant" do
    test_eval "13", 13
  end

  it "; can be a no-op" do
    test_eval ";", nil
  end

  it "1+1 should equal 2" do
    test_eval "1+1", 2
  end

  it "local assignment" do
    test_eval "a = 60;a*2", 120
  end

  it "logical ||" do
    test_eval "nil || 120", 120
  end

  it "keyword_like vars" do
    test_eval <<ENDCODE, 100
root_var = 20
end_var = 20
while_var = 20
if_var = 20
do_var = 20
root_var + end_var + while_var + if_var + do_var
ENDCODE
  end


  it "logical &&" do
    test_eval "1 && 120", 120
  end

  it "multiple statements separated by newlines or semicolons" do
    test_eval "a = 12; b = 10; a * b", 120
    test_eval <<ENDCODE, 120
      a = 12
      b = 10
      a * b
ENDCODE
  end
end
