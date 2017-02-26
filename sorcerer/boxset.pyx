#cython: language_level=3, boundscheck=False, wraparound=False

import cython
import numpy as np


cdef int uid = 0


cdef class Box:
    def __cinit__(self, int x1, int y1, int x2, int y2):
        self.x1 = x1
        self.y1 = y1
        self.x2 = x2
        self.y2 = y2

    def __reduce__(self):
        return (Box, (self.x1, self.y1, self.x2, self.y2))


cdef class BoxSet:
    def __cinit__(self, Box box):
        global uid
        uid += 1

        self.id = uid
        self.boxes = [box]
        self.bounds = box

    cpdef void append(self, Box box):
        self.boxes.append(box)
        self.bounds.x1 = min(self.bounds.x1, box.x1)
        self.bounds.y1 = min(self.bounds.y1, box.y1)
        self.bounds.x2 = max(self.bounds.x2, box.x2)
        self.bounds.y2 = max(self.bounds.y2, box.y2)

    cpdef int overlap(self, Box otherbox, double overlap_factor):
        if not overlap(self.bounds, otherbox, 0):
            return 0

        for box in self.boxes:
            if overlap(box, otherbox, overlap_factor):
                return 1

        return 0

    def __iadd__(self, BoxSet other):
        for otherbox in other.boxes:
            self.append(otherbox)

        return self

    def center(self):
        width = self.bounds.x2 - self.bounds.x1
        height = self.bounds.y2 - self.bounds.y1
        return self.bounds.x1 + width/2, self.bounds.y1 + height / 2

    def window(self, grid, origin=(0, 0)):
        for box in self.boxes:
            grid[box.y1-origin[1]:box.y2-origin[1], box.x1-origin[0]:box.x2-origin[0]] = True

        return grid

    def vertices(self):
        # Add a 1px border to the grid.
        grid = np.zeros((self.bounds.y2-self.bounds.y1+2, self.bounds.x2-self.bounds.x1+2),
                        dtype=np.bool)
        window = self.window(grid, origin=(self.bounds.x1 - 1, self.bounds.y1 - 1))

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
        vertices = [(vertex[0] + self.bounds.x1 - 1, vertex[1] + self.bounds.y1 - 1) for vertex in vertices]
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


cdef int overlap(Box a, Box b, double overlap_factor):
    # Todo: This doesn't doesn't work correctly for overlapping boxes
    # when none of their corners overlap.

    cdef double area
    area = (a.x2 - a.x1) * (a.y2 - a.y1)

    # Bottom left
    if (
        b.x1 <= a.x1 < b.x2
        and b.y1 <= a.y1 < b.y2
        and ((b.x2 - a.x1) * (b.y2 - a.y1)) / area >= overlap_factor
    ):
        return 1
    # Top right
    if (
        b.x1 <= a.x2 < b.x2
        and b.y1 <= a.y2 < b.y2
        and ((a.x2 - b.x1) * (a.y2 - b.y1)) / area >= overlap_factor
    ):
        return 1
    # Top left
    if (
        b.x1 <= a.x1 < b.x2
        and b.y1 <= a.y2 < b.y2
        and ((b.x2 - a.x1) * (a.y2 - b.y1)) / area >= overlap_factor
    ):
        return 1
    # Bottom right
    if (
        b.x1 <= a.x2 < b.x2
        and b.y1 <= a.y1 < b.y2
        and ((a.x2 - b.x1) * (b.y2 - a.y1)) / area >= overlap_factor
    ):
        return 1

    area = (b.x2 - b.x1) * (b.y2 - b.y1)

    # Bottom left
    if (
        a.x1 <= b.x1 < a.x2
        and a.y1 <= b.y1 < a.y2
        and ((a.x2 - b.x1) * (a.y2 - b.y1)) / area >= overlap_factor
    ):
        return 1
    # Top right
    if (
        a.x1 <= b.x2 < a.x2
        and a.y1 <= b.y2 < a.y2
        and ((b.x2 - a.x1) * (b.y2 - a.y1)) / area >= overlap_factor
    ):
        return 1
    # Top left
    if (
        a.x1 <= b.x1 < a.x2
        and a.y1 <= b.y2 < a.y2
        and ((a.x2 - b.x1) * (b.y2 - a.y1)) / area >= overlap_factor
    ):
        return 1
    # Bottom right
    if (
        a.x1 <= b.x2 < a.x2
        and a.y1 <= b.y1 < a.y2
        and ((b.x2 - a.x1) * (a.y2 - b.y1)) / area >= overlap_factor
    ):
        return 1

    return 0


class VerticesException(Exception):
    pass
