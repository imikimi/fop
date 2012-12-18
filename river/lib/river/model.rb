module River
module Model

class MethodInvocation
  attr_accessor :identifier
  attr_accessor :object
  attr_accessor :parameters

  def initialize(identifier, object, parameters)
    @identifier = identifier
    @object = object
    @parameters = parameters || []
  end

  def validate_parameter_length(required_length)
    raise "Wrong number of parametrs. Expected #{required_length}, got #{parameters.length}." unless parameters.length==required_length
  end

  def evaluated_object(runtime)
    object.evaluate runtime
  end

  def evaluated_parameters(runtime)
    (parameters||[]).collect{|p|p.evaluate(runtime)}
  end

  # currently there is only one type of object, so we are hard-coding the method bodies here
  def evaluate(runtime)
    param_evals = evaluated_parameters runtime
    obj_val = evaluated_object runtime
    case identifier
    when :+, :*, :/, :- then validate_parameter_length(1);obj_val.send(identifier, param_evals[0])
    when :<, :<=, :>, :>=, :== then validate_parameter_length(1);obj_val.send(identifier, param_evals[0]) ? 1 : nil
    else evaluate_method(runtime,obj_val,param_evals)
    end
  end

  def evaluate_method(runtime,obj_val,param_evals)
    obj_val.invoke runtime, identifier, param_evals
  end
end

class IfStatement
  attr_accessor :test_statement, :body, :else_clause

  def initialize(test_statement, body, else_clause)
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


class WhileStatement
  attr_accessor :test_statement, :body

  def initialize(test_statement, body)
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

class IdentifierGet
  attr_accessor :identifier, :parameters

  def initialize(identifier,parameters)
    @identifier = identifier
    @parameters = parameters
  end

  def evaluated_parameters(runtime)
    (parameters||[]).collect{|p|p.evaluate(runtime)}
  end

  def evaluate(runtime)
    stack_frame = runtime.current_stack_frame
    context = stack_frame[:"@context"]
    if stack_frame.has_key?(identifier)
      stack_frame[identifier]
    else
      context.invoke runtime, identifier, evaluated_parameters(runtime)
    end
  end
end

class MemberGet
  attr_accessor :identifier

  def initialize(identifier)
    @identifier = identifier
  end

  def evaluate(runtime)
    runtime.context.mmembers[identifier]
  end
end

class Self
  def evaluate(runtime)
    runtime.context
  end
end

class RootObject
  def evaluate(runtime)
    runtime.root
  end
end

class Setter
  attr_accessor :identifier, :statement

  def initialize(identifier, statement)
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
    stack_frame = runtime.current_stack_frame
    stack_frame[identifier] = statement.evaluate(runtime)
  end
end

class Constant
  attr_accessor :value

  def initialize(value)
    @value = value
  end

  def evaluate(runtime)
    value
  end
end

end
end
