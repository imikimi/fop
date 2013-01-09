module River
module Runtime

class Object
  attr_reader :parent, :mmethods, :mmembers

  class << self
    def new_root_object
      Object.new.tap do |o|
        o.set_method :new, lambda {|runtime,context,params| context.new}
        o.set_method :debug, lambda {|runtime,context,params| puts params.collect{|a| a.inspect}.join(', ')} # temporary implementation for debugging
        o.set_method :eval, (lambda do |runtime,context,params|
          River::Runtime::Tests.validate_parameter_length(params,1)
          block = params[0]
          block.invoke_in context, runtime, :call, [], nil
        end)
      end
    end
  end

  def initialize(_parent = nil)
    self.parent=_parent
  end

  def new
    Runtime::Object.new self
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

  def set_method(method_name, function_def)
    mmethods[method_name] = function_def
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

end
end
