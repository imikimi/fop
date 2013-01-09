module River
module Runtime

class Tests
  class << self
    def validate_parameters(parameters, length_or_types, info='')
      length = case length_or_types
      when Integer then length_or_types
      when Array then
        types = length_or_types
        types.length
      end
      raise "Wrong number of parameters. Expected #{length}, got #{parameters.length}. #{info}" unless parameters.length == length
      types && types.each_with_index do |klass, i|
        next if klass==true
        raise "Wrong parameter type for parameter #{i+1}/#{types.length}. Expected #{klass}, got #{parameters[i].class}. #{info}" unless klass == parameters[i].class
      end
      parameters
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

  attr_reader :root, :symbols

  def initialize
    @root = top_stack_frame.context
    @symbols = {}
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

  def get_symbol(symbol)
    symbols||=root.new symbol
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
