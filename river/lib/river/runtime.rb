module River
module Runtime

class Object
  attr_reader :parent, :mmethods, :mmembers

  class << self
    def new_root_object
      Object.new.tap do |o|
        o.set_method :new, lambda {|runtime,context,params| context.new}
        o.set_method :debug, lambda {|runtime,context,params| puts params.collect{|a| a.inspect}.join(', ')} # temporary implementation for debugging
      end
    end
  end

  def initialize(_parent = nil)
    self.parent=_parent
  end

  def new
    Runtime::Object.new self
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

  def invoke(runtime, method_name, params, invoking_model)
    method = find_method method_name
    if method
      method.call runtime, self, params
    else
      raise "method #{method_name.inspect} not found on object #{inspect} methods=#{mmethods.keys.inspect} (line #{invoking_model.source_line}, column #{invoking_model.source_column})"
    end
  end
end

class StackFrame
  attr_accessor :parent
  attr_accessor :locals
  attr_accessor :context

  # options: :context, :locals, :parent
  def initialize(options={})
    @context = options[:context] || Object.new_root_object
    @locals = Hash.new options[:locals]
    @parent = options[:parent]
  end

  def context
    @context || (parent && parent.context)
  end

  def has_local?(name)
    locals.has_key?(name) || (parent && parent.has_local?(name))
  end

  def [](name)
    (locals.has_key?(name) && locals[name]) ||
    parent && parent[name]
  end

  def []=(name,value)
    if parent && parent.has_local?(name)
      parent[name] = value
    else
      locals[name] = value
    end
  end
end

class Stack
  def top_stack_frame
    @top_stack_frame ||= StackFrame.new
  end

  attr_reader :root

  def initialize
    @root = top_stack_frame.context
  end

  # the stack consists of an array of hashs
  # Each entry in the stack is a call-frame with a hash of local variable names
  def stack; @stack ||= [top_stack_frame]; end

  def context; current_stack_frame.context; end

  def current_stack_frame; stack[-1]; end

  def push_stack_frame(stack_frame)
    stack << stack_frame
  end

  def pop_stack_frame
    stack.pop
  end

  def in(stack_frame)
    push_stack_frame(stack_frame)
    yield
  ensure
    pop_stack_frame
  end

  def in_context(new_context)
    old_context = context
    current_stack_frame.context = new_context
    yield
  ensure
    current_stack_frame.context = old_context
  end
end
end
end
