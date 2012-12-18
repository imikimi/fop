module River
module Model

module BlockTools
  attr_accessor :parameter_names

  def new_stack_frame(runtime, context, locals={})
    locals.merge! :"@context" => context
    runtime.push_new_stack_frame locals
  end

  def process_params(params)
    raise "wrong number of parameters. #{self} expects #{parameter_names.length} but got #{params.length}" unless params.length == parameter_names.length
    locals = {}
    parameter_names.each_with_index do |pname,index|
      locals[pname] = params[index]
    end
    locals
  end

  def invoke(runtime, context, params)
    locals = process_params params

    new_stack_frame runtime, context, locals
    body.evaluate(runtime).tap {runtime.pop_stack_frame}
  end
end

class FunctionDefinition
  include BlockTools
  attr_accessor :name, :body

  def initialize(name, parameter_names, body)
    @name = name
    @parameter_names = parameter_names
    @body = body
  end

  def evaluate(runtime_now)
    runtime_now.context.set_method name, lambda {|runtime_later,context,params| invoke(runtime_later,context,params)}
    1 # return true
  end

  def to_s; name; end
end

=begin
class DoBlock
  include BlockTools
  attr_accessor :body

  def initialize(parameter_names, body)
    @parameter_names = parameter_names
    @body = body
  end

  def evaluate(runtime)
    lambda {|runtime_later,context,params| invoke(runtime_later,context,params)}
  end
end
=end

class ContextStatement
  include BlockTools
  attr_accessor :context_statement, :body

  def initialize(context_statement, body)
    @context_statement = context_statement
    @body = body
  end

  def evaluate(runtime)
    context = context_statement.evaluate runtime
    new_stack_frame runtime, context
    body.evaluate(runtime).tap {runtime.pop_stack_frame}
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

end
end
