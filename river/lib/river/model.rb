module River
module Model

class ModelNode
  attr_accessor :parse_node, :receives_message, :is_part_of_message_parameter
  attr_accessor :children, :parent

  def initialize(options={})
    @parse_node = options[:parse_node]
  end

  def children(*args)
    @children ||= begin
      args.flatten.compact.each {|child|child.parent = self}
    end
  end

  def is_part_of_message_parameter
    @is_part_of_message_parameter || (parent && parent.is_part_of_message_parameter)
  end

  def source_line; parse_node.line; end
  def source_column; parse_node.column; end

  # output parsable source-code
  def to_code
    "### #{self.class} has not implemented #to_code"
  end

  def to_one_liner(code)
    code.
      gsub(/[ \t\n]+end\b/,' end').
      gsub(/\n[ \t]*/,'; ')
  end

  def one_liner(code)
    max_oneliner_length = 80
    !code[/#[^\n]*/] && (one_liner=to_one_liner(code)).length <= max_oneliner_length && one_liner
  end

  def to_json
    to_hash.to_json
  end

  def to_hash
    {class_name:self.class.to_s.split("::")[-1]}
  end

  def parameters_to_code(parameters = self.parameters)
    if parameters && parameters.length>0
      ret = parameters.collect(&:to_code).join ', '
      receives_message || is_part_of_message_parameter ? "(#{ret})" : " #{ret}"
    else
      ""
    end
  end

  def indent(string, indent = "  ")
    indent + string.gsub("\n", "\n#{indent}")
  end
end

class SpecialOperator < ModelNode
  attr_accessor :left, :right, :operator

  def initialize(left, operator, right, options={})
    super options
    @left = left
    @right = right
    @operator = operator
    children left, right
  end

  def to_code
    "#{left} #{operator} #{right}"
  end

  def to_hash
    super.merge left:left.to_hash, right:right.to_hash
  end
end

class LogicalOr < SpecialOperator
  def evaluate(runtime); @left.evaluate(runtime) || @right.evaluate(runtime) end
end

class LogicalAnd < SpecialOperator
  def evaluate(runtime); @left.evaluate(runtime) && @right.evaluate(runtime) end
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

  def to_hash
    super.merge method_name:identifier.to_s, parameters:parameters.collect(&:to_hash)
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
    children(object,parameters)
    parameters && parameters.each {|p| p.is_part_of_message_parameter=true}
  end

  def validate_parameters(required_length)
    River::Runtime::Tests.validate_parameters(parameters,required_length)
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
    if obj_val.kind_of? Integer
      case identifier
      when :+, :*, :/, :- then validate_parameters(1);obj_val.send(identifier, param_evals[0])
      when :<, :<=, :>, :>=, :== then validate_parameters(1);obj_val.send(identifier, param_evals[0]) ? 1 : nil
      else raise "unsupported method on Integer #{identifier}"
      end
    else
      evaluate_method(runtime,obj_val,param_evals)
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

  def to_hash
    super.merge test_statement:test_statement.to_hash, body:body.to_hash, else_clause:else_clause && else_clause.to_hash
  end

  def initialize(test_statement, body, else_clause, options = {})
    super options
    @test_statement = test_statement
    @body = body
    @else_clause = else_clause
    children(test_statement, body, else_clause)
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

  def to_hash
    super.merge test_statement:test_statement.to_hash, body:body.to_hash
  end

  def initialize(test_statement, body, options = {})
    super options
    @test_statement = test_statement
    @body = body
    children  test_statement, body
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

  def to_hash
    super.merge identifier:identifier.to_s, parameters:parameters&&parameters.collect(&:to_hash)
  end

  def initialize(identifier,parameters, options = {})
    super options
    @identifier = identifier
    @parameters = parameters
    children parameters
    parameters && parameters.each {|p| p.is_part_of_message_parameter=true}
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
    "@#{identifier}"
  end

  def to_hash
    super.merge identifier:identifier.to_s
  end

  def initialize(identifier, options = {})
    super options
    @identifier = identifier
  end

  def evaluate(runtime)
    runtime.context.get_member identifier
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

  def to_hash
    super.merge identifier:identifier.to_s, statement:statement.to_hash
  end

  def initialize(identifier, statement, options={})
    super options
    @identifier = identifier
    @statement = statement
    children statement
  end
end

class MemberSet < Setter
  def to_code
    "@" + super
  end

  def evaluate(runtime)
    runtime.context.set_member identifier, statement.evaluate(runtime)
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

  def to_hash
    super.merge value:value
  end

  def initialize(value, options = {})
    super options
    @value = value
  end

  def evaluate(runtime)
    value
  end
end

class String < Constant
  def evaluate(runtime)
    runtime.root.new(value)
  end
end

# TODO: remove the Symbol and String models and replace with just Model::Constant. However, we need to register the symbol with the runtime at parse-time. Therefor the Parser needs to be linked to the runtime, which it isn't currently.
class Symbol < Constant
  def evaluate(runtime)
    runtime.get_symbol value
  end
end

end
end
