#!/usr/bin/env python

import os
import sys
import logging
import argparse
import multiprocessing
import fnmatch
import json

from collections import defaultdict
from datetime import datetime

import numpy as np
from netCDF4 import Dataset
from cfmeta import Cmip5File, Cmip3File

from pyclimate import Consumer
from pyclimate.nchelpers import *

log = logging.getLogger(__name__)

def s2d(s):
    return datetime.strptime(s, '%Y-%m-%d')

def ss2d(s):
    return datetime.strptime(s, '%Y%m%d')

def d2s(d):
    return datetime.strftime(d, '%Y-%m-%d')

def d2ss(d):
    return datetime.strftime(d, '%Y%m%d')

def d2y(d):
    return datetime.strftime(d, '%Y')

climo_periods = {
    '6190': [s2d('1961-01-01'),s2d('1990-12-31')],
    '2020': [s2d('2010-01-01'),s2d('2039-12-31')],
    '2050': [s2d('2040-01-01'),s2d('2069-12-31')],
    '2080': [s2d('2070-01-01'),s2d('2099-12-31')]
}

def determine_climo_periods(nc):
    '''
    Determine what climatological periods are available in a given netCDF file
    '''

    # Detect which climatological periods can be created
    time_var = nc.variables['time']
    s_date = num2date(time_var[0], units=time_var.units, calendar=time_var.calendar)
    e_date = num2date(time_var[-1], units=time_var.units, calendar=time_var.calendar)

    return dict([(k, v) for k, v in climo_periods.items() if v[0] > s_date and v[1] < e_date])


def main(args):
    with open(args.input, 'r') as f:
        file_list = f.read().splitlines()

    for fp in file_list:
        log.info(fp)

        nc = Dataset(fp)
        available_climo_periods = determine_climo_periods(nc)
        nc.close()
        cf = Cmip5File(datanode_fp = fp)

        for _, t_range in available_climo_periods.items():
            log.info('Generating climo period %s to %s', d2s(t_range[0]), d2s(t_range[1]))
            cf3 = Cmip3File(**cf.__dict__)

            climo_range = '{}-{}'.format(d2y(t_range[0]), d2y(t_range[1]))
            cf3.update(temporal_subset = climo_range)
            log.info(cf3.fname)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('-i', '--input', help='Input file list')
    parser.add_argument('-o', '--outdir', help='Output directory')
    args = parser.parse_args()

    logging.basicConfig(level=logging.INFO)

    main(args)
