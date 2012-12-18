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

  it "if then else should work" do
    test_parse("if 1 then 1 end").should==1
    test_parse("if nil then 1 end").should==nil
    test_parse("if nil then 1 else 2 end").should==2
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

  it "if followed by operator" do
    test_parse("if 1 then 2 end + 2").should == 4
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

  it "should work to have multiple statements separated by newlines instead of semis" do
    test_parse(<<ENDCODE).should == 120
      a = 12
      b = 10
      a*b
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

  it "complex test" do
    test_parse(<<ENDCODE).should == 120
      point = new
      in point
        @x = @y = 0
        def x; @x end
        def y; @y end
        def set_x(x); @x=x end
        def set_y(y); @y=y end
        def area; x * y end
      end

      point.set_x(12)
      point.set_y(10)
      point.area
ENDCODE
  end
end
