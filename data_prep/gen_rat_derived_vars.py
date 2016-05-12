#!/usr/bin/env python


import os
import logging
import argparse
import shutil

from collections import defaultdict
from tempfile import NamedTemporaryFile

from netCDF4 import Dataset
from cfmeta import Cmip5File

from util import d2y, determine_climo_periods
from climos import create_climo_file
from derived_vars import tas, hdd, gdd, ffd, pas

log = logging.getLogger(__name__)

def copy_input_vars_to_temp(variable_set):
    tempfiles = {}
    for varname, fp in variable_set.items():
        tempfiles[varname] = NamedTemporaryFile(suffix='.nc')
        shutil.copy2(fp, tempfiles[varname])
    return tempfiles

def close_tempfiles(tempfiles):
    for varname, tempf in tempfiles.items():
        tempf.close()

def main(args):
    log.info('Reading input file list %s', args.input)
    with open(args.input, 'r') as f:
        file_list = f.read().splitlines()

    model_sets = defaultdict(dict)
    for fp in file_list:
        cf = Cmip5File(datanode_fp = fp)
        key = '{}_{}_{}'.format(cf.model, cf.experiment, cf.ensemble_member)

        model_sets[key][cf.variable_name] = fp

    for model_experiment_member, variable_set in model_sets.items():
        log.debug(variable_set)

        # Copy input to $TMPDIR
        log.info('Copying input to temp %s', variable_set)
        tempfiles = copy_input_vars_to_temp(variable_set)
        log.debug(tempfiles)
        
        # Extract base metadata from an input file to set output file paths later
        cf = Cmip5File(datanode_fp = next(dictionary.itervalues()))

        # Generate derived vars
        for func in [tas, hdd]:
            # Store derived daily var in tempfile
            with NamedTemporaryFile(suffix='.nc') as temp_daily:
                varname = func(tempfiles, temp_daily.name)
                nc = Dataset(temp_daily.name)
                available_climo_periods = determine_climo_periods(nc)
                nc.close()

                for _, t_range in available_climo_periods.items():
                    temp_climo = NamedTemporaryFile(suffix='.nc')

                    climo_range = '{}-{}'.format(d2y(t_range[0]), d2y(t_range[1]))
                    log.info('Generating climo period %s to %s', climo_range, temp_out.name)

                    # Alter relevant info
                    cf.update(variable_name = varname, mip_table = 'Amon', temporal_subset = climo_range)

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


        # Close tempfiles (auto deleted)
        close_tempfiles(tempfiles)

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('-i', '--input', help='Input file list')
    parser.add_argument('-o', '--outdir', help='Output directory')
    parser.add_argument('-v', '--verbosity', default=0, action='count', help='Increase log level. -v = INFO, -vv = DEBUG')
    args = parser.parse_args()

    level = logging.ERROR
    if args.verbosity > 1:
        level = logging.DEBUG
    elif args.verbosity == 1:
        level = logging.INFO
    logging.basicConfig(level=level)

    main(args)
