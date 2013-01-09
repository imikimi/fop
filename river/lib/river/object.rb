module River
module Runtime

class Object
  attr_reader :parent, :mmethods, :mmembers

  class << self
    def new_root_object
      Object.new.tap do |o|
        o.set_method(:new) {|runtime,context,params| context.new}
        o.set_method(:debug) {|runtime,context,params| puts params.collect{|a| a.inspect}.join(', ')} # temporary implementation for debugging
        o.set_method(:eval) do |runtime,context,params|
          River::Runtime::Tests.validate_parameters(params,1)
          block = params[0]
          block.invoke_in context, runtime, :call, [], nil
        end

        o.set_method(:set_method) do |runtime,context,params|
          sym, proc = River::Runtime::Tests.validate_parameters params, [Runtime::Symbol, Runtime::Proc], "method = set_method"
          context.set_method sym.ruby_symbol, proc
        end

        o.set_method(:get_method) do |runtime,context,params|
          River::Runtime::Tests.validate_parameters params, [Runtime::Symbol], "method = get_method"
          method = context.find_method params[0].ruby_symbol
          method.kind_of?(Runtime::Proc) ? method : nil   # currently we allow procs written in pure ruby (like this one) as well as river procs; only return river procs
        end

        o.set_method(:set_member) do |runtime,context,params|
          sym, obj = River::Runtime::Tests.validate_parameters params, [Runtime::Symbol, true], "method = set_member"
          context.set_member sym.ruby_symbol, obj
        end

        o.set_method(:get_member) do |runtime,context,params|
          River::Runtime::Tests.validate_parameters params, [Runtime::Symbol], "method = get_member"
          context.get_member params[0].ruby_symbol
        end
      end
    end
  end

  def initialize(_parent = nil)
    self.parent=_parent
  end

  def new(*args)
    case args[0]
    when Model::Block then Runtime::Proc.new self, *args
    when ::Symbol then Runtime::Symbol.new self, *args
    when nil then Runtime::Object.new self
    else
      raise "hell"
    end
  end

  def ancestor?(k)
    k && (k==parent ? true : (parent && parent.ancestor?(k))) || false
  end

  def parent=(k)
    if k==self
      raise "cannot self-parent"
    elsif k && k.ancestor?(self)
      raise "k (#{k.inspect}) is an anscestor of self - circular parentage"
    else
      @parent=k
    end
  end

  def mmethods; @methods||={}; end
  def mmembers; @members||={}; end

  def set_member(member_name, value)
    mmembers[member_name] = value
  end

  def get_member(member_name)
    mmembers[member_name]
  end

  def set_method(method_name, river_block = nil, &block)
    mmethods[method_name] = river_block || block
  end

  # return which object is the parent of self
  def where_method(method_name)
    mmethods[method_name] ? self :
    (parent && parent!=self && parent.find_method(method_name))
  end

  def find_method(method_name)
    mmethods[method_name] ||
    (parent && parent!=self && parent.find_method(method_name))
  end

  def inspect
    "<#{self.class}:#{self.object_id}>"
  end

  def invoke(runtime, method_name, params, invoking_model)
    invoke_in self, runtime, method_name, params, invoking_model
  end

  def invoke_in(context, runtime, method_name, params, invoking_model)
    method = find_method method_name
    if method
      method.call runtime, context, params
    else
      raise "method #{method_name.inspect} not found on object #{context.inspect} methods=#{mmethods.keys.inspect} (line #{invoking_model && invoking_model.source_line}, column #{invoking_model && invoking_model.source_column})"
    end
  end
end

class Symbol < Object
  attr_accessor :ruby_symbol
  def initialize(parent, ruby_symbol)
    super parent
    @ruby_symbol = ruby_symbol
  end
end

class Proc < Object
  attr_accessor :block
  def initialize(parent, block, closure = nil)
    super parent
    @block = block
    @closure = closure
    set_method(:call) {|runtime, context, params| call runtime, context, params}
  end

  def call(runtime, context, params)
    if @closure
      @block.invoke runtime, @closure.context, params, @closure
    else
      @block.invoke runtime, context, params
    end
  end
end

end
end
