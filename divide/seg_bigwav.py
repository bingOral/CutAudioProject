#!/usr/bin/python
#~ -*- utf8 -*-

import sys
import os.path
import shutil
import struct
import numpy as np
import soundfile as sf

'''
seg big_wav based vad_result

if len(sys.argv) != 2 and len(sys.argv) != 4:
    print "Usage     : python %s  vad_result_key2points  [fade-in]  [fade-out]" % sys.argv[0]
    print "@fade-in  : speech segments extend backward N mss"
    print "@fade-out : speech segments extend forward N ms"
    print ""
    print "E.G.      : python %s  log.vad  300  300" % sys.argv[0]
    exit(1)
'''

fade_in = 0
fade_out = 0
if len(sys.argv) == 4:
    fade_in = int(sys.argv[2])
    fade_out = int(sys.argv[3])

res = sys.argv[1]
try:
    fin = open( res, "r" )
except IOError:
    print "Open file [%s] failed!\n" % res
    exit

for line in fin.readlines():
    line = line.strip()
    arr = line.split()
    filename = arr[0]
    intervals = arr[1:]
    intervals = [ int(x) for x in intervals  ]

    try:
        f = open( filename , "rb" )
    except IOError:
        print "Open file [%s] failed!\n" % filename
        fin.close()
        exit
    data = f.read()
    f.close()

    offset = 0
    if data[:4] == 'RIFF':
        offset = 44
    data = data[offset:]
    filelen_ms = int( len(data) / 32)

    ### seg bigfile
    filepath, filename_all = os.path.split(filename)
    filename_base, fileext = os.path.splitext(filename_all)
    #print "seg file [%s] into dir [%s]" %(filename,sys.argv[4])
    assert( len(intervals) % 2 == 0 )
    total_seg = len(intervals) / 2
    postfix_len = len(str(total_seg))
    for i in range( 0, len(intervals), 2 ):  # one sub file
        count = i/2 + 1
	fileout_temp = "%s{0}-{1:0{2}d}.wav" % sys.argv[4]
        fileout = fileout_temp.format(filename_base, count, postfix_len)
        #print fileout, intervals[i], intervals[i+1]
        if intervals[i] - fade_in < 0:
            intervals[i] = 0
        elif ( i > 1 and intervals[i] - intervals[i-1] < fade_in ):
            intervals[i] = intervals[i] - int( (intervals[i] - intervals[i-1]) * 2 / 3 )
        else:
            intervals[i] = intervals[i] - fade_in

        if intervals[i+1] + fade_out > filelen_ms:
            intervals[i+1] = filelen_ms
        elif ( i+1 < len(intervals)-1 and intervals[i+2] - intervals[i+1] < fade_out ):
            intervals[i+1] = intervals[i+1] + int( (intervals[i+2] - intervals[i+1]) * 2 / 3 )
        else:
            intervals[i+1] = intervals[i+1] + fade_out

        start = intervals[i] * 16 * 2  # 1ms -> 16samples -> 32bytes(char)
        end = intervals[i+1] * 16 * 2

        try:
            pcm = struct.unpack('<%dh' % ((end-start)/2), data[start:end])
            with sf.SoundFile(fileout,'w',16000,1) as f:
                f.write(np.array(pcm,dtype=np.int16))
        except IOError:
            print "Open file [%s] failed!\n" % fileout
            fin.close()
            exit
fin.close()
