require File.join(File.dirname(__FILE__),"..","lib","river")

describe River::Parser do

  before :each do
    @parser = nil
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

  it "1+1 should equal 2" do
    River::Parser.new.parse("1+1").evaluate.should==2
  end

  it "if else should work" do
    test_parse("if 1; 1 end").should==1
    test_parse("if nil; 1 end").should==nil
    test_parse("if 1; 1 else 2 end").should==1
    test_parse("if nil; 1 else 2 end").should==2
  end

  it "if else should work" do
    test_parse(<<ENDCODE).should == 120
      if @tail
        @tail = 1
      else
        @tail = 2
      end
      60 * @tail
ENDCODE
  end

  it "while should work" do
    test_parse("while nil; 1 end").should==nil
    test_parse("count=0;while count<10; count=count+1 end;count").should==10
  end

  it "def func" do
    (!!test_parse("def double(x); x*2 end")).should==true
  end

  it "def func should work with no parameters" do
    test_parse("def two; 2 end;two").should==2
  end

  it "def func should work with two parameters" do
    test_parse("def mulsq(x,y); x*y*y end;mulsq(2,3)").should==18
  end

  it "def func should have local scope for its variables" do
    test_parse("t=2;def doit(t); t*3 end;t*doit(5)*t").should==60
    test_parse("t=2;def doit(x); t=3;t*x end;t*doit(5)*t").should==60
  end

  it "member set and get shoudl work" do
    test_parse("@t=5;@t*2").should == 10
  end

  it "self should work" do
    test_parse("self")
  end

  it "if returns a value" do
    test_parse("if 1; 2 end + 2").should == 4
    test_parse("if nil; 2; else 3 end + 2").should == 5
  end

  it "'root' should work" do
    test_parse("root").class.should == River::Runtime::Object
  end

  it "basic method invocation" do
    test_parse("def foo; 123 end;foo;self.foo").should == 123
  end

  it "should work to create new objects" do
    test_parse("new").class.should == River::Runtime::Object
  end

  it "should work to execute in a context" do
    test_parse("obj=new;in obj; def foo; 123 end end;obj.foo").should==123
    test_parse("obj=new;in obj; def foo; 123 end end;obj.foo").should==123
  end

  it "should work to have multiple statements separated by newlines or semicolons" do
    test_parse("a = 12; b = 10; a * b").should == 120
    test_parse(<<ENDCODE).should == 120
      a = 12
      b = 10
      a * b
ENDCODE
  end

  it "should work to get the root object" do
    test_parse(<<ENDCODE).should == 120
      @foo = 120
      in root
        @foo
      end
ENDCODE
  end

  it "'in' does not define a new scope" do
    test_parse(<<ENDCODE).should == 120
      foo = 120
      in root
        foo
      end
ENDCODE
  end

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
