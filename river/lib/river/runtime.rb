module River
module Runtime

class Error < Exception
end

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
  attr_accessor :source

  # options: :context, :locals, :parent, :source
  def initialize(options={})
    @context = options[:context] || Object.new_root_object
    @locals = Hash.new options[:locals]
    @parent = options[:parent]
    @source = options[:source]
  end

  def source_trace
    case source
    when ::String
      source
    when nil
      "(missing source info)"
    else
      source.source_ref(context)
    end
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
    @top_stack_frame ||= StackFrame.new :source => "(root stack frame)"
  end

  attr_reader :root, :symbols, :includes, :stack

  def initialize
    @root = top_stack_frame.context
    @symbols = {}
    @includes = {}
    @stack = [top_stack_frame]
  end


  def river_include(raw_filename)
    filename = File.expand_path(raw_filename)
    filename += ".river" unless filename[/\.river$/]
    return nil if @includes[filename]
    raise "include file does not exist: #{filename}" unless File.exists?(filename)

    src = File.read filename
    parser = River::Parser.new :source_file => raw_filename
    parsed = parser.parse src

    unless parsed
      $stderr.puts "Parsing failed on file: #{filename}"
      $stderr.puts parser.parser_failure_info
      raise "included file #{filename.inspect} failed to parse"
    end

    model = parsed.to_model
    model.evaluate self

    @includes[filename] = 1 # return a true value for river = any integer works
  end

  def backtrace
    stack[1..-1].reverse.collect &:source_trace
  end

  def backtrace_sources
    stack[1..-1].reverse.collect &:source
  end

  def context; current_stack_frame.context; end

  def current_stack_frame; stack[-1]; end

  def push_stack_frame(stack_frame)
    raise "no source" unless stack_frame.source
    stack << stack_frame
  end

  def pop_stack_frame
    stack.pop
  end

  def river_raise(source, error_string)
    puts error_string+"\n"+ BabelBridge::Tools.uniform_tabs((["  "+source.source_ref]+backtrace).join("\n  "))
    raise Error.new(error_string)
  end

  def in(stack_frame)
    push_stack_frame(stack_frame)
    yield
  ensure
    pop_stack_frame
  end

  def get_symbol(symbol)
    symbols[symbol]||=root.new symbol
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
