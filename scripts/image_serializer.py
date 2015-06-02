#!/usr/bin/env python

import cv2
import numpy as np

def serialize_image(im_in):
  out_str = ''
  out_str += str(im_in.shape[0]) + '\n'
  out_str += str(im_in.shape[1]) + '\n'
  for i in range(im_in.shape[0]):
    for j in range(im_in.shape[1]):
      for k in range(im_in.shape[2]):
        out_str += str(im_in[i, j, k]) + '\n'
  return out_str[:-1]

def deserialize_image(in_str):
  lines = filter(lambda x: x != '', in_str.split('\n'))
  im_out = None
  if len(lines) > 2:
    try:
      rows = int(lines[0])
      cols = int(lines[1])
      im_out = np.zeros((rows, cols, 3), np.uint8)
      row, col, depth = 0, 0, 0
      for p in lines[2:]:
        im_out[row, col, depth] = int(p)
        if depth == 2:
          depth = 0
          if col == cols-1:
            col = 0
            row += 1
          else:
            col += 1
        else:
          depth += 1
    except Exception, e:
      print e
      return None
  return im_out
