require File.join(File.dirname(__FILE__),"..","lib","river")

module River
module Runtime
describe Object do

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

end
end
end
