require 'bigdecimal'
require 'win32/clipboard'	# gem install win32-clipboard


class Float

	# accurate modulo
	def %(other)
		x = BigDecimal(self.to_s)
		y = BigDecimal(other.to_s)
		z = x % y
		z.to_f
	end
end


class Array

	# circular index
	def on(idx)
		self.at(idx%self.size)
	end
	
	# sum of array
	def sigma
		inject(:+)
	end
	
	# average
	def avg
		self.sigma.to_f/self.size
	end
	
	# calc multi-dimensional array
	def add(x)
		self.map{|e| Array === e ? e.add(x) : e+x }
	end
	
	def mod(x)
		self.map{|e| Array === e ? e.mod(x) : e%x }
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
end


# export to file
def export(str, filepath)
#	Dir::chdir(File.dirname(__FILE__))
	f = File.open(filepath, 'w')
	f.puts str
	f.close
end


# copy to clipboard
def clipbd(x)
	x = x.inspect if Array === x
	Win32::Clipboard.set_data(x)
end

