module River
module Runtime

class Object
  attr_reader :parent, :mmethods, :mmembers

  class << self
    def new_root_object
      Object.new.tap do |o|
        o.set_method :new, lambda {|runtime,context,params| Runtime::Object.new(context)}
      end
    end
  end

  def initialize(_parent = nil)
    self.parent=_parent
  end

  def ancestor?(k)
    k && (k==parent ? true : (parent && parent.ancestor?(k))) || false
  end

  def parent=(k)
    if k==self
      raise "cannot self-parent"
    elsif k && k.ancestor?(self)
      raise "k (#{k.inspect}) is an anscestor of self - circular parentage"
    else
      @parent=k
    end
  end

  def mmethods; @methods||={}; end
  def mmembers; @members||={}; end

  def set_method(method_name, function_def)
    mmethods[method_name] = function_def
  end

  # return which object is the parent of self
  def where_method(method_name)
    mmethods[method_name] ? self :
    (parent && parent!=self && parent.find_method(method_name))
  end

  def find_method(method_name)
    mmethods[method_name] ||
    (parent && parent!=self && parent.find_method(method_name))
  end

  def inspect
    "<#{self.class}:#{self.object_id}>"
  end

  def invoke(runtime, method_name, params)
    method = find_method method_name
    if method
      method.call runtime, self, params
    else
      raise "method #{method_name.inspect} not found on object #{inspect} methods=#{mmethods.keys.inspect}"
    end
  end
end

class Stack
  def top_stack_frame
    @top_stack_frame ||= {
      :"@context" => @root = Object.new_root_object
    }
  end

  attr_reader :root

  # the stack consists of an array of hashs
  # Each entry in the stack is a call-frame with a hash of local variable names
  def stack; @stack ||= [top_stack_frame]; end

  def context; current_stack_frame[:"@context"]; end

  def current_stack_frame; stack[-1]; end

  def push_new_stack_frame(locals={})
    stack << locals
  end

  def pop_stack_frame
    stack.pop
  end
end
end
end
