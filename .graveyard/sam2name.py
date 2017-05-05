# NOT FOR GENERAL USAGE, used once as the sample IDs instead of the sample Names were placed into the columns of the tsv files in results/ dir
import sys

convert = { 'S1': 'B33', 'S2': 'B41', 'S3': 'B42', 'S4': 'B66', 'S5': 'B67',
	  'S6': 'B69', 'S7': 'B76', 'S8': 'B77', 'S9': 'B33r', 'S10': 'B41r',
	  'S11': 'B42r', 'S12': 'B66r', 'S13': 'B67r', 'S14': 'B69r', 'S15': 'B76r',
	  'S16': 'B77r', 'S17': 'T33', 'S18': 'T41', 'S19': 'T42', 'S20': 'T66',
	  'S21': 'T67', 'S22': 'T69', 'S23': 'T76', 'S24': 'T77', 'S25': 'T33r', 
	  'S26': 'T41r', 'S27': 'T42r', 'S28': 'T66r', 'S29': 'T67r', 'S30': 'T69r',
	  'S31': 'T76r', 'S32': 'T77r', 'S33': 'B80', 'S34': 'T80', 'S35': 'FM', 
	  'S36': 'FUM', 'S37': 'water1', 'S38': 'water2', 'S39': 'cf85', 'S40': 'cf89',
	  'S41': 'B80r', 'S42': 'T80r', 'S43': 'FMr', 'S44': 'FUMr', 'S45': 'water3',
	  'S46': 'water4', 'S47': 'cf85r', 'S48': 'cf89r'}

output = open(sys.argv[2], 'w') 

count = 0
with open(sys.argv[1]) as f:
	for line in f:
		if count == 0:
			if line.startswith("#"):
				header = [x.split("_")[1] if "_" in x else x for x in line.rstrip("\n").split("\t")]
			else:
				header = line.rstrip("\n").split("\t")
			new_header = [convert.get(x) if x in convert.keys() else x for x in header]
			new_header = "\t".join(new_header) + "\n"
			output.write(new_header)
			count += 1
		else:
			output.write(line)
			count += 1
