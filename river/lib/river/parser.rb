# A turing complete programming language
# Example program that computes the power of two of the value stored in the [0] register:
# => [0]=32;[1]=1;while [0]>0 do [1] = [1] * 2; [0] = [0]-1; end;[1]

# DONE: turing.rb PLUS
# => functions
# => local variables
# => stack
# TODO: add variables and functions
# TODO: add closures
# TODO: add classes

module River
class Parser < BabelBridge::Parser
  ignore_whitespace

  rule :root, :statements do
    def evaluate(runtime = Runtime::Stack.new)
      to_model.evaluate runtime
    end
  end

  rule :statements, many?(:not_end_statement, :end_statement), match?(:end_statement) do
    def to_model; River::Model::StatementBlock.new not_end_statement ? not_end_statement.collect{|s|s.to_model} : []; end
  end

  rule :not_end_statement, dont.match("end"), :statement


  binary_operators_rule :statement, :method_invocation_chain, [[:/, :*], [:+, :-], [:<, :<=, :>, :>=, :==]] do
    def to_model
      River::Model::MethodInvocation.new operator, left.to_model, [right.to_model]
    end
  end

  rule :method_invocation_chain, :operand, ".", many(:identifier_get, ".") do
    def to_model
      invocations = identifier_get
      ret = operand.to_model
      while invocations.length > 0
        i = invocations[0]
        invocations = invocations[1..-1]
        ret = River::Model::MethodInvocation.new i.identifier.to_sym, ret, i.parameters_model
      end
      ret
    end
  end

  rule :method_invocation_chain, :operand

  rule :end_statement, rewind_whitespace, /([\t ]*[;\n])+/

  rule :operand, :function_definition
  rule :operand, :if_statement
  rule :operand, :while_statement
  rule :operand, :context_statement

  rule :function_definition, "def", :identifier, :parameter_list?, :end_statement, :statements, "end" do
    def to_model; River::Model::FunctionDefinition.new identifier.to_sym, parameter_names, statements.to_model; end

    def parameter_names; @parameter_names||=parameter_list ? parameter_list.parameter_names : []; end
  end

  rule :parameter_list, "(", many(:identifier, ","), ")" do
    def parameter_names
      @parameter_names ||= identifier.collect{|a|a.to_sym}
    end
  end

  rule :if_statement, "if", :statement, "then", :statements, :else_clause?, "end" do
    def to_model; River::Model::IfStatement.new statement.to_model, statements.to_model, else_clause && else_clause.to_model; end
  end
  rule :else_clause, "else", :statements

  rule :while_statement, "while", :statement, :end_statement, :statements, "end" do
    def to_model; River::Model::WhileStatement.new statement.to_model, statements.to_model; end
  end

  rule :context_statement, "in", :statement, :end_statement, :statements, "end" do
    def to_model; River::Model::ContextStatement.new statement.to_model, statements.to_model; end
  end

  rule :operand, :parenthetical_expression
  rule :operand, :local_variable_set
  rule :operand, :member_set
  rule :operand, :literal
  rule :operand, :self
  rule :operand, :identifier_get
  rule :operand, :member_get
=begin
  rule :operand, :block

  rule :block, "do", :do_parameter_list?, :statements, "end" do
    def to_model; River::Model::DoBlock.new identifier.to_sym, parameter_names, statements.to_model; end

    def parameter_names; @parameter_names||=parameter_list ? parameter_list.parameter_names : []; end
  end
=end

  rule :do_parameter_list, "|", many(:identifier, ","), "|" do
    def parameter_names
      @parameter_names ||= identifier.collect{|a|a.to_sym}
    end
  end


  rule :parenthetical_expression, "(", :statement, ")"

  rule :self, "self" do
    def to_model; River::Model::Self.new; end
  end

  rule :local_variable_set, :identifier, "=", :statement do
    def to_model; River::Model::LocalVariableSet.new identifier.to_sym, statement.to_model; end
  end

  rule :member_set, :member_identifier, "=", :statement do
    def to_model; River::Model::MemberSet.new member_identifier.to_sym, statement.to_model; end
  end

  rule :member_get, :member_identifier do
    def to_model; River::Model::MemberGet.new member_identifier.to_sym; end
  end

  rule :identifier_get, dont.match(:keyword), :identifier, :parameters? do
    def parameters_model; parameters && parameters.to_model; end
    def to_model; River::Model::IdentifierGet.new identifier.to_sym, parameters_model; end
  end

  rule :parameters, "(", many(:statement,","), ")" do
    def to_model; statement.collect {|s|s.to_model}; end
  end

  rule :parameters, rewind_whitespace, /[ \t]*/, rewind_whitespace, many(:statement,",") do
    def to_model; statement.collect {|s|s.to_model}; end
  end

  rule :keyword, /(root|do|end|if|while|then|in)[^a-zA-Z0-9_]/

  rule :member_identifier, /@[_a-zA-Z][_a-zA-Z0-9]*/
  rule :identifier, /[_a-zA-Z][_a-zA-Z0-9]*/
  rule :literal, :nil
  rule :literal, :root_object
  rule :literal, :integer

  rule :root_object, "root" do
    def to_model; River::Model::RootObject.new; end
  end

  rule :nil, "nil" do
    def to_model; River::Model::Constant.new nil; end
  end

  rule :integer, /[-]?[0-9]+/ do
    def to_model; River::Model::Constant.new to_s.to_i; end
  end
end
end
