from sorcerer.iimg cimport ThresholdIntegral


def searcher(ThresholdIntegral iimg, int grid, origin):
    return _searcher(iimg, grid, origin[0], origin[1])


cdef _searcher(ThresholdIntegral iimg, int grid, int xorigin, int yorigin):
    boxes = []
    total = grid * grid

    for x in range(xorigin, iimg.X - grid, grid):
        for y in range(yorigin, iimg.Y - grid, grid):
            gridsum = iimg.count(x, y, x + grid, y + grid)

            if (gridsum / total) >= 0.5:
                boxes.append((x, y, x + grid, y + grid))

    return boxes
