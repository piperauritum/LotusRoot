require 'win32/clipboard'		## gem install win32-clipboard

# copy to clipboard (for maintenance)
def clipbd(x)
	x = x.inspect if Array === x
	Win32::Clipboard.set_data("#{x}")
end