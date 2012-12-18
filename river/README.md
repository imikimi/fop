# River

TODO: Write a gem description

## Installation

Add this line to your application's Gemfile:

    gem 'river'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install river

## Usage

TODO: Write usage instructions here

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

# River Language

### Locals

    a = 123

### If

    a = 12
    if a == 12 then
      a = 24
    end

### If-Else

    a = 12
    if a == 13 then
      a = 24
    else
      a = 36
    end

### While

    b = 1
    a = 10
    while a > 0 do
      a = a - 1
      b = b * 2
    end

### Object and Contexts

Everything executes within the context of an object. By default, this is the root object. When you define new methods you are defining new methods on the object which is the current context.

Objects in River are very simple. They consist of 3 parts:

1. Members: These are named values stored in the object. This is just a Ruby hash from symbols to River-values.
1. Methods: Named methods associated with the object. Note, these methods are only available to the object the belong to OR CHILD OBJECTS
1. Parent: If a method is invoked on this object, but this object doesn't have the named method, the call is forward to the parent object. Note, the CONTEXT will still be THIS object (self), but the Parent object's method will be used

Accessing the current context-object:

    self

Invocking methods on objects:

    my_object.a_method
    my_object.b_method()
    my_object.c_method(1,2,3)

Creating a new object

    new
    any_existing_object.new

Getting and setting members of the current context

    @my_member = 123
    @my_double_member = @my_member * 2

Adding methods to the current context. Note, if a same-named method already exists, it is replaced silently

    def my_method_name do
      123
    end

    def my_method_name_with_params(a,b) do
      a*b
    end

Executing in a context

    point = new
    in point do
      @x = @y = 0;
      def x do @x end
      def y do @y end
      def set_x(x) do @x=x end
      def set_y(y) do @y=y end
      def area do @x * @y end
    end

    point.set_x(12)
    point.set_y(10)
    point.area
    > 120
