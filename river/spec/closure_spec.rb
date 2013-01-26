#TODO:
=begin

I want to test all aspects of closures, which is actually kinda confusing :).

Things to test:

* self is captured in a closure, but it is only used if the River method "call" is invoked on the Proc object
* we don't have return/break/next yet, but when we do, those work differently if the block as a "Def" or a "do"
* "def" does not have any closure
* "do" which is used in an "eval" or is assigned to a specifc_named class method via set_method will have a closure, but it will use the appropriate context - the object eval was invoked on, or the object.specifc_named was invoked on.

first-class function variants
 * captures enclosing stack-frame? (is a "closure", changes to locals are shared among the parent block and all other closures)
 * captures enclosing context ("self") ?
 * break / continue / next / return do what?
 * "binds" values from the enclosing stack-frame ? (gets a COPY of the current locals)
=end
