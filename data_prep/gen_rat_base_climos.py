#!/usr/bin/env python

import os
import sys
import logging
import argparse
import multiprocessing
import fnmatch
import json
import shutil

from collections import defaultdict
from tempfile import NamedTemporaryFile

import numpy as np
from netCDF4 import Dataset
from cfmeta import Cmip5File

from util import d2y, determine_climo_periods
from climos import create_climo_file

log = logging.getLogger(__name__)

def main(args):
    log.info('Reading input file list %s', args.input)
    with open(args.input, 'r') as f:
        file_list = f.read().splitlines()

    model_sets = defaultdict(dict)
    for fp in file_list:
        cf = Cmip5File(datanode_fp = fp)
        key = '{}-{}-{}'.format(cf.model,cf.variable_name,cf.ensemble_member)
        model_sets[key][cf.experiment] = fp

    for model_var_run, experiment in model_sets.items():
        for experiment_name, fp in experiment.items():

            # Copy file to local temp
            with NamedTemporaryFile(suffix='.nc') as tempf, NamedTemporaryFile(suffix='.nc') as temp_out:
                log.info('Copying input fname %s to %s', fp, tempf.name)
                shutil.copy2(fp, tempf.name)

                nc = Dataset(tempf.name)
                available_climo_periods = determine_climo_periods(nc)
                nc.close()
                cf = Cmip5File(datanode_fp = fp)
                variable = cf.variable_name

                for _, t_range in available_climo_periods.items():
                    climo_range = '{}-{}'.format(d2y(t_range[0]), d2y(t_range[1]))
                    log.info('Generating climo period %s to %s', climo_range, temp_out.name)

                    try:
                        create_climo_file(tempf.name, temp_out.name, t_range[0], t_range[1], variable)
                    except KeyboardInterrupt:
                        exit(1)
                    except:
                        log.exception('Failed to create climatology file')

                    log.info('Copying result to output directory')
                    cf.update(temporal_subset = climo_range, mip_table = 'Amon')
                    out_fp = os.path.join(args.outdir, cf.cmor_fname)
                    shutil.copy2(temp_out.name, out_fp)

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('-i', '--input', help='Input file list')
    parser.add_argument('-o', '--outdir', help='Output directory')
    args = parser.parse_args()

    logging.basicConfig(level=logging.INFO)

    main(args)
