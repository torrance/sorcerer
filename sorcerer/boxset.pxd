cdef class Tree:
    cdef public Box bounds
    cdef public Tree leaf1, leaf2
    cdef public object boxsets
    cdef public int is_leaf
    cdef void add(self, BoxSet boxset)
    cdef void remove(self, BoxSet boxset)
    cdef object find(self, Box box, double overlap_factor)
    cdef object getall(self)


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