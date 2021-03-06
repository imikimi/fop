require File.join(File.dirname(__FILE__),"spec_helper")

describe River::Parser do

  include RiverSpecHelper

  it "test passing blocks in as parameters" do
    test_eval(<<ENDCODE).should == 120
      def run_twice_and_sum(block)
        block.call + block.call
      end

      run_twice_and_sum do
        60
      end
ENDCODE
  end

  it "test passing two blocks in as parameters" do
    test_eval(<<ENDCODE).should == 120
      def run_and_sum(block1, block2)
        block1.call + block2.call
      end

      run_and_sum do
        10*4
      end, do
        160/2
      end
ENDCODE
  end

  it "complex test" do
    test_eval(<<ENDCODE).should == 120
      point = derive
      point.eval do
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

  it "linked list test" do
    code = (<<ENDCODE)
      @linked_list = derive
      @linked_list_node = derive

      root.eval do
        def linked_list; @linked_list; end
        def linked_list_node; @linked_list_node; end
      end

      @linked_list_node.eval do
        def next; @next end
        def value; @value end
        def set_next(n); @next = n end
        def set_value(v); @value = v end
      end

      @linked_list.eval do
        def head; @head end
        def tail; @tail end

        def add(value)
          if @tail
            @tail = @tail.set_next root.linked_list_node.derive
          else
            @head = @tail = root.linked_list_node.derive
          end
          @tail.set_value value
        end

        def each(block)
          current = @head
          while current
            block.call current.value
            current = current.next
          end
          self
        end
      end

      my_ll = root.linked_list.derive
      my_ll.add 2
      my_ll.add 5
      my_ll.add 12

      product = 1
      my_ll.each do |el|
        product = product * el
      end
      product
ENDCODE
    #puts parser.parse(code).to_model.to_code
    test_eval(code).should == 120
  end
end
