require 'bigdecimal'
require 'pp'

# accurate operators
class Float
	%w(+ - * / % **).each{|op|
		class_eval <<-EOS
			def #{op}(other)
				x = BigDecimal(self.to_s)
				y = BigDecimal(other.to_s)
				z = x #{op} y
				z.to_f
			end
		EOS
	}
end


class Complex
	%w(+ - * / % **).each{|op|
		class_eval <<-EOS
			def #{op}(other)
				x = BigDecimal(self.real.to_s)
				if Complex===other
					y = BigDecimal(other.real.to_s)
				else
					y = BigDecimal(other.to_s)
				end
				z = x #{op} y
				Complex(z.to_f, self.imag)
			end
		EOS
	}

	%w(== != < > <= >= <=>).each{|op|
		class_eval <<-EOS
			def #{op}(other)
				x = self.real
				if Complex===other
					y = other.real
				else
					y = other
				end
				x #{op} y
			end
		EOS
	}
end


class Array

	# circular index
	def on(idx)
		Complex===idx ? i=idx.real : i=idx
		self.at(i%self.size)
	end

	# sum of array
	# obsolete: replace by Array#sum (Ruby 2.4~)
	def sigma
		inject(:+)
	end

	# average
	def avg
		self.sum.to_f/self.size
	end

	# calc multi-dimensional array
	def add(x)
		self.map{|e|
			if Array === e
				e.add(x)
			elsif e!=nil
				if Complex === e
					e + Complex(x, 0)
				else
					e+x
				end
			else
				e
			end
		}
	end

	def mul(x)
		self.map{|e|
			if Array === e
				e.mul(x)
			elsif e!=nil
				e*x
			else
				e
			end
		}
	end

	def mod(x)
		self.map{|e|
			if Array === e
				e.mod(x)
			elsif e!=nil
				e%x
			else
				e
			end
		}
	end

	# conditional slice
	def slice_by(&block)
		x, y = [], []
		self.each{|e|
			if block.call(e)
				x << y if y!=[]
				y = []
			end
			y << e
		}
		x << y
		x
	end

	# deep copy
	def deepcopy
		Marshal.load(Marshal.dump(self))
	end

	# convert the intervals to array of pitch
	def itv_pch(mod=0)
		self.inject([0]){|arr,n|
			pc = arr.last+n
			pc %= mod if mod>0
			arr << pc
		}
	end


	def pch_itv(mod=0)
		self.zip(self.rotate(1)).map{|x,y| mod>0 ? (y-x)%mod : y-x}
	end
end


# export to file
def export(str, filepath)
#	Dir::chdir(File.dirname(__FILE__))
	f = File.open(filepath, 'w')
	f.puts str
	f.close
end
