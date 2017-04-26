#Danny's script to parse coverage files from Bismark
import os
import sys

print(sys.argv)
#datadir = '/exports/eddie/scratch/dross11/bed_files/'
datadir = sys.argv[1]
data = {}

#fout = open('outputparse.txt', 'w')
fout = open(sys.argv[2], 'w')

for filename in os.listdir(datadir):
  if filename.endswith("coverage.txt"):
    sample = filename.split('_')[1]
    fname = os.path.join(datadir, filename)
    print(fname)
    with open(fname) as fin:
      for line in fin:
        line = line.strip()
        tokens = line.split('\t')
        key = (tokens[0], tokens[1], tokens[2])
        if key not in data:
          data[key] = {}
        data[key][sample] = tokens[3]

printheader = True
for (k1, k2, k3) in data:
	if printheader:
		fout.write('\t\t')
		for key in data[(k1, k2, k3)]:
			fout.write('\t' + key)
		fout.write('\n')
		printheader = False
	fout.write(k1 + '\t' + k2 + '\t' + k3)
	for key in data[(k1, k2, k3)]:
		fout.write('\t' + data[(k1, k2, k3)][key])
	fout.write('\n')

	
