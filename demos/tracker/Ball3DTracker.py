#!/usr/bin/env python

import cv2
import numpy as np
from Tracker import Tracker
from Filter import ThresholdFilter, KalmanFilter
from Algorithm import Centroid
from math import *

class Line():
  
  def __init__(self, vector=[0., 0., 0.], point=[0., 0., 0.]):
    self.vector = vector
    self.point = point
  
  def __repr__(self):
    s = ''
    xs, ys, zs = [float(i) for i in self.vector]
    xp, yp, zp = [float(i) for i in self.point]
    s += '<%2f, %2f, %2f>s + <%2f, %2f, %2f>' % (xs, ys, zs, xp, yp, zp)
    return s
  
  def __add__(self, l2):
    t = Line()
    t.vector = [self.vector[i]+l2.vector[i] for i in range(len(self.vector))]
    t.point = [self.point[i]+l2.point[i] for i in range(len(self.point))]
    return t
  
  def __sub__(self, l2):
    t = Line()
    t.vector = [self.vector[i]-l2.vector[i] for i in range(len(self.vector))]
    t.point = [self.point[i]-l2.point[i] for i in len(range(self.point))]
    return t
  
  def normalize(self):
    n = Line.norm(self)
    if n != 0:
      self.vector = [float(v)/n for v in self.vector]
  
  @staticmethod
  def norm(l):
    return sqrt(sum([i*i for i in l.vector]))
  
  @staticmethod
  def dot(l1, l2):
    if (len(l1.vector) != len(l2.vector)): return 0.
    return sum([l1.vector[i]*l2.vector[i] for i in range(len(l1.vector))])
  
  @staticmethod
  def cross(l1, l2):
    l = Line()
    l.vector = [(l1.vector[1]*l2.vector[2]-l1.vector[2]*l2.vector[1]), \
                (l1.vector[2]*l2.vector[0]-l1.vector[0]*l2.vector[2]), \
                (l1.vector[0]*l2.vector[1]-l1.vector[1]*l2.vector[0])]
    return l
  
  @staticmethod
  def point_between_lines(l1, l2):
    # Taken from http://geomalgorithms.com/a07-_distance.html
    w = Line.cross(l1, l2)
    a = Line.dot(l1, l1)
    b = Line.dot(l1, l2)
    c = Line.dot(l2, l2)
    d = Line.dot(l1, w)
    e = Line.dot(l2, w)
    f = float(a*c-b*b)
    threshold = 1e-8
    if abs(f) > threshold:
      sc = float(b*e-c*d)/f
      tc = float(a*e-b*d)/f
    else:
      sc = 0.
      tc = 0.
    l = Line()
    l.vector = [sc*l1.vector[i]-tc*l2.vector[i] for i in range(len(l1.vector))]
    l.normalize()
    w_norm = Line.norm(w)
    l.vector = [w_norm*v for v in l.vector]
    l.point = [l2.point[i]-l1.point[i] for i in range(len(l1.point))]
    return [l.point[i]+l.vector[i] for i in range(len(l.vector))]

