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
          River::Runtime::Tests.validate_parameters params, [Runtime::Proc], "method = eval"
          block = params[0]
          block.call runtime, context, []
        end

        o.set_method(:set_method) do |runtime,context,params|
          sym, proc = River::Runtime::Tests.validate_parameters params, [Runtime::Symbol, Runtime::Proc], "method = set_method"
          context.set_method sym.ruby_object, proc
        end

        o.set_method(:get_method) do |runtime,context,params|
          River::Runtime::Tests.validate_parameters params, [Runtime::Symbol], "method = get_method"
          method = context.find_method params[0].ruby_object
          method.kind_of?(Runtime::Proc) ? method : nil   # currently we allow procs written in pure ruby (like this one) as well as river procs; only return river procs
        end

        o.set_method(:set_member) do |runtime,context,params|
          sym, obj = River::Runtime::Tests.validate_parameters params, [Runtime::Symbol, true], "method = set_member"
          context.set_member sym.ruby_object, obj
        end

        o.set_method(:get_member) do |runtime,context,params|
          River::Runtime::Tests.validate_parameters params, [Runtime::Symbol], "method = get_member"
          context.get_member params[0].ruby_object
        end

        o.set_method(:require) do  |runtime,context,params|
          River::Runtime::Tests.validate_parameters params, [Runtime::String], "method = require"
          runtime.river_include params[0].ruby_object
        end
      end
    end
  end

  def initialize(_parent = nil)
    self.parent=_parent
  end

  def new(*args)
    case args[0]
    when Model::Block then Runtime::Proc
    when ::String then Runtime::String
    when ::Symbol then Runtime::Symbol
    when nil then Runtime::Object
    else
      raise "hell"
    end.new self, *args
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
      runtime.river_raise invoking_model, "local or method #{method_name.inspect} not found"
    end
  end
end


class Proc < Object
  attr_accessor :block
  def initialize(parent, block, closure = nil)
    super parent
    @block = block
    @closure = closure
    set_method(:call) do |runtime, context, params|
      if @closure
        @block.invoke runtime, @closure.context, params, @closure
      else
        @block.invoke runtime, context, params
      end
    end
  end

  def call(runtime, context, params)
    @block.invoke runtime, context, params, @closure
  end
end

class WrappedRubyObject < Object
  attr_accessor :ruby_object

  def initialize(parent, ruby_object)
    super parent
    @ruby_object = ruby_object
  end

  def inspect; ruby_object.inspect; end
end

class Symbol < WrappedRubyObject
end

class String < WrappedRubyObject
  def initialize(parent, ruby_object)
    super
    set_method(:length) {|runtime, context, params| ruby_object.length}
    set_method(:+) do |runtime, context, params|
      River::Runtime::Tests.validate_parameters params, [Runtime::String], "method = +"
      Runtime::String.new parent, ruby_object + params[0].ruby_object
    end
  end
end

end
end
