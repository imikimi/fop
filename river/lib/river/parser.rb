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
  delimiter :whitespace?

  rule :root, :statements do
    def evaluate(runtime = Runtime::Stack.new)
      to_model.evaluate runtime
    end
  end

  rule :statements, :end_statement?, many?(:statement, :end_statement), :end_statement?, :delimiter => // do
    def to_model; River::Model::StatementBlock.new statement ? statement.collect{|s|s.to_model} : [], :parse_node => self; end
  end

  binary_operators_rule :statement, :method_invocation_chain, [[:/, :*], [:+, :-], [:<, :<=, :>, :>=, :==]], :delimiter => :space? do
    def to_model
      River::Model::MethodInvocation.new left.to_model, operator, [right.to_model], :parse_node => self
    end
  end

  rule :method_invocation_chain, :operand, ".", many(:method_invocation, "."), :delimiter => :space? do
    def to_model
      method_invocation.inject(operand.to_model) do |expression_so_far, invocation|
        expression_so_far.receives_message = true
        invocation.to_model expression_so_far
      end
    end
  end

  rule :method_invocation, :identifier, :assignment_operator, :whitespace?, :statement, :delimiter => :space? do
    def to_model(object_expression)
      River::Model::AssignmentMethodInvocation.new object_expression, identifier.to_sym, assignment_operator.to_sym, statement.to_model, :parse_node => self
    end
  end

  rule :assignment_operator, "="

  rule :method_invocation, :identifier, :parameters?, :delimiter => :space? do
    def parameters_model; parameters && parameters.to_model; end
    def to_model(object_expression)
      River::Model::MethodInvocation.new object_expression, identifier.to_sym, parameters_model, :parse_node => self
    end
  end

  rule :method_invocation_chain, :operand

  rule :end_statement, /([\t ]*[;\n])+[\t ]*/

  rule :operand, :function_definition
  rule :operand, :if_statement
  rule :operand, :while_statement
  rule :operand, :parenthetical_expression
  rule :operand, :local_variable_set
  rule :operand, :member_set
  rule :operand, :literal
  rule :operand, :self
  rule :operand, :identifier_get
  rule :operand, :member_get
  rule :operand, :block

  rule :function_definition, "def", :def_identifier, :parameter_list, :statements, "end", :delimiter => :space? do
    def to_model; River::Model::FunctionDefinition.new def_identifier.to_sym, parameter_names, statements.to_model, :parse_node => self; end
  end

  rule :parameter_list, "(", many?(:identifier, ","), ")" do
    def parameter_names
      @parameter_names ||= identifier ? identifier.collect{|a|a.to_sym} : []
    end
  end

  rule :parameter_list, :end_statement do
    def parameter_names; []; end
  end

  rule :if_statement, "if", :statement_then_statements, :else_clause?, "end" do
    def to_model; River::Model::IfStatement.new statement.to_model, statements.to_model, else_clause && else_clause.to_model, :parse_node => self; end
  end
  rule :else_clause, "else", :statements

  rule :while_statement, "while", :statement_then_statements, "end" do
    def to_model; River::Model::WhileStatement.new statement.to_model, statements.to_model, :parse_node => self; end
  end

  rule :statement_then_statements, :statement, :end_statement, :statements, :delimiter => //

  rule :block, "do", :do_parameter_list?, :statements, "end" do
    def to_model; River::Model::DoBlock.new parameter_names, statements.to_model, :parse_node => self; end

    def parameter_names; @parameter_names||=do_parameter_list ? do_parameter_list.parameter_names : []; end
  end

  rule :do_parameter_list, "|", many(:identifier, ","), "|" do
    def parameter_names
      @parameter_names ||= identifier.collect{|a|a.to_sym}
    end
  end

  rule :parenthetical_expression, "(", :statement, ")"

  rule :self, "self" do
    def to_model; River::Model::Self.new :parse_node => self; end
  end

  rule :local_variable_set, :identifier, "=", :statement do
    def to_model; River::Model::LocalVariableSet.new identifier.to_sym, statement.to_model, :parse_node => self; end
  end

  rule :member_set, :member_identifier, "=", :statement do
    def to_model; River::Model::MemberSet.new identifier.to_sym, statement.to_model, :parse_node => self; end
  end

  rule :member_get, :member_identifier do
    def to_model; River::Model::MemberGet.new identifier.to_sym, :parse_node => self; end
  end

  rule :identifier_get, dont.match(:keyword), :identifier, :parameters?, :delimiter => :space? do
    def parameters_model; parameters && parameters.to_model; end
    def to_model; River::Model::IdentifierGet.new identifier.to_sym, parameters_model, :parse_node => self; end
  end

  rule :parameters, "(", many(:statement,","), ")" do
    def to_model; statement.collect {|s|s.to_model}; end
  end

  rule :parameters, many(:statement,/[\t ]*,\s*/), :delimiter => // do
    def to_model; statement.collect {|s|s.to_model}; end
  end

  rule :keyword, /(root|do|end|if|while|in|else|def)\b/

  rule :member_identifier, "@", :identifier, :delimiter => //
  rule :identifier, /[_a-z][_a-z0-9]*/i
  rule :def_identifier, /[_a-z][_a-z0-9]*[=?!]?/i
  rule :literal, :nil
  rule :literal, :root_object
  rule :literal, :integer
  rule :literal, :symbol

  rule :space, many(:space_or_comment), :delimiter => //
  rule :whitespace, many(:whitespace_or_comment), :delimiter => //
  rule :space_or_comment, /[ \t]+/
  rule :space_or_comment, :comment
  rule :whitespace_or_comment, /\s+/
  rule :whitespace_or_comment, :comment
  rule :comment, /#[^\n]*/

  rule :symbol, ":", :identifier, :delimiter => // do
    def to_model; River::Model::Symbol.new identifier.to_sym, :parse_node => self; end
  end

  rule :root_object, "root" do
    def to_model; River::Model::RootObject.new :parse_node => self; end
  end

  rule :nil, "nil" do
    def to_model; River::Model::Constant.new nil, :parse_node => self; end
  end

  rule :integer, /[-]?[0-9]+/ do
    def to_model; River::Model::Constant.new to_s.to_i, :parse_node => self; end
  end
end
end