class Ball3DTracker():
  
  def __init__(self, algorithm):
    self.threshold_filter = ThresholdFilter( np.array([24, 125, 100], dtype=np.uint8), np.array([36, 255, 255], dtype=np.uint8) )
    self.algo = algorithm()
    
    # Camera Setups
    self.left_tracker = Tracker(1)
    self.right_tracker = Tracker(2)
    self.horizontal_fov = 120.0
    self.vertical_fov = 60.0
    self.d = 100
    
    self.centroid_algo = Centroid()
    self.left_transformed_image = np.copy( self.left_tracker.image )
    self.right_transformed_image = np.copy( self.right_tracker.image )
    
    self.valid = True
  
  def captureImageFrame(self):
    self.left_tracker.captureImageFrame()
    self.right_tracker.captureImageFrame()
    self.valid = self.left_tracker.valid and self.right_tracker.valid
    if self.valid:
      de_kernel = np.ones([3,3], dtype=np.uint8)
      
      self.left_transformed_image = np.copy( self.left_tracker.image )
      self.left_transformed_image = cv2.resize(self.left_transformed_image, (0,0), self.left_transformed_image, 0.5, 0.5, cv2.INTER_LANCZOS4)
      self.left_transformed_image = cv2.GaussianBlur(self.left_transformed_image, (9,9), 2, self.left_transformed_image, 2)
      self.left_transformed_image = cv2.cvtColor(self.left_transformed_image, cv2.COLOR_BGR2HSV)
      self.left_transformed_image = self.threshold_filter(self.left_transformed_image)
      self.left_transformed_image = cv2.erode(self.left_transformed_image, de_kernel, iterations=1)
      self.left_transformed_image = cv2.dilate(self.left_transformed_image, de_kernel, iterations=1)
      self.left_tracker.centroid = self.centroid_algo(self.left_transformed_image)
      self.left_transformed_image = cv2.cvtColor(self.left_transformed_image, cv2.cv.CV_GRAY2BGR)
      lds_centroid = self.left_tracker.centroid[:]
      self.left_tracker.centroid = tuple([2*i for i in self.left_tracker.centroid])
      cv2.circle(self.left_transformed_image, lds_centroid, 2, (255, 0, 0), -1)
      cv2.circle(self.left_tracker.image, self.left_tracker.centroid, 2, (255, 0, 0), -1)
      
      self.right_transformed_image = np.copy( self.right_tracker.image )
      self.right_transformed_image = cv2.resize(self.right_transformed_image, (0,0), self.right_transformed_image, 0.5, 0.5, cv2.INTER_LANCZOS4)
      self.right_transformed_image = cv2.GaussianBlur(self.right_transformed_image, (9,9), 2, self.right_transformed_image, 2)
      self.right_transformed_image = cv2.cvtColor(self.right_transformed_image, cv2.COLOR_BGR2HSV)
      self.right_transformed_image = self.threshold_filter(self.right_transformed_image)
      self.right_transformed_image = cv2.erode(self.right_transformed_image, de_kernel, iterations=1)
      self.right_transformed_image = cv2.dilate(self.right_transformed_image, de_kernel, iterations=1)
      self.right_tracker.centroid = self.centroid_algo(self.right_transformed_image)
      self.right_transformed_image = cv2.cvtColor(self.right_transformed_image, cv2.cv.CV_GRAY2BGR)
      rds_centroid = self.right_tracker.centroid[:]
      self.right_tracker.centroid = tuple([2*i for i in self.right_tracker.centroid])
      cv2.circle(self.right_transformed_image, rds_centroid, 2, (255, 0, 0), -1)
      cv2.circle(self.right_tracker.image, self.right_tracker.centroid, 2, (255, 0, 0), -1)
      
      midpoint = self.compute_transform()
      print midpoint
  
  def compute_transform(self):
    # NOT CURRENTLY VALID DATA
    l_centroid = self.left_tracker.centroid
    r_centroid = self.right_tracker.centroid
    
    # Compute the camera sizes
    l_width = self.left_tracker.image.shape[0]
    l_height = self.left_tracker.image.shape[1]
    r_width = self.left_tracker.image.shape[0]
    r_height = self.left_tracker.image.shape[1]
    
    # Compute euler angles
    theta_l = ((float(l_centroid[0])/l_width)-0.5)*self.horizontal_fov
    phi_l = ((float(l_centroid[1])/l_height)-0.5)*self.vertical_fov
    theta_r = ((float(r_centroid[0])/r_width)-0.5)*self.horizontal_fov
    phi_r = ((float(r_centroid[1])/r_height)-0.5)*self.vertical_fov
    
    left_line = Line([sin(theta_l), cos(theta_l)*cos(phi_l), sin(theta_l)*cos(phi_l)], [0., -float(self.d)/2., 0.])
    right_line = Line([sin(theta_r), cos(theta_r)*cos(phi_r), sin(theta_r)*cos(phi_r)], [0., float(self.d)/2., 0.])
    
    midpoint = Line.point_between_lines(left_line, right_line)
    return midpoint

if __name__ == '__main__':
  # Ball Tracker Tests
  b3dt = Ball3DTracker(Centroid)
  while cv2.waitKey(1) == -1 and b3dt.valid:
    cv2.imshow("Left Original Image", b3dt.left_tracker.image)
    cv2.imshow("Left Transformed Image", b3dt.left_transformed_image)
    cv2.imshow("Right Original Image", b3dt.right_tracker.image)
    cv2.imshow("Right Transformed Image", b3dt.right_transformed_image)
    b3dt.captureImageFrame()
  cv2.destroyAllWindows()
