require File.join(File.dirname(__FILE__),"spec_helper")

describe "basic-blocks" do
  include RiverSpecHelper

  it "if" do
    test_eval("if 1; 1 end").should==1
    test_eval("if nil; 1 end").should==nil
  end

  it "if-else (one-line)" do
    test_eval("if 1; 1 else 2 end").should==1
    test_eval("if nil; 1 else 2 end").should==2
  end

  it "if-else (multiline)" do
    test_eval(<<ENDCODE).should == 2
      if nil
        1
      else
        2
      end
ENDCODE
  end

  it "while" do
    test_eval("while nil; 1 end").should==nil
    test_eval("count=0;while count<10; count=count+1 end;count").should==10
  end
end


describe "methods" do
  include RiverSpecHelper

  it "def" do
    (!!test_eval("def double(x); x*2 end")).should==true
  end

  it "def with no parameters" do
    test_eval("def two; 2 end;two").should==2
    test_eval("def two() 2 end;two").should==2
    test_eval("def two(); 2 end;two").should==2
  end

  it "def with parameters" do
    test_eval("def sq(x) x*x end;sq(2)").should==4
    test_eval("def mulsq(x,y) x*y*y end;mulsq(2,3)").should==18
    test_eval("def mulsq(x,y); x*y*y end;mulsq(2,3)").should==18
  end

  it "def with parameters - omitted parens" do
    test_eval("def mulsq(x,y) x*y*y end;mulsq 2,3").should==18
  end

  it "def func should have local scope for its variables" do
    test_eval("t=2;def doit(t); t*3 end;t*doit(5)*t").should==60
    test_eval("t=2;def doit(x); t=3;t*x end;t*doit(5)*t").should==60
  end

  it "on self" do
    test_eval("def foo; 123 end;self.foo").should == 123
  end

  it "assignment methods" do
    test_eval(<<ENDCODE).should == 120
      def x=(x)
        @x=x
      end

      def x
        @x
      end

      self.x = 120
      self.x
ENDCODE
  end
end

describe "members" do
  include RiverSpecHelper
  it "new members default to nil" do
    test_eval("@t").should == nil
  end

  it "member get/set" do
    test_eval("@t=5;@t*2").should == 10
  end
end

describe "basic OO features" do
  include RiverSpecHelper
  it "self" do
    test_eval("self").class.should == River::Runtime::Object
  end

  it "root" do
    test_eval("root").class.should == River::Runtime::Object
  end

  it "create new objects" do
    test_eval("new").class.should == River::Runtime::Object
  end
end

describe "in-block" do
  include RiverSpecHelper

  it "should work to get the root object" do
    test_eval(<<ENDCODE).should == 120
      @foo = 120
      in root
        @foo
      end
ENDCODE
  end

  it "should work to execute in a context" do
    test_eval("obj=new;in obj; def foo; 123 end end;obj.foo").should==123
  end

  it "'in' does not define a new scope" do
    test_eval(<<ENDCODE).should == 120
      foo = 120
      in root
        foo
      end
ENDCODE
  end
end

describe "do-blocks" do
  include RiverSpecHelper

  it "test basic do-block" do
    test_eval(<<ENDCODE).should == 120
      @my_block = do
        120
      end
      @my_block.call
ENDCODE
  end

  it "test do-block with params" do
    test_eval(<<ENDCODE).should == 120
      @my_block = do |x,y|
        x*10 + y
      end
      @my_block.call 10, 20
ENDCODE
  end

  it "test closure" do
    test_eval(<<ENDCODE).should == 120
      y = 20
      @my_block = do |x|
        x*10 + y
      end
      @my_block.call 10
ENDCODE
  end
end
