# Sorcerer

Sorcerer is a source finding tool for astronomical radio images, which are otherwise dominated by Gaussian noise.

## Overview

Sorcerer uses a type of threshold algorithm that operates at varying grid sizes. For a given grid size, if the median brightness of a tile is greater than a threshold value, the tile is marked as representing a source. Given the known characteristics of Gaussian noise, we can search at lower and lower thresholds as the grid size is increased, whilst avoiding false positives.

Sorcerer is therefore well suited for both small bright sources as well as larger, and more diffuse faint sources.

### Example

**Below:** Source detections from the [ATLBS radio survey](http://www.rri.res.in/atlbs/) at 1.4 GHz. This was created using the following configuration:

        sorcerer --grid 40 8 --grid 30 10 --grid 24 12 --grid 16 8 --grid 12 6 --grid 8 8 --grid 4 4 --sensitivity 12 High_resolution_region_A.fits

<a style="display: block; float: left; margin: 0 5px" href="https://raw.githubusercontent.com/torrance/sorcerer/master/examples/example1.png">
        <img alt="Example of point source detections" width=280px src="https://raw.githubusercontent.com/torrance/sorcerer/master/examples/example1.png" />
</a>
<a style="display: block; float: left; margin: 0 5px" href="https://raw.githubusercontent.com/torrance/sorcerer/master/examples/example2.png">
        <img alt="Example of both point and diffuse source detections" width=280px src="https://raw.githubusercontent.com/torrance/sorcerer/master/examples/example2.png" />
</a>
<a style="display: block; float: left; margin: 0 5px" href="https://raw.githubusercontent.com/torrance/sorcerer/master/examples/example3.png">
        <img alt="Example of diffuse source detection" width=280px src="https://raw.githubusercontent.com/torrance/sorcerer/master/examples/example3.png" />
</a>
<div style="clear: both;"></div>

## Installing

Sorcerer requires **Python 3.4+.**

For now, installation is directly from Github:

        pip install git+https://github.com/torrance/sorcerer.git

Installation requires Cython and a suitable C compiler, such as GCC.

## Usage

For full configuration options, see the output `sorcerer --help`.

The two most important settings are `--grid` and `--sensitivity`.

The setting `--grid` accepts a pair of (positive) integers, the first of which denotes the grid size and the second denotes the overlap. The overlap value creates additional grids of the same size, but offset slightly. For example, the pair (12, 4) will create 4 overlapping grids of size 12px by 12px. Each grid is offset as evenly as possible, and in this case each grid would be offset by 3px. Ideally the overlap will divide the grid size.

You can provide multiple grid parameters. Ideally the grid sizes will span the anticipated sizes of your sources. Grid sizes much below your beam size are not recommend.

The setting `--sensitivity` controls the threshold values used at each grid size; threshold units are in standard deviations above the background mean. We define `p = 1 / 10^(sensitivity)`, where `p` is correlated with the probability of a tile having a median above a certain value. We determine the threshold for a particular grid size as the lowest threshold for which the the median probability is lower than `p`.

Put simply, increasing `--sensitivity` will reduce the number of sources detected, but also result in fewer false positives.

Sorcerer outputs both a catalog CSV and a KVIS annotation file in the current directory, `<filename>-sorcerer.{ann,csv}`.

Optionally, Sorcerer can output a highly compressed FITS file of the original image containing _only_ the sources. By passing `--cutout`, this file will be created at `<filename>-sorcerer.fits.{xz,gz}`. See `--help` for additional cutout configuration options.

### Examples:

> Search at multiple grid sizes:
>
>         sorcerer --grid 30 15 --grid 12 4 --grid 6 6 --sensitivity 15 image.fits

> Overwrite existing sorcerer catalog and annotation files:
>
>        sorcerer --grid 60 15 --grid 6 6 --sensitivity 12 --clobber image.fits

> Restrict sorcerer to runnning on just one CPU core:
>
>        sorcerer --grid 24 6 --grid 12 3 --sensitivity 24 --workers 1 image.fits

## Feedback

Sorcerer is in active development. Any questions/bugs/suggestions, please open an issue on Github at https://github.com/torrance/sorcerer