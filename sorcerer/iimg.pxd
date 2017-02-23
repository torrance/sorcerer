cimport numpy as np


cdef class ThresholdIntegral:
    cdef public int X, Y
    cdef public double threshold
    cdef public np.ndarray iimg

    cdef public int count(self, int x1, int y1, int x2, int y2)