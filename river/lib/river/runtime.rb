module River
module Runtime

class Tests
  class << self
    def validate_parameter_length(parameters, expected_length)
      raise "Wrong number of parametrs. Expected #{required_length}, got #{parameters.length}." unless parameters.length==expected_length
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
