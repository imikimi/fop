require File.join(File.dirname(__FILE__),"spec_helper")

describe "statements" do
  include RiverSpecHelper

  it "int constant" do
    River::Parser.new.parse("13").evaluate.should==13
  end

  it "; can be a no-op" do
    River::Parser.new.parse(";").evaluate.should==nil
  end

  it "1+1 should equal 2" do
    River::Parser.new.parse("1+1").evaluate.should==2
  end

  it "local assignment" do
    test_parse("a = 60;a*2").should == 120
  end

  it "multiple statements separated by newlines or semicolons" do
    test_parse("a = 12; b = 10; a * b").should == 120
    test_parse(<<ENDCODE).should == 120
      a = 12
      b = 10
      a * b
ENDCODE
  end
end

describe "basic-blocks" do
  include RiverSpecHelper

  it "if" do
    test_parse("if 1; 1 end").should==1
    test_parse("if nil; 1 end").should==nil
  end

  it "if-else (one-line)" do
    test_parse("if 1; 1 else 2 end").should==1
    test_parse("if nil; 1 else 2 end").should==2
  end

  it "if-else (multiline)" do
    test_parse(<<ENDCODE).should == 2
      if nil
        1
      else
        2
      end
ENDCODE
  end

  it "while" do
    test_parse("while nil; 1 end").should==nil
    test_parse("count=0;while count<10; count=count+1 end;count").should==10
  end
end


describe "methods" do
  include RiverSpecHelper

  it "def" do
    (!!test_parse("def double(x); x*2 end")).should==true
  end

  it "def with no parameters" do
    test_parse("def two; 2 end;two").should==2
    test_parse("def two() 2 end;two").should==2
    test_parse("def two(); 2 end;two").should==2
  end

  it "def with parameters" do
    test_parse("def sq(x) x*x end;sq(2)").should==4
    test_parse("def mulsq(x,y) x*y*y end;mulsq(2,3)").should==18
    test_parse("def mulsq(x,y); x*y*y end;mulsq(2,3)").should==18
  end

  it "def with parameters - omitted parens" do
    test_parse("def mulsq(x,y) x*y*y end;mulsq\n2,3").should==18
  end

  it "def func should have local scope for its variables" do
    test_parse("t=2;def doit(t); t*3 end;t*doit(5)*t").should==60
    test_parse("t=2;def doit(x); t=3;t*x end;t*doit(5)*t").should==60
  end

  it "on self" do
    test_parse("def foo; 123 end;self.foo").should == 123
  end

  it "assignment methods" do
    test_parse(<<ENDCODE).should == 120
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
    test_parse("@t").should == nil
  end

  it "member get/set" do
    test_parse("@t=5;@t*2").should == 10
  end
end

describe "basic OO features" do
  include RiverSpecHelper
  it "self" do
    test_parse("self").class.should == River::Runtime::Object
  end

  it "root" do
    test_parse("root").class.should == River::Runtime::Object
  end

  it "create new objects" do
    test_parse("new").class.should == River::Runtime::Object
  end
end

describe "in-block" do
  include RiverSpecHelper

  it "should work to get the root object" do
    test_parse(<<ENDCODE).should == 120
      @foo = 120
      in root
        @foo
      end
ENDCODE
  end

  it "should work to execute in a context" do
    test_parse("obj=new;in obj; def foo; 123 end end;obj.foo").should==123
  end

  it "'in' does not define a new scope" do
    test_parse(<<ENDCODE).should == 120
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
    test_parse(<<ENDCODE).should == 120
      @my_block = do
        120
      end
      @my_block.call
ENDCODE
  end

  it "test do-block with params" do
    test_parse(<<ENDCODE).should == 120
      @my_block = do |x,y|
        x*10 + y
      end
      @my_block.call 10, 20
ENDCODE
  end

  it "test closure" do
    test_parse(<<ENDCODE).should == 120
      y = 20
      @my_block = do |x|
        x*10 + y
      end
      @my_block.call 10
ENDCODE
  end
end
