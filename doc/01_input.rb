require_relative '../bin/LotusRoot'

## Elements will be unfold with Durations ##

## Example:
## elm = ["@"]; dur = [3]
## => elm = ["@", "=", "="]

# Pitches
pch = [0, 3, 2, 2, 5, 3, 3, 5, 7, 8, 2, 3, 5, 7, 0, 2, 3, 5, -1, -5, 3, -5, -7, 
-4, -5, -5, -7, -9, -2, 7, -3, -2, -2, 2, 3, 2, -2, 0, -2, -4, -5, 0, 6, 7, 0, 
2, 3, -2, -3, -5, -5]

# Elements
elm = ["@", "@", "@", "@", "@", "@", "@", "@", "@", "@", "@", "@", "@", "@", 
"@", "@", "@", "@", "@", "@", "r!", "@", "@", "@", "@", "@", "@", "@", "@", 
"@", "@", "@\\trill", "@", "@", "r!", "@", "@", "@", "r!", "@", "@", "@", "@", 
"@", "@", "@", "@", "@", "@", "@", "@", "@", "@", "@"]

# Durations
dur = [14, 1, 1, 6, 1, 1, 5, 1, 1, 1, 5, 1, 1, 1, 5, 1, 1, 1, 2, 2, 12, 14, 2, 
6, 1, 1, 2, 1, 1, 6, 2, 3, 1, 4, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 6, 2, 1, 1, 1, 
1, 2, 1, 1, 4]

# Tuplets
tpl = [4]

sco = Score.new(dur, elm, tpl, pch)		# Initialize
sco.pitchShift = 24
sco.accMode = 1
sco.altNoteName = [[6, "fis"]]
sco.gen									# Generates LilyPond code
sco.print								# Outputs to console
sco.export("sco.txt")					# Exports to a textfile