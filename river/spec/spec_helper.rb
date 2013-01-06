require File.join(File.dirname(__FILE__),"..","lib","river")

module RiverSpecHelper
  def self.included(mod)
    mod.class_eval do
      before :each do
        @parser = nil
      end
    end
  end

  def parser
    @parser ||= River::Parser.new
  end

  def test_parse(program)
    res = parser.parse(program)
    res || begin
      puts parser.parser_failure_info :verbose => true
      raise "parser failure"
    end
  end

  def test_eval(program,equal_to=nil)
    test_parse(program).evaluate.tap do |res|
      equal_to.should == res if equal_to
    end
  end
end
