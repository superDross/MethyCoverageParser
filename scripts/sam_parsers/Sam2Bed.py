''' Script to read in bismark paired end SAM and parse to give BED of fragments for calulating read depth across features
 
 
        default                  old_flag
   ===================     ===================
   Read 1       Read 2     Read 1       Read 2
 OT:    99           147        67           131
 OB:    83           163        115           179
 CTOT:  147          99         131           67
 CTOB:  163          83         179           115

Proper Read Pairs; paired end reads which align inwards on oppossing strands, oppossed to aligning in the same direction.

Proper Pairs OT/OB 
        
       PE1
      ---->
------------------- +
------------------- -
      <----
       PE2



Proper Pairs CTOT/CTOB

       PE2
      ---->
------------------- +
------------------- -
      <----
       PE1


Created by Duncan Sproul
Edited by David Ross
'''
# Load regular expression module
import re
import argparse

def main(sam_file, out_file, non_directional=False):
    ''' Extract the proper paired reads from a SAM file and
        export positions to a BED file.

    Args:
        sam_file: input SAM file
        bed_file: output BED file name
        non_directional: check for complementary proper paired reads too (CTOB/CTOT)
    '''
    # open files needed
    f = open(sam_file, 'r')
    fo = open(out_file, 'w')

    # Set a header flag
    head_flag = 0

    print("Processing paired SAM end file to BED: "+sam_file)

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
                # for OT and OB
                if int(read1[1]) == 99 and int(read2[1]) == 147:
                    fo.write(chr1+"\t"+start1+"\t"+str(end2)+"\t"+read1[0]+"\n")
                if int(read1[1]) == 83 and int(read2[1]) == 163:
                    fo.write(chr1+"\t"+start2+"\t"+str(end1)+"\t"+read1[0]+"\n")

                # for CTOB or CTOT reads: 
                if non_directional:
                    if int(read1[1]) == 163 and int(read2[1]) == 83:
                        fo.write(chr1+"\t"+start1+"\t"+str(end2)+"\t"+read1[0]+"\n")
                    if int(read1[1]) == 147 and int(read2[1]) == 99:
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
            # for OT and OB
            if int(read1[1]) == 99 and int(read2[1]) == 147:
                fo.write(chr1+"\t"+start1+"\t"+str(end2)+"\t"+read1[0]+"\n")
            if int(read1[1]) == 83 and int(read2[1]) == 163:
                fo.write(chr1+"\t"+start2+"\t"+str(end1)+"\t"+read1[0]+"\n")
                 
            # for CTOB or CTOT reads: 
            if non_directional:
                if int(read1[1]) == 163 and int(read2[1]) == 83:
                    fo.write(chr1+"\t"+start1+"\t"+str(end2)+"\t"+read1[0]+"\n")
                if int(read1[1]) == 147 and int(read2[1]) == 99:
                    fo.write(chr1+"\t"+start2+"\t"+str(end1)+"\t"+read1[0]+"\n")
            
                        
    # Close files
    f.close()
    fo.close()

    print("BED file generation completed")
    print("Results file: " + out_file)


def cli():
    parser = argparse.ArgumentParser(description='Extract proper read pair positions from a given SAM file and ouput into a BED file')
    parser.add_argument('-i', '--sam', help='inputted SAM file')
    parser.add_argument('-o', '--bed', help='name of ouputted BED file')
    parser.add_argument('-nd', '--non_directional',action='store_true', help='checks SAM file for proper paired complementary reads also (CTOT & CTOB)')
    args = vars(parser.parse_args())
    main(args['sam'], args['bed'], args['non_directional'])


if __name__ == '__main__':
    cli()
