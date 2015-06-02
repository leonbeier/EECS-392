#!/usr/bin/env python

import cv2
import numpy as np
from image_serializer import deserialize_image

if __name__ == '__main__':
  # Deserialization
  in_str_orig = ''
  in_str_ms = ''
  with open('ycbcr2hsv_modelsim.txt', 'r') as f:
    in_str_ms = f.read()
  with open('ycbcr2hsv_output.txt', 'r') as f:
    in_str_orig = f.read()
  im_orig = deserialize_image(in_str_orig)
  im_ms = deserialize_image(in_str_ms)
  diff = im_orig - im_ms
  gray_diff = np.zeros(im_orig.shape, np.uint)
  for i in range(im_orig.shape[0]):
    for j in range(im_orig.shape[1]):
      v = int((diff[i,j,0]**2 + diff[i,j,1]**2 + diff[i,j,2]**2)**0.5)
      print v
      gray_diff[i,j] = v if v < 256 and v >= 0 else 256 if v >= 256 else 0
  cv2.imwrite('dout_diff.jpg', gray_diff)
