module River
module Model

class ModelNode
  attr_accessor :parse_node

  def initialize(options={})
    @parse_node = options[:parse_node]
  end

  def source_line; parse_node.line; end
  def source_column; parse_node.column; end

  # output parsable source-code
  def to_code
    "### #{self.class} has not implemented #to_code"
  end

  def parameters_to_code(parameters = self.parameters)
    (parameters && parameters.length>0 ? "(#{parameters.collect(&:to_code).join ', '})" : "")
  end

  def indent(string, indent = "  ")
    indent + string.gsub("\n", "\n#{indent}")
  end
end

class MethodInvocation < ModelNode
  attr_accessor :identifier
  attr_accessor :object
  attr_accessor :parameters

  def to_code
    if operator_method?
      raise "hell" if parameters.length!=1
      "#{object.to_code} #{identifier} #{parameters[0].to_code}"
    else
      "#{object.to_code}.#{identifier}#{parameters_to_code}"
    end
  end

  def operator_method?
    return @operator_method unless @operator_method == nil
    @operator_method = !!identifier.to_s[/^[-<>=+!^%&*$]+$/]
  end

  def initialize(object, identifier, parameters, options = {})
    super options
    @identifier = identifier
    @object = object
    @parameters = parameters || []
  end

  def validate_parameter_length(required_length)
    raise "Wrong number of parametrs. Expected #{required_length}, got #{parameters.length}." unless parameters.length==required_length
  end

  def evaluated_object(runtime)
    @last_evaluated_object = object.evaluate(runtime).tap {|obj_val| raise "invoked method #{identifier.inspect} on nil" unless obj_val}
  end

  def evaluated_parameters(runtime)
    (parameters||[]).collect{|p|p.evaluate(runtime)}
  end

  # currently there is only one type of object, so we are hard-coding the method bodies here
  def evaluate(runtime)
    param_evals = evaluated_parameters runtime
    obj_val = evaluated_object runtime
    raise "invoked method #{identifier.inspect} on nil" unless obj_val
    case identifier
    when :+, :*, :/, :- then validate_parameter_length(1);obj_val.send(identifier, param_evals[0])
    when :<, :<=, :>, :>=, :== then validate_parameter_length(1);obj_val.send(identifier, param_evals[0]) ? 1 : nil
    else evaluate_method(runtime,obj_val,param_evals)
    end
  end

  def evaluate_method(runtime,obj_val,param_evals)
    obj_val.invoke runtime, identifier, param_evals, self
  end
end

class AssignmentMethodInvocation < MethodInvocation
  attr_accessor :assignment_operator

  def to_code
    "#{object.to_code+'.'}#{@identifier_without_operator} = #{parameters[0].to_code}"
  end

  def initialize(object, identifier, assignment_operator, value_expression, options = {})
    super object, "#{identifier}#{assignment_operator}".to_sym, [value_expression], options
    @assignment_operator = assignment_operator
    @identifier_without_operator = identifier
  end

  def evaluate(runtime)
    super
    @last_evaluated_object
  end
end

class IfStatement < ModelNode
  attr_accessor :test_statement, :body, :else_clause

  def to_code
    "if #{test_statement.to_code}\n#{indent body.to_code}#{else_clause && "\nelse\n#{indent else_clause.to_code}"}\nend"
  end

  def initialize(test_statement, body, else_clause, options = {})
    super options
    @test_statement = test_statement
    @body = body
    @else_clause = else_clause
  end

  def evaluate(runtime)
    if test_statement.evaluate(runtime)
      body.evaluate(runtime)
    elsif else_clause
      else_clause.evaluate(runtime)
    end
  end
end


class WhileStatement < ModelNode
  attr_accessor :test_statement, :body

  def to_code
    "while #{test_statement.to_code}\n#{indent body.to_code}\nend"
  end

  def initialize(test_statement, body, options = {})
    super options
    @test_statement = test_statement
    @body = body
  end

  def evaluate(runtime)
    ret = nil
    while test_statement.evaluate(runtime)
      ret = body.evaluate(runtime)
    end
    ret
  end
end

class IdentifierGet < ModelNode
  attr_accessor :identifier, :parameters

  def to_code
    identifier.to_s + parameters_to_code
  end

  def initialize(identifier,parameters, options = {})
    super options
    @identifier = identifier
    @parameters = parameters
  end

  def evaluated_parameters(runtime)
    (parameters||[]).collect{|p|p.evaluate(runtime)}
  end

  def evaluate(runtime)
    stack_frame = runtime.current_stack_frame
    context = stack_frame.context
    if stack_frame.has_local?(identifier)
      stack_frame[identifier]
    else
      context.invoke runtime, identifier, evaluated_parameters(runtime), self
    end
  end
end

class MemberGet < ModelNode
  attr_accessor :identifier

  def to_code
    identifier.to_s
  end

  def initialize(identifier, options = {})
    super options
    @identifier = identifier
  end

  def evaluate(runtime)
    runtime.context.mmembers[identifier]
  end
end

class Self < ModelNode
  def to_code; "self" end
  def evaluate(runtime)
    runtime.context
  end
end

class RootObject < ModelNode
  def to_code; "root" end
  def evaluate(runtime)
    runtime.root
  end
end

class Setter < ModelNode
  attr_accessor :identifier, :statement
  def to_code
    "#{identifier} = #{statement.to_code}"
  end

  def initialize(identifier, statement, options={})
    super options
    @identifier = identifier
    @statement = statement
  end
end

class MemberSet < Setter
  def evaluate(runtime)
    runtime.context.mmembers[identifier] = statement.evaluate(runtime)
  end
end

class LocalVariableSet < Setter

  def evaluate(runtime)
    runtime.current_stack_frame[identifier] = statement.evaluate(runtime)
  end
end

class Constant < ModelNode
  attr_accessor :value

  def to_code
    value.inspect
  end

  def initialize(value, options = {})
    super options
    @value = value
  end

  def evaluate(runtime)
    value
  end
end

end
end
