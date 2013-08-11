class Object
  # Invokes the method identified by _method_, passing it any
  # arguments specified, just like the regular Ruby <tt>Object#send</tt> does.
  #
  # *Unlike* that method however, a +NoMethodError+ exception will *not* be raised
  # if the method does not exist.
  #
  # This differs from the regular Ruby <tt>Object#try</tt> method which only
  # suppresses the +NoMethodError+ exception if the object is Nil
  #
  # If try_method is called without a method to call, it will yield any given block with the object.
  #
  # Please also note that +try_method+ is defined on +Object+, therefore it won't work with
  # subclasses of +BasicObject+. For example, using try_method with +SimpleDelegator+ will
  # delegate +try_method+ to target instead of calling it on delegator itself.
  #
  # ==== Examples
  #
  # Without +try_method+
  #   @person && @person.respond_to?(:name) && @person.name
  # or
  #   (@person && @person.respond_to?(:name)) ? @person.name : nil
  #
  # With +try_method+
  #   @person.try_method(:name)
  #
  # +try_method+ also accepts arguments and/or a block, for the method it is trying
  #   Person.try_method(:find, 1)
  #   @people.try_method(:collect) {|p| p.name}
  #
  # Without a method argument try_method will yield to the block unless the receiver is nil.
  #   @person.try_method { |p| "#{p.first_name} #{p.last_name}" }
  #--
  # +try_method+ behaves like +Object#send+, unless called on +NilClass+ or a class that does not implement _method_.
  def try(method=nil, *args, &block)
    if method == nil && block_given?
      yield self
    elsif respond_to?(method)
      __send__(method, *args, &block)
    else
      nil
    end
  end
end

class NilClass
  # Calling +try_method+ on +nil+ always returns +nil+.
  # It becomes specially helpful when navigating through associations that may return +nil+.
  #
  # === Examples
  #
  #   nil.try_method(:name) # => nil
  #
  # Without +try_method+
  #   @person && @person.respond_to(:children) && !@person.children.blank? && @person.children.respond_to(:first) && @person.children.first.respond_to(:name) && @person.children.first.name
  #
  # With +try_method+
  #   @person.try_method(:children).try_method(:first).try_method(:name)
  def try(*args)
    nil
  end
end

class Array

   def to_ranges

      compact.sort.uniq.inject([]) do |r,x|

         r.empty? || r.last.last.succ != x ? r << (x..x) : r[0..-2] << (r.last.first..x)

      end

   end

end

