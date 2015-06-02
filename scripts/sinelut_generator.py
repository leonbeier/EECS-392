#!/usr/bin/env python

import math

def sinelut_generator(start, end, n):
  n = int(n)
  if n > 0:
    diff = (end-start)/float(n+1)
    lut = [0.0]*n
    for i in range(n):
      lut[i] = math.sin(start + diff*(i+1))
    return lut
  else: return []

if __name__ == '__main__':
  slut = sinelut_generator(0, math.pi, 0.01)
  print slut
