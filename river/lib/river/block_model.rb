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

class FunctionDefinition < ModelNode
  include BlockTools
  attr_accessor :name

  def to_code
    parameters_code = parameter_names && parameter_names.length>0 ? "(#{parameter_names.join(', ')})" : ""
    "def #{name}#{parameters_code}\n#{indent body.to_code}\nend"
  end

  def to_hash
    super.merge method_name:name.to_s, parameter_names:parameter_names.collect(&:to_s), body:body.to_hash
  end

  def initialize(name, parameter_names, body, options = {})
    super options
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

class StatementBlock < ModelNode
  attr_accessor :statements

  def initialize(statements, options = {})
    super options
    @statements = statements
  end

  def to_hash
    super.merge statements:statements.collect(&:to_hash)
  end

  def evaluate(runtime)
    ret = nil
    statements.each do |s|
      ret = s.evaluate(runtime)
    end
    ret
  end

  def to_code
    statements.collect(&:to_code).join "\n"
  end
end

class DoBlock < ModelNode
  include BlockTools

  def to_code
    parameters_code = parameter_names && parameter_names.length>0 ? "|#{parameter_names.join(', ')}|" : ""
    "do #{parameters_code}\n#{indent body.to_code}\nend"
  end

  def to_hash
    super.merge parameter_names:parameter_names.collect(&:to_s), body:body.to_hash
  end

  def initialize(parameter_names, body, options = {})
    super options
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
