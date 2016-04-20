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
from tempfile import NamedTemporaryFile

import numpy as np
from netCDF4 import Dataset
from cfmeta import Cmip5File, Cmip3File
from cdo import Cdo

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

def var_trans(variable):
    # Returns additional variable specific commands
    if variable == 'pr':
        return '-mulc,86400'
    return ''

def create_climo_file(fp_in, fp_out, t_start, t_end, variable):
    '''
    Generates climatological files from an input file and a selected time range
    Paramenters:
        f_in: input file path
        f_out: output file path
        t_start (datetime.datetime): start date of climo period
        t_end (datetime.datetime): end date of climo period
        variable (str): name of the variable which is being processed
    Requested date range MUST exist in the input file
    '''
    supported_vars = {'tasmin', 'tasmax', 'pr'}

    if variable not in supported_vars:
        raise Exception("Unsupported variable: cant't yet process {}".format(variable))

    # Allow different ops by variable? # op = 'sum' if variable == 'pr' else 'mean'
    op = 'mean'

    cdo = Cdo()
    date_range = '{},{}'.format(d2s(t_start), d2s(t_end))

    if not os.path.exists(os.path.dirname(fp_out)):
        os.makedirs(os.path.dirname(fp_out))

    with NamedTemporaryFile(suffix='.nc') as tempf:
        cdo.seldate(date_range, input=fp_in, output=tempf.name)

        # Add extra postprocessing for specific variables.
        vt = var_trans(variable)

        if 'yr' in fp_in:
            cdo_cmd = '{vt} -tim{op} {fname}'.format(fname=tempf.name, op=op, vt=vt)
        else:
            cdo_cmd = '{vt} -ymon{op} {fname} {vt} -yseas{op} {fname} {vt} -tim{op} {fname}'\
                .format(fname=tempf.name, op=op, vt=vt)

        cdo.copy(input=cdo_cmd, output=fp_out)

def main(args):
    with open(args.input, 'r') as f:
        file_list = f.read().splitlines()

    for fp in file_list:
        log.info(fp)

        nc = Dataset(fp)
        available_climo_periods = determine_climo_periods(nc)
        nc.close()
        cf = Cmip5File(datanode_fp = fp)
        cf3 = Cmip3File(**cf.__dict__)
        variable = cf3.variable_name

        for _, t_range in available_climo_periods.items():
            log.info('Generating climo period %s to %s', d2s(t_range[0]), d2s(t_range[1]))

            climo_range = '{}-{}'.format(d2y(t_range[0]), d2y(t_range[1]))
            cf3.update(temporal_subset = climo_range)
            out_fp = os.path.join(args.outdir, cf3.fname)

            try:
                create_climo_file(fp, out_fp, t_range[0], t_range[1], variable)
            except KeyboardInterrupt:
                exit(1)
            except:
                log.exception('Failed to create climatology file')


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('-i', '--input', help='Input file list')
    parser.add_argument('-o', '--outdir', help='Output directory')
    args = parser.parse_args()

    logging.basicConfig(level=logging.INFO)

    main(args)
