import os.path
import time
import subprocess

t = os.path.getmtime('.')
while True:
    t2 = os.path.getmtime('.')
    if t2 > t:
        print('Compiling')
        subprocess.call(['coffee', '-cb', '.', '-d', '../js'])
        t = os.path.getmtime('.')
    time.sleep(1)
