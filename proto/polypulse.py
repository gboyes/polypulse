import sys 
import os
import numpy as np

def inverseUnit(k, fs):
	return fs * 60.0 / k

def polyperiod(period, quant, tuplet, group):
	return ((period * quant) / tuplet) * group


def gcd(a, b):
	while b > 0:
		temp = b
		b = a % b
		a = temp
	return a

def lcm(a, b):
	return a * (b / gcd(a, b))

def lcm_(x):
	result = x[0]
	for i in range(len(x)):
		result = lcm(result, x[i])
	return result


def main(bpm):
	fs = 48000.0
	period = inverseUnit(bpm, fs)
	_bpm = inverseUnit(period, fs)
	print(period, _bpm)

	cycle = lcm_([24000, 23991, 23987])
	
	print("Will sync in %d beats"%(cycle / period))

	s = cycle /fs
	m = s / 60.0
	h = m / 60.0
	d = h / 24.0
	y = d / 365.0

	print("Will sync in %0.9fs\n%0.9fm\n%0.9fh\n%0.9fd\n%0.9fy\n"%(s, m, h, d, y))

if __name__ == '__main__':

	bpm = float(sys.argv[1])
	main(bpm)