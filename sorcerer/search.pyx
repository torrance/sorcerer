from sorcerer.iimg cimport ThresholdIntegral


def searcher(ThresholdIntegral iimg, int grid, int origin):
    return _searcher(iimg, grid, origin)


cdef _searcher(ThresholdIntegral iimg, int grid, int origin):
    boxes = []
    total = (grid - 1) * (grid - 1)

    for x in range(origin, iimg.X - grid, grid):
        for y in range(origin, iimg.Y - grid, grid):
            gridsum = iimg.count(x, y, x + grid, y + grid)

            if (gridsum / total) >= 0.5:
                boxes.append((x, y, x + grid, y + grid))

    return boxes
