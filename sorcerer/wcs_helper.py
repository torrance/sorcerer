from astropy import wcs
import numpy as np


class WCSHelper:
    def __init__(self, header):
        self.header = header
        self.wcs = wcs.WCS(header=header, naxis=2)

    def beamarea_pix(self):
        """
        Returns the area of the beam in pixels squared,
        taking into account the special 4 ln(2) factor.
        """
        beamsigma1 = self.header['BMAJ'] / self.wcs.wcs.cdelt[0]
        beamsigma2 = self.header['BMIN'] / self.wcs.wcs.cdelt[0]
        return (np.pi * beamsigma1 * beamsigma2) / (4 * np.log(2))

    def pix2world(self, pixel):
        return self.wcs.all_pix2world([pixel], 0)[0]
