require 'test/unit'

class Foobar
	attr_accessor :foo, :bar
	def initialize
		@foo = ""
		@bar = 0
	end
	def to_s
		"Foo: #{@foo} Bar: #{@bar}"
	end
end

class FoobarTest < Test::Unit::TestCase
	def test_initialize
		fb = Foobar.new
		assert_not_nil(fb)
	end	
	def test_foo
		fb = Foobar.new
		assert_equal("", fb.foo)
		fb.foo = "Hello Dolly!"
		assert_equal("Hello Dolly!", fb.foo)
	end
	def test_bar
		fb = Foobar.new
		assert_equal(0, fb.bar)
		fb.bar = 13
		assert_equal(13, fb.bar)
	end
	def test_to_s
		fb = Foobar.new
		fb.foo = "Hello Dolly."
		fb.bar = 10
		assert_equal("Foo: Hello Dolly. Bar: 10", fb.to_s)
	end
end
