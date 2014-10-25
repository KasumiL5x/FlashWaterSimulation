import glob
import subprocess
import os

PBUTIL_PATH = 'C:\\Program Files (x86)\\Adobe\\Adobe Utilities - CS5\\Pixel Bender Toolkit 2\\pbutil.exe'

def main():
	count = 0
	for curr_file in glob.glob('*.pbk'):
		filename = os.path.splitext(curr_file)[0]
		new_file = filename + '.pbj'
		args = [PBUTIL_PATH, curr_file, new_file]
		print 'Compiling ' + curr_file
		if subprocess.call(args) is not 0:
			print 'Error, stopping.'
			raw_input() # Don't close the window.
			return
		count += 1

	print 'Finished compiling ' + str(count) + ' shaders.'

if __name__ == '__main__':
	main()
