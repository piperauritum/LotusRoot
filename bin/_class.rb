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
		@du.flatten.sum
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
	attr_accessor :par, :evts

	def initialize(param=nil, event=nil)
		@par, @evts = param, event
		@evts = Event.new("r!", nil) if event==nil
	end

	def ar
		[@par.ar, @evts.ar]
	end
end


class MtrParam
	attr_accessor :beat, :unit, :orig

	def initialize(param)
		@orig = param
		param = [[param], 1] if Integer === param
		if param[0].size==1
			x = param[0][0]
			y = if x%3==0
				[3]*(x/3)
			else
				[2]*(x/2)+[x%2]-[0]
			end
			param = [y, param[1]]
		end
		@beat, @unit = param
	end

	def ar
		[@beat, @unit]
	end
end


class Bar
	attr_accessor :mtr, :tpls

	def initialize(metre=nil, tuplets=[])
		@mtr, @tpls = metre, tuplets
	end

	def ar
		[@mtr.ar, @tpls.ar]
	end
end


class Array
	def ar
		self.map(&:ar)
	end

	def to_tpar
		TplParam.new(self)
	end
end
