require File.join(File.dirname(__FILE__),"spec_helper")

describe "to_code" do
  include RiverSpecHelper

  it "optional parenthesis" do
    [
      "func1 func2(1, 2)",
      "func1 1, 2",
      <<ENDCODE
func1 do
  func2 1, 2
end
ENDCODE
    ].each do |code|
      test_parse(code).to_model.to_code.should == code.strip
    end
  end

end
