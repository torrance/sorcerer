#cython: language_level=3, boundscheck=False, wraparound=False

import numpy as np
from tqdm import tqdm

cimport numpy as np
from sorcerer.boxset cimport BoxSet


def merge(boxes):
    print("Merging (non-greedy) {} boxes...".format(len(boxes)))

    boxsets = []
    for box in tqdm(boxes):
        # Search for candidate groups for each box.
        # There may be multiple previoulsy separate groups
        # that a box bridges.
        candidates = []
        for i, boxset in enumerate(boxsets):
            if boxset.overlap(box):
                candidates.append(i)

        # This is important: we sort the candidates list
        # with the highest index first. This means when we delete
        # non-primary groups later, the indices of remaining non-primary
        # groups are unchanged.
        candidates = sorted(candidates, reverse=True)
        if candidates:
            primary = boxsets[candidates[0]]

            # First add the box to the primary group.
            primary.append(box)

            # Merge all other groups into the first
            # candidate group
            for candidate in candidates[1:]:
                boxset = boxsets[candidate]
                primary += boxset  # In place addition

                # Remove the uneeded group
                del boxsets[candidate]

        else:
            # Start its own group
            boxsets.append(BoxSet(box))

    print("Merging complete: {} boxes remain".format(len(boxsets)))
    return boxsets



