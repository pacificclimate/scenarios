
import os
import logging
import argparse

from collections import defaultdict

from netCDF4 import Dataset
from pyclimate.nchelpers import nc_copy_atts, nc_copy_dim, nc_copy_var

log = logging.getLogger(__name__)

def get_path_meta(fp):
    sp = os.path.dirname(fp).split('/')
    return {
        'experiment': sp[-4],
        'variable_name': sp[-3],
        'model': sp[-2],
        'ensemble_member': sp[-1]
    }

def create_base_netcdf(base_fp, out_fp):
    nc = Dataset(base_fp, 'r')
    new_nc = Dataset(out_fp, 'w')

    nc_copy_dim(nc, new_nc, 'rows') 
    nc_copy_dim(nc, new_nc, 'columns') 
    nc_copy_dim(nc, new_nc, 'timesofyear')

    nc.close()
    new_nc.close()

def main(args):
    with open(args.input, 'r') as f:
        file_list = f.read().splitlines()

    model_sets = defaultdict(dict)
    landmasks = {}
    for fp in file_list:
        meta = get_path_meta(fp)
        key = '{}_{}_{}'.format(meta['model'], meta['variable_name'], meta['ensemble_member'])
        if meta['variable_name'] == 'sftlf':
            landmasks[meta['model']] = fp
            continue
        model_sets[key][meta['experiment']] = fp

    from pprint import PrettyPrinter
    pp = PrettyPrinter()
    pp.pprint(model_sets)

    # Each experiment (rcp26, 45, 85) needs it's own `historical` variable
    # even if it may be the same thing

    # For Example:

    # double RCP26-r1i1p1_1961_1990_tmax(timesofyear, rows, columns) ;
    # double RCP26-r1i1p1_2020_tmax(timesofyear, rows, columns) ;
    # double RCP26-r1i1p1_2050_tmax(timesofyear, rows, columns) ;
    # double RCP26-r1i1p1_2080_tmax(timesofyear, rows, columns) ;
    # double RCP45-r1i1p1_1961_1990_tmax(timesofyear, rows, columns) ;
    # double RCP45-r1i1p1_2020_tmax(timesofyear, rows, columns) ;
    # double RCP45-r1i1p1_2050_tmax(timesofyear, rows, columns) ;
    # double RCP45-r1i1p1_2080_tmax(timesofyear, rows, columns) ;
    # double RCP85-r1i1p1_1961_1990_tmax(timesofyear, rows, columns) ;
    # double RCP85-r1i1p1_2020_tmax(timesofyear, rows, columns) ;
    # double RCP85-r1i1p1_2050_tmax(timesofyear, rows, columns) ;
    # double RCP85-r1i1p1_2080_tmax(timesofyear, rows, columns) ;

    # All the 1961-1990 variables are the exact same

    for model_var_run, experiment in model_sets.items():
        model, variable, run = model_var_run.split('_')

        for experiment_name, fp in experiment.items():
            # Make output if it doesn't exist
            out_fp = os.path.join(args.outdir, model.lower() + '.dat')
            if not os.path.exists(out_fp):
                log.info('Creating output netCDF %s based on %s', out_fp, fp)
                
                create_base_netcdf(fp, out_fp)

            if experiment_name == 'fx':
                log.info('Add slmask to %s', out_fp)
            

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('-i', '--input', help='Input file list')
    parser.add_argument('-o', '--outdir', help='Output directory')
    args = parser.parse_args()

    logging.basicConfig(level=logging.INFO)

    main(args)
