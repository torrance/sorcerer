#cython: language_level=3, boundscheck=False, wraparound=False

import numpy as np

cimport cython
cimport numpy as np


cdef class ThresholdIntegral:
    def __init__(self, np.ndarray img, double threshold):
        self.X = img.shape[1]
        self.Y = img.shape[0]
        self.threshold = threshold

        iimg = np.zeros((self.Y + 1, self.X + 1), dtype=np.int)
        iimg[1:, 1:] = img >= threshold
        iimg.cumsum(axis=0, out=iimg)
        iimg.cumsum(axis=1, out=iimg)
        self.iimg = iimg

    cdef int count(self, int x1, int y1, int x2, int y2):
        return self.iimg[y2, x2] + self.iimg[y1, x1] - self.iimg[y1, x2] - self.iimg[y2, x1]
