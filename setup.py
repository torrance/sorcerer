from Cython.Build import cythonize
import numpy as np
from setuptools import Extension, setup


extensions = [
    Extension('sorcerer.boxset', ['sorcerer/boxset.pyx'], include_dirs=[np.get_include()]),
    Extension('sorcerer.iimg', ['sorcerer/iimg.pyx'], include_dirs=[np.get_include()]),
    Extension('sorcerer.postprocessing', ['sorcerer/postprocessing.pyx'], include_dirs=[np.get_include()]),
    Extension('sorcerer.search', ['sorcerer/search.pyx'], include_dirs=[np.get_include()]),
]


setup(
    name='sorcerer',
    description='A source finding tool, for locating and characterising sources in radio images.',
    url='https://github.com/torrance/sorcerer',
    author='Torrance Hodgson',
    author_email='torrance123@gmail.com',
    license='GPLv3',
    classifiers=[
        'Development Status :: 3 - Alpha',
        'Programming Language :: Python :: 3',
    ],
    keywords='radio astronomy sources noise',
    packages=['sorcerer'],
    install_requires=[
        'astropy',
        'cython',
        'numpy',
        'scipy',
    ],
    scripts=['scripts/sorcerer'],
    ext_modules=cythonize(extensions),
)