import csv

from astropy.io import fits
import numpy as np
import numpy.ma as ma

from sorcerer.boxset import VerticesException


def write_catalog(boxsets, img, wcs_helper, f):
    print("Writing catalog file: {}".format(f.name))

    writer = csv.writer(f)
    writer.writerow(['ID', 'x', 'y', 'x1', 'y1', 'x2', 'y2', 'Total Flux', 'Integrated Flux',
                     'Peak Flux', 'Peak Flux (95 Percentile)'])
    writer.writerow(['', '(degrees)', '(degrees)', '(degrees)', '(degrees)',
                     '(degrees)', '(degrees)'])

    beamarea = wcs_helper.beamarea_pix()

    for boxset in boxsets:
        bounds = boxset.bounds
        X = bounds.x2 - bounds.x1
        Y = bounds.y2 - bounds.y1
        mask = np.zeros((Y, X), dtype=np.bool)
        mask = boxset.window(mask, origin=(bounds.x1, bounds.y1))
        source = ma.array(img[bounds.y1:bounds.y2, bounds.x1:bounds.x2],
                          mask=~mask).compressed()

        total_flux = source.sum()
        integrated_flux = total_flux / beamarea
        peak_flux = source.max()
        peak_flux95 = np.percentile(source, 95)

        x, y = wcs_helper.pix2world(boxset.center())
        x1, y1 = wcs_helper.pix2world([bounds.x1, bounds.y1])
        x2, y2 = wcs_helper.pix2world([bounds.x2, bounds.y2])

        writer.writerow([boxset.id, x, y, x1, y1, x2, y2, total_flux, integrated_flux,
                         peak_flux, peak_flux95])

    f.close()


def write_annotations(boxsets, wcs_helper, f):
    print("Writing to annotation file: {}".format(f.name))

    f.write('# KARMA ANNOTATION FILE\n')
    f.write('\n')
    f.write('COORD W\n')
    f.write('PA STANDARD\n')
    f.write('COLOR GREEN\n')
    f.write('\n')

    for boxset in boxsets:
        try:
            for line in boxset.annotation(wcs_helper):
                f.write(line + "\n")
        except VerticesException as e:
            print("WARNING: " + str(e))

    f.close()


def write_cutout(boxsets, hdu, margin, f):
    print("Creating compressed FITS file...")
    img = np.squeeze(hdu.data)
    header = hdu.header

    mask = np.zeros(img.shape, np.bool)
    for boxset in boxsets:
        boxset.window(mask)

    # Grow the mask:
    for _ in range(margin):
        # Shift up
        mask[1:, :] = np.logical_or(mask[1:, :], mask[0:-1, :])
        # Shift down
        mask[0:-1, :] = np.logical_or(mask[0:-1, :], mask[1:, :])
        # Shift right
        mask[:, 1:] = np.logical_or(mask[:, 1:], mask[:, 0:-1])
        # Shift left
        mask[:, 0:-1] = np.logical_or(mask[:, 0:-1], mask[:, 1:])

    img[~mask] = np.nan
    cutout = fits.PrimaryHDU(img)
    cutout.header = header.copy()
    cutout.update_header()

    cutout.writeto(f)
    f.close()
