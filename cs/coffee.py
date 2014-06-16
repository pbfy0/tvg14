import os.path
import time
import subprocess
import glob

def getmtime():
	return max(os.path.getmtime(x) for x in glob.glob('*.coffee'))

t = getmtime()
while True:
    t2 = getmtime()
    if t2 > t:
        print('Compiling')
        subprocess.call('coffee -c -o ..'+ os.path.sep + 'js .', shell=True)
        t = getmtime()
    time.sleep(1)
