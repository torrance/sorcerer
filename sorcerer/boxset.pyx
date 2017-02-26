#cython: language_level=3, boundscheck=False, wraparound=False

import cython
import numpy as np


cdef int uid = 0


cdef class BoxSet:
    def __cinit__(self, object box):
        global uid
        uid += 1

        self.id = uid
        self.boxes = [box]
        self.bounds[0] = box[0]
        self.bounds[1] = box[1]
        self.bounds[2] = box[2]
        self.bounds[3] = box[3]

    cpdef void append(self, object box):
        self.boxes.append(box)
        self.bounds[0] = min(self.bounds[0], box[0])
        self.bounds[1] = min(self.bounds[1], box[1])
        self.bounds[2] = max(self.bounds[2], box[2])
        self.bounds[3] = max(self.bounds[3], box[3])

    cpdef int overlap(self, object otherbox):
        if not overlap(self.bounds, otherbox):
            return 0

        for box in self.boxes:
            if overlap(box, otherbox):
                return 1

        return 0

    def __iadd__(self, other):
        for otherbox in other.boxes:
            self.append(otherbox)

        return self

    def center(self):
        width = self.bounds[2] - self.bounds[0]
        height = self.bounds[3] - self.bounds[1]
        return self.bounds[0] + width/2, self.bounds[1] + height / 2

    def window(self, grid, origin=(0, 0)):
        for x1, y1, x2, y2 in self.boxes:
            grid[y1-origin[1]:y2-origin[1], x1-origin[0]:x2-origin[0]] = True

        return grid

    def vertices(self):
        # Add a 1px border to the grid.
        grid = np.zeros((self.bounds[3]-self.bounds[1]+2, self.bounds[2]-self.bounds[0]+2),
                        dtype=np.bool)
        window = self.window(grid, origin=(self.bounds[0] - 1, self.bounds[1] - 1))

        right = (1, 0)
        left = (-1, 0)
        up = (0, 1)
        down = (0, -1)

        # Find initial vertex
        direction = right
        pos = (0, 1)
        while not window[pos[1], pos[0]]:
            pos = (pos[0] + direction[0], pos[1] + direction[1])

        # Now find the rest
        vertices = [pos]
        for _ in range(999):
            # Walk along perimeter until we find next vertex
            while perimeter((pos[0] + direction[0], pos[1] + direction[1]), window):
                pos = (pos[0] + direction[0], pos[1] + direction[1])

            vertices.append(pos)
            if vertices[0] == vertices[len(vertices) - 1]:
                break  # We've done a complete loop

            # Determine new direction to head in
            if direction == left or direction == right:
                newpos = (pos[0] + up[0], pos[1] + up[1])
                if perimeter(newpos, window):
                    direction = up
                else:
                    direction = down
            else:
                newpos = (pos[0] + right[0], pos[1] + right[1])
                if perimeter(newpos, window):
                    direction = right
                else:
                    direction = left
        else:
            raise VerticesException("Failed to calculate vertices for {}".format(self.id))

        # Correct for non-zero origin from adding the 1px border.
        vertices = [(vertex[0] + self.bounds[0] - 1, vertex[1] + self.bounds[1] - 1) for vertex in vertices]
        return vertices

    def annotation(self, wcs_helper):
        center = wcs_helper.pix2world(self.center())
        label = "TEXT {} {} {}".format(center[0], center[1], self.id)

        polygon = "CLINES"
        for vertex in self.vertices():
            x1, y1 = wcs_helper.pix2world(vertex)
            # Limit the accuracy of the floats to avoid bugs in KVIS Karma
            # caused by excessive line length in large, complex shapes.
            polygon += " {:.8f} {:.8f}".format(x1, y1)

        return [label, polygon]


def perimeter(pos, grid):
    result = (
        grid[pos[1], pos[0]]
        and not (
            grid[pos[1] + 1, pos[0] + 0]
            and grid[pos[1] + 1, pos[0] + 1]
            and grid[pos[1] + 0, pos[0] + 1]
            and grid[pos[1] - 1, pos[0] + 1]
            and grid[pos[1] - 1, pos[0] + 0]
            and grid[pos[1] - 1, pos[0] - 1]
            and grid[pos[1] + 0, pos[0] - 1]
            and grid[pos[1] + 1, pos[0] - 1]
        )
    )
    return result


cdef int overlap(a, b):
    # Todo: This doesn't doesn't work correctly for overlapping boxes
    # when none of their corners overlap.

    cdef int a0, a1, a2, a3
    cdef int b0, b1, b2, b3
    a0, a1, a2, a3 = a[0], a[1], a[2], a[3]
    b0, b1, b2, b3 = b[0], b[1], b[2], b[3]

    # Bottom left
    if (
        a0 <= b0 < a2
        and a1 <= b1 < a3
    ):
        return 1
    # Top right
    if (
        a0 <= b2 < a2
        and a1 <= b3 < a3
    ):
        return 1
    # Top left
    if (
        a0 <= b0 < a2
        and a1 <= b3 < a3
    ):
        return 1
    # Bottom right
    if (
        a0 <= b2 < a2
        and a1 <= b1 < a3
    ):
        return 1

    # Bottom left
    if (
        b0 <= a0 < b2
        and b1 <= a1 < b3
    ):
        return 1

    # Top right
    if (
        b0 <= a2 < b2
        and b1 <= a3 < b3
    ):
        return 1
    # Top left
    if (
        b0 <= a0 < b2
        and b1 <= a3 < b3
    ):
        return 1
    # Bottom right
    if (
        b0 <= a2 < b2
        and b1 <= a1 < b3
    ):
        return 1

    return 0


class VerticesException(Exception):
    pass
