﻿class Event
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


class Bar
	attr_accessor :mtr, :tpls

	def initialize(metre=nil, tuplets=[])
		@mtr, @tpls = metre, tuplets
	end

	def ar
		[@mtr.ar, @tpls.ar]
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


class Array
	def ar
		self.map(&:ar)
	end

	def to_tpp
		TplParam.new(self)
	end
end