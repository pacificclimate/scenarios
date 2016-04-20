#!/usr/bin/env python

import os
import sys
import logging
import argparse
import multiprocessing
import fnmatch
import json

from collections import defaultdict

import numpy as np
from netCDF4 import Dataset
from cfmeta import Cmip5File

from pyclimate import Consumer
from pyclimate.nchelpers import *

log = logging.getLogger(__name__)

pcic12filter =  [{'model': x.split()[0], 'ensemble_member': x.split()[1], 'experiment': x.split()[2:]} for x in '''MPI-ESM-LR r3i1p1 historical rcp26 rcp45 rcp85
inmcm4 r1i1p1 historical rcp26 rcp45 rcp85
HadGEM2-ES r1i1p1 historical rcp26 rcp45 rcp85
CanESM2 r1i1p1 historical rcp26 rcp45 rcp85
MIROC5 r3i1p1 historical rcp26 rcp45 rcp85
CSIRO-Mk3-6-0 r1i1p1 historical rcp26 rcp45 rcp85
MRI-CGCM3 r1i1p1 historical rcp26 rcp45 rcp85
ACCESS1-0 r1i1p1 historical rcp26 rcp45 rcp85
CNRM-CM5 r1i1p1 historical rcp26 rcp45 rcp85
CCSM4 r2i1p1 historical rcp26 rcp45 rcp85
HadGEM2-CC r1i1p1 historical rcp26 rcp45 rcp85
GFDL-ESM2G r1i1p1 historical rcp26 rcp45 rcp85'''.split('\n')]

def in_pcic12(cf):
    for entry in pcic12filter:
        if all([(hasattr(cf, att) and (getattr(cf, att) == val or getattr(cf, att) in val)) for att, val in entry.items()]):
            return True
    return False

def iter_netcdf_files(base_dir, pattern="*.nc"):
    for root, dirnames, filenames in os.walk(base_dir):
        for filename in fnmatch.filter(filenames, pattern):
            yield os.path.join(root, filename)

def iter_pcic12_cmip5_file(file_iter):
    for fp in file_iter:
        cf = Cmip5File(datanode_fp = fp)
        if in_pcic12(cf):
            yield fp

def main(args):
    netcdf_iter = iter_netcdf_files(args.indir)
    file_iter = iter_pcic12_cmip5_file(netcdf_iter)

    for fp in file_iter:
        print(fp)

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('indir', help='Input directory')
    args = parser.parse_args()

    logging.basicConfig(level=logging.INFO)

    main(args)
