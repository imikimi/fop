module River
module Model

class Block < ModelNode
  attr_accessor :parameter_names, :body

  def setup_stack_frame(context, params, parent_stack_frame = nil)
    runtime.river_raise self, "wrong number of parameters. #{self} expects #{parameter_names.length} but got #{params.length}" unless params.length == parameter_names.length
    stack_frame = Runtime::StackFrame.new :context => context, :parent => parent_stack_frame, :source => self
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

class StatementBlock < Block
  attr_accessor :statements

  def initialize(statements, options = {})
    super options
    @statements = statements
    children statements
  end

  def is_part_of_message_parameter
    false
  end

  def to_code
    statements.collect(&:to_code).join "\n"
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
end

class FunctionDefinition < Block
  attr_accessor :name

  def initialize(name, parameter_names, body, options = {})
    super options
    @name = name
    @parameter_names = parameter_names
    @body = body
    children body
  end

  def to_s; name; end

  def to_code
    parameters_code = parameter_names && parameter_names.length>0 ? "(#{parameter_names.join(', ')})" : ""
    body_code = body.to_code
    code = "def #{name}#{parameters_code}\n#{indent body.to_code}\nend"
    one_liner(code) || code
  end

  def to_hash
    super.merge method_name:name.to_s, parameter_names:parameter_names.collect(&:to_s), body:body.to_hash
  end

  def evaluate(runtime)
    proc = runtime.root.derive self
    runtime.context.set_method(name,proc)
    proc
  end

end

class DoBlock < Block

  def initialize(parameter_names, body, options = {})
    super options
    @parameter_names = parameter_names
    @body = body
    children body
  end

  def to_code
    parameters_code = parameter_names && parameter_names.length>0 && "|#{parameter_names.join(', ')}|"
    "do#{parameters_code ? " "+parameters_code : ""}\n#{indent body.to_code}\nend"
  end

  def to_hash
    super.merge parameter_names:parameter_names.collect(&:to_s), body:body.to_hash
  end

  def evaluate(runtime)
    closure = runtime.current_stack_frame
    runtime.root.derive self, closure
  end
end

end
end
