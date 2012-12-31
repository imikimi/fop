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
    if res
      res.evaluate
    else
      puts parser.parser_failure_info :verbose => true
    end
  end
end
