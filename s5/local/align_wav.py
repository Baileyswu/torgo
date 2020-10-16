import soundfile as sf
import scipy.io.wavfile as wav
import argparse
import logging
logging.basicConfig(level=logging.INFO)
parser = argparse.ArgumentParser()
parser.add_argument("in1", help="array wav path")
parser.add_argument("in2", help="head wav path")
parser.add_argument("in3", help="shift frames to aligment", type=int)
parser.add_argument("out1", help="after cutting array wav")
parser.add_argument("out2", help="after cutting head wav")


args = parser.parse_args()
logging.debug(args.in1, args.in2, args.in3, args.out1, args.out2)

path_array = args.in1
path_head = args.in2
delta = args.in3
out_array = args.out1
out_head = args.out2

signal_array, fs_array = sf.read(path_array)
signal_head, fs_head = sf.read(path_head)
# fs_array, signal_array,  = wav.read(path_array)
# fs_head, signal_head = wav.read(path_head)

length_array = len(signal_array)
length_head = len(signal_head)

start_array = 0
start_head = 0

if delta > 0:
    length_array -= delta
    start_array = delta
else:
    length_head += delta
    start_head = -delta

length = min(length_array, length_head)
signal_array = signal_array[start_array: start_array+length]
signal_head = signal_head[start_head: start_head+length]

sf.write(out_array, signal_array, fs_array)
sf.write(out_head, signal_head, fs_head)
# wav.write(out_array, fs_array, signal_array)
# wav.write(out_head, fs_head, signal_head)