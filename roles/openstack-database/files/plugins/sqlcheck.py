#!/usr/bin/python
import subprocess, string, sys

STATE_OK = 0
STATE_WARNING = 1
STATE_CRITICAL = 2

def main():
  try:
    msqlr = subprocess.Popen(['pgrep', '-cfl', '[m]ysqld'], stdout=subprocess.PIPE).stdout
    result = msqlr.read().strip()
    if result == '0':
      print "Error: MySQL is not running"
      sys.exit(STATE_CRITICAL)
    else:
      print "OK - MySQL is running."
      sys.exit(STATE_OK)
  except Exception as e:
    print "Error: %s" %e
    sys.exit(STATE_WARNING)

if __name__ == '__main__':
  main()
