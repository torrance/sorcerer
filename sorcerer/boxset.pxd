cdef class BoxSet:
    cdef public int id
    cdef public object boxes
    cdef public int bounds[4]

    cpdef void append(self, object box)
    cpdef int overlap(self, object otherbox, double overlap_factor)