require 'bigdecimal'
#require 'win32/clipboard'	# gem install win32-clipboard


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
	# summation of array
	def sigma
#		s = inject(:+)
#		s==nil ? 0 : s
		inject(:+)
	end
	
	# adding to multi-dimensional array
	def mdadd(x)
		self.map{|e| Array === e ? e.mdadd(x) : e+x }
	end
	
	# conditional slicing
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
end


def export(str, filepath)
	Dir::chdir(File.dirname(__FILE__))
	f = File.open(filepath, 'w')
	f.puts str
	f.close
end


=begin
def set_clipboard(x)
	x = x.inspect if Array === x
	Win32::Clipboard.set_data(x)
end
=end

