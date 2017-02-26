cdef class Box:
    cdef public int x1
    cdef public int y1
    cdef public int x2
    cdef public int y2


cdef class BoxSet:
    cdef public int id
    cdef public object boxes
    cdef public Box bounds

    cpdef void append(self, Box box)
    cpdef int overlap(self, Box otherbox, double overlap_factor)