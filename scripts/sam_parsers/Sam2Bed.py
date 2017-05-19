''' Script to read in bismark paired end SAM and parse to give BED of fragments for calulating read depth across features
Created by Duncan Sproul
'''

# Load regular expression module
import re
import sys

# open files needed
f = open(sys.argv[1], 'r')
fo = open(sys.argv[2], 'w')

# Set a header flag
head_flag = 0

print(" Processing paired SAM end file to BED: "+sys.argv[1])

# cycle through file and print out
while True:
    line1 = f.readline()
    if not line1: 
        break 

    line1.strip("\n")
    
    # Check to see if the last line was header
    if head_flag == 0:
        
        # Check if we are still in header
        if not re.search('^@', line1):
            # if we are not, set flag to 1
            head_flag = 1
            
            # now, process this set of lines
            # Otherwise get out of sync
            # Read in strip and check line2 exists
            line2 = f.readline()
            line2.strip("\n")
            if not line2: 
                break
            
            # Process both lines
            # Split the lines
            read1 = line1.split("\t")
            read2 = line2.split("\t")
            chr1 = read1[2]
            chr2 = read2[2]
            start1 = read1[3]
            start2 = read2[3]
            length1 = len(read1[9])
            length2 = len(read2[9])
            end1 = int(start1)+length1
            end2 = int(start2)+length2

            # write out
            # determines if they are paired and proper pairs
            if int(read1[1]) == 99 and int(read2[1]) == 147:
                fo.write(chr1+"\t"+start1+"\t"+str(end2)+"\t"+read1[0]+"\n")
            if int(read1[1]) == 83 and int(read2[1]) == 163:
                fo.write(chr1+"\t"+start2+"\t"+str(end1)+"\t"+read1[0]+"\n")
                
    # Not in header, process lines
    else :
        # Read in strip and check line2 exists
        line2 = f.readline()
        line2.strip("\n")
        if not line2: 
            break
        
        # Process both lines
        # Split the lines
        read1 = line1.split("\t")
        read2 = line2.split("\t")
        chr1 = read1[2]
        chr2 = read2[2]
        start1 = read1[3]
        start2 = read2[3]
        length1 = len(read1[9])
        length2 = len(read2[9])
        end1 = int(start1)+length1
        end2 = int(start2)+length2
            
        # Write out
        if int(read1[1]) == 99 and int(read2[1]) == 147:
            fo.write(chr1+"\t"+start1+"\t"+str(end2)+"\t"+read1[0]+"\n")
        if int(read1[1]) == 83 and int(read2[1]) == 163:
            fo.write(chr1+"\t"+start2+"\t"+str(end1)+"\t"+read1[0]+"\n")
        
# Close files
f.close()
fo.close()

print(" BED file generation completed")
print(" Results file: " + sys.argv[2])
