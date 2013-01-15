require File.join(File.dirname(__FILE__),"spec_helper")

module River
module Runtime
describe Object do
  include RiverSpecHelper

  it "should be creatable" do
    Object.new.class.should == Object
  end

  it "should be able to have a parent" do
    o1 = Object.new
    o2 = Object.new(o1)
    o2.parent.should==o1
  end

  it "should work with ancestor" do
    o1 = Object.new
    o2 = Object.new(o1)
    o3 = Object.new(o1)
    o2.ancestor?(o1).should == true
    o2.ancestor?(o3).should == false
  end

  it "should work block circular parentage" do
    o1 = Object.new
    o2 = Object.new(o1)
    lambda {o1.parent = o2}.should raise_error
  end


  it "should work to eval on the root object" do
    test_eval(<<ENDCODE).should == 120
      @foo = 120
      root.eval do
        @foo
      end
ENDCODE
  end

  it "should work to eval on a non-root object" do
    test_eval(<<ENDCODE).should==123
obj=new
obj.eval do
  def foo; 123 end
end
def foo; 999 end
obj.foo
ENDCODE
  end

  it "set_method should work" do
    test_eval(<<ENDCODE).should == 120
      @foo = 120
      root.set_method :bar, do
        @foo
      end
      root.bar
ENDCODE
  end

  it "get_method should work" do
    test_eval(<<ENDCODE).should == 120
      root.eval do
        def foo
          120
        end
      end
      root.get_method(:foo).call
ENDCODE
  end

  it "set_member should work" do
    test_eval(<<ENDCODE).should == 120
      root.set_member :foo, 120
      @foo
ENDCODE
  end

  it "get_member should work" do
    test_eval(<<ENDCODE).should == 120
      @foo = 120
      root.get_member :foo
ENDCODE
  end

  it "symbol should work" do
    test_eval(":symbol").ruby_object.should == :symbol
  end

  it "string should work" do
    test_eval('"string"').ruby_object.should == "string"
  end

end
end
end
