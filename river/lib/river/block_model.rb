module River
module Model

module BlockTools
  attr_accessor :parameter_names, :body

  def setup_stack_frame(context, params, parent_stack_frame = nil)
    raise "wrong number of parameters. #{self} expects #{parameter_names.length} but got #{params.length}" unless params.length == parameter_names.length
    stack_frame = Runtime::StackFrame.new :context => context, :parent => parent_stack_frame
    parameter_names.each_with_index do |pname,index|
      stack_frame[pname] = params[index]
    end
    stack_frame
  end

  def invoke(runtime, context, params, parent_stack_frame = nil)
    stack_frame = setup_stack_frame context, params, parent_stack_frame

    runtime.in stack_frame do
      body.evaluate runtime
    end
  end
end

class FunctionDefinition
  include BlockTools
  attr_accessor :name

  def initialize(name, parameter_names, body)
    @name = name
    @parameter_names = parameter_names
    @body = body
  end

  def evaluate(runtime_now)
    runtime_now.context.set_method name, (lambda do |runtime_later,context,params|
      invoke(runtime_later,context,params)
    end)
    1 # return true
  end

  def to_s; name; end
end

# Execute "body" in a context.
# NOTE: context == the "self" pointer
class ContextStatement
  include BlockTools

  # context_statement returns the context in which the body will be executed
  attr_accessor :context_statement

  def initialize(context_statement, body)
    @context_statement = context_statement
    @body = body
  end

  def evaluate(runtime)
    context = context_statement.evaluate runtime

    runtime.in_context context do
      body.evaluate runtime
    end
  end
end

class StatementBlock
  attr_accessor :statements

  def initialize(statements)
    @statements = statements
  end

  def evaluate(runtime)
    ret = nil
    statements.each do |s|
      ret = s.evaluate(runtime)
    end
    ret
  end
end

class DoBlock
  include BlockTools
  def initialize(parameter_names, body)
    @parameter_names = parameter_names
    @body = body
  end

  def evaluate(runtime)
    closure = runtime.current_stack_frame
    runtime.root.new.tap do |functor|
      functor.set_method(:call, lambda do |runtime_later,context,params|
        invoke runtime_later, closure.context, params, closure
      end)
    end
  end
end

end
end
