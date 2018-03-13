class Event
	attr_accessor :el, :du

	def initialize(element, duration)
		if Array === duration
			@el, @du = element, duration
		else
			@el, @du = element, [duration]
		end
	end

	def ar
		[@el, @du]
	end

	def dsum
		@du.flatten.sigma
	end
end


class MtrParam
	attr_accessor :beat, :unit

	def initialize(array)
		@beat, @unit = array
	end

	def ar
		[@beat, @unit]
	end
end


class TplParam
	attr_accessor :numer, :denom, :unit

	def initialize(array)
		@numer, @denom, @unit = array
	end

	def ar
		[@numer, @denom, @unit]
	end

	def tick
		Rational(@denom*@unit, @numer)
	end

	def even?
		@numer == @denom
	end

	def dot?
		[
			Math.log2(@numer)%1==0,
			@denom%3==0,
			note_value_dot(self)!=nil
		].all?
	end
end


class Tuplet
	attr_accessor :evt, :par

	def initialize(event=nil, param=nil)
		@evt, @par = event, param
		@evt = Event.new("r!", nil) if event==nil
	end

	def ar
		[@evt.ar, @par.ar]
	end
end


class Array
	def ar
		self.map(&:ar)
	end

	def to_tpp
		TplParam.new(self)
	end
end