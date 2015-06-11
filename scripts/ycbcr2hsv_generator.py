#!/usr/bin/env python

import cv2
import numpy as np
from image_serializer import *

if __name__ == '__main__':
  lena = cv2.imread('392.png')
  lena_rgb = cv2.cvtColor(lena, cv2.COLOR_BGR2RGB)
  lena_ycbcr = cv2.cvtColor(lena, cv2.COLOR_BGR2YCR_CB)
  lena_ycbcr[:,:,1], lena_ycbcr[:,:,2] = np.copy(lena_ycbcr[:,:,2]), np.copy(lena_ycbcr[:,:,1])
  lena_hsv = cv2.cvtColor(lena, cv2.COLOR_BGR2HSV)
  ycbcr_serialized = serialize_image(lena_ycbcr)
  hsv_serialized = serialize_image(lena_hsv)
  rgb_serialized = serialize_image(lena_rgb)
  with open('ycbcr2hsv_input.txt', 'w+') as f:
    f.write(ycbcr_serialized)
  with open('ycbcr2hsv_output.txt', 'w+') as f:
    f.write(hsv_serialized)
  with open('final_input.txt', 'w+') as f:
    f.write(rgb_serialized)
  
  # Deserialization
  in_str = ''
  with open('ycbcr2hsv_modelsim.txt', 'r') as f:
    in_str = f.read()
  im_hsv = deserialize_image(in_str)
  im_bgr = cv2.cvtColor(im_hsv, cv2.COLOR_HSV2BGR)
  im_ycbcr = cv2.cvtColor(im_bgr, cv2.COLOR_BGR2YCR_CB)
  im_ycbcr[:,:,1], im_ycbcr[:,:,2] = np.copy(im_ycbcr[:,:,2]), np.copy(im_ycbcr[:,:,1])
  if im_hsv is not None:
    cv2.imshow('BGR', lena)
    cv2.imshow('BGR-Deserialized', im_bgr)
    cv2.imshow('HSV', lena_hsv)
    cv2.imshow('HSV-Deserialized', im_hsv)
    cv2.imwrite('dout_ycbcr.jpg', im_ycbcr)
    cv2.imwrite('dout_bgr.jpg', im_bgr)
    cv2.imwrite('lena_ycbcr.jpg', lena_ycbcr)
    cv2.imwrite('lena_hsv.jpg', lena_hsv)
    cv2.imwrite('dout_hsv.jpg', im_hsv)
    cv2.waitKey(0)
  else:
    print 'Error deserializing'
