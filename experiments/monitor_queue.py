# Monitor the number of packets sent and dropped at rh

from time import sleep, time
from subprocess import *
import re

default_dir = '.'

def monitor_qlen(interval_sec=0.01):
  pat_queued =re.compile(r'backlog\s[^\s]+\s([\d]+)p')
  dropped = re.compile(r"Sent\s([\d]+)\sbytes\s([\d]+)\spkt\s\(dropped\s([\d]+)")#dropped ([0-9]+),", re.S)
  cmd = "tc -s qdisc show dev rh-eth1"
  ret = []
  open("queue.txt","w").write('')
  t0 = "%f" % time()
  while 1:
    p = Popen(cmd, shell=True, stdout=PIPE)
    output = p.stdout.read()
    matches = pat_queued.findall(output)
    matched_dropped = dropped.findall(output)
    t1 = "%f" % time()
    print str(float(t1)-float(t0)), matched_dropped[0][1], matched_dropped[0][2] #[1], matched_dropped[2]
    open("queue.txt","a").write(str(float(t1)-float(t0))+' '+matched_dropped[0][1]+' ' + matched_dropped[0][2] + '\n')
    sleep(interval_sec)

monitor_qlen()

