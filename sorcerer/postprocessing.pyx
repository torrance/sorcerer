#cython: language_level=3, boundscheck=False, wraparound=False

import numpy as np

cimport numpy as np
from sorcerer.boxset cimport Box, BoxSet, Tree


def merge(boxes, shape, overlap_factor):
    print("Merging {} boxes...".format(len(boxes)))
    boxsets = _merge(boxes, shape[1], shape[0], overlap_factor)
    print("Merging complete: {} boxes remain".format(len(boxsets)))
    return boxsets


cdef _merge(object boxes, int X, int Y, double overlap_factor):
    cdef Tree tree = Tree(0, 0, X, Y)

    cdef Box box
    cdef BoxSet primary, candidate
    for box in boxes:
        candidates = tree.find(box, overlap_factor)

        if candidates:
            primary = candidates.pop()
            primary.append(box)

            for candidate in candidates:
                primary += candidate
                tree.remove(candidate)

            # Primary boxset has increased in size. Ensure tree categorises
            # it appropriately.
            tree.add(primary)
        else:
            tree.add(BoxSet(box))

    return tree.getall()

