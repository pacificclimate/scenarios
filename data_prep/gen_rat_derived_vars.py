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
from derived_vars import derived_vars

log = logging.getLogger(__name__)

def copy_input_vars_to_temp(variable_set):
    tempfiles = {}
    for varname, fp in variable_set.items():
        tempfiles[varname] = NamedTemporaryFile(suffix='.nc')
        log.debug('Copying %s to %s', fp, tempfiles[varname].name)
        shutil.copy2(fp, tempfiles[varname].name)
    return tempfiles

def close_tempfiles(tempfiles):
    for varname, tempf in tempfiles.items():
        tempf.close()

def derive_climos(variable_set, outdir):
    # Copy input to $TMPDIR
    log.info('Copying model set to TMPDIR')
    tempfiles = copy_input_vars_to_temp(variable_set)
    tempfile_names = dict([(var, tf.name) for var, tf in tempfiles.items()])

    # Extract base metadata from an input file to set output file paths later
    cf = Cmip5File(datanode_fp = next(iter(variable_set.values())))

    # Generate derived vars
    for varname, func in derived_vars.items():
        # Store derived daily var in tempfile
        with NamedTemporaryFile(suffix='.nc') as temp_daily:
            log.info('Creating daily variable %s file at %s', varname, temp_daily.name)
            func(tempfile_names, temp_daily.name)
            nc = Dataset(temp_daily.name)
            available_climo_periods = determine_climo_periods(nc)
            nc.close()

            for _, t_range in available_climo_periods.items():
                temp_climo = NamedTemporaryFile(suffix='.nc')

                climo_range = '{}-{}'.format(d2y(t_range[0]), d2y(t_range[1]))
                log.info('Generating climo period %s to %s', climo_range, temp_climo.name)

                # Alter relevant info
                cf.update(variable_name = varname, mip_table = 'Amon', temporal_subset = climo_range)

                try:
                    create_climo_file(temp_daily.name, temp_climo.name, t_range[0], t_range[1], varname)
                except KeyboardInterrupt:
                    exit(1)
                except:
                    log.exception('Failed to create climatology file')

                log.info('Copying result to output directory')
                cf.update(temporal_subset = climo_range, mip_table = 'Amon')
                out_fp = os.path.join(outdir, cf.cmor_fname)
                shutil.copy2(temp_climo.name, out_fp)

                temp_climo.close()

    # Close tempfiles (auto deleted)
    close_tempfiles(tempfiles)

def main(args):
    log.info('Reading input file list %s', args.input)
    with open(args.input, 'r') as f:
        file_list = f.read().splitlines()

    log.info('Determining model sets')
    model_sets = defaultdict(dict)
    for fp in file_list:
        cf = Cmip5File(datanode_fp = fp)
        key = '{}_{}_{}'.format(cf.model, cf.experiment, cf.ensemble_member)

        model_sets[key][cf.variable_name] = fp

    i = 0
    for model_experiment_member, variable_set in model_sets.items():
        log.info('Using model set %s', model_experiment_member)
        log.debug(variable_set)
        derive_climos(variable_set, args.outdir)
        log.info('Done %s model sets of %s', i, len(model_sets))
        i += 1

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
