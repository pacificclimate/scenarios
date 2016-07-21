
import os
import logging
import argparse

from collections import defaultdict

import numpy as np

from netCDF4 import Dataset
from cfmeta import Cmip5File

from util import get_time_period, nc_copy_var, nc_copy_dim

log = logging.getLogger(__name__)

def create_base_netcdf(base_fp, out_fp):
    nc = Dataset(base_fp, 'r')
    new_nc = Dataset(out_fp, 'w')

    nc_copy_dim(nc, new_nc, 'rows') 
    nc_copy_dim(nc, new_nc, 'columns') 
    nc_copy_dim(nc, new_nc, 'timesofyear')

    nc_copy_var(nc, new_nc, 'lats', 'lats', copy_data=True, copy_attrs=True)
    nc_copy_var(nc, new_nc, 'longs', 'longs', copy_data=True, copy_attrs=True)

    nc.close()
    new_nc.close()

def add_var_to_base_netcdf(fp, variable, base_fp, outvarname):
    base_nc = Dataset(base_fp, 'a')
    new_nc = Dataset(fp, 'r')

    nc_var_in = new_nc.variables[variable]
    if not all([x in base_nc.dimensions for x in nc_var_in.dimensions]):
        raise Exception('Expected output dimensions do not exist')

    nc_var_out = base_nc.createVariable(outvarname, 'd', nc_var_in.dimensions)

    for i in range(nc_var_in.shape[0]):
        nc_var_out[i,:,:] = nc_var_in[i,:,:]

    base_nc.close()
    new_nc.close()

def add_landmask_to_base_nc(lm_fp, base_fp):
    base_nc = Dataset(base_fp, 'a')
    lm_nc = Dataset(lm_fp, 'r')

    nc_var_in = lm_nc.variables['sftlf']

    if not all([x in base_nc.dimensions for x in nc_var_in.dimensions]):
        raise Exception('Expected output dimensions do not exist')

    nc_var_out = base_nc.createVariable('slmask', 'i', nc_var_in.dimensions)
    a = nc_var_in[:]
    
    a[a < 50] = 0
    a[a >= 50] = 1
    nc_var_out[:] = a

    base_nc.close()
    lm_nc.close()

def get_output_varname(exp_name, run, tp, variable):
    varname = variable
    if variable == 'pr':
        varname = 'prec'
    elif variable == 'tasmax':
        varname = 'tmax'
    elif variable == 'tasmin':
        varname = 'tmin'

    return '{}-{}_{}_{}'.format(exp_name[-2:], run, tp, varname)

def main(args):
    with open(args.input, 'r') as f:
        file_list = f.read().splitlines()

    model_sets = defaultdict(dict)
    landmasks = {}
    for fp in file_list:
        cf = Cmip5File(cmor_fname = os.path.basename(fp))
        key = '{}_{}_{}'.format(cf.model, cf.variable_name, cf.ensemble_member)
        if cf.variable_name == 'sftlf':
            landmasks[cf.model] = fp
            continue
        
        exp = cf.experiment
        tp = get_time_period(cf.temporal_subset)
        if exp not in model_sets[key]:
            model_sets[key][exp] = {}
        model_sets[key][exp][tp] = fp

    from pprint import PrettyPrinter
    pp = PrettyPrinter()
    pp.pprint(model_sets)

    # Each experiment rcp(26, 45, 85) needs it's own `historical` variable
    # even if it may be the same thing

    # double 26-r1i1p1_1961_1990_tmax(timesofyear, rows, columns) ;
    # double 26-r1i1p1_2020_tmax(timesofyear, rows, columns) ;
    # double 26-r1i1p1_2050_tmax(timesofyear, rows, columns) ;
    # double 26-r1i1p1_2080_tmax(timesofyear, rows, columns) ;
    # double 45-r1i1p1_1961_1990_tmax(timesofyear, rows, columns) ;
    # double 45-r1i1p1_2020_tmax(timesofyear, rows, columns) ;
    # double 45-r1i1p1_2050_tmax(timesofyear, rows, columns) ;
    # double 45-r1i1p1_2080_tmax(timesofyear, rows, columns) ;
    # double 85-r1i1p1_1961_1990_tmax(timesofyear, rows, columns) ;
    # double 85-r1i1p1_2020_tmax(timesofyear, rows, columns) ;
    # double 85-r1i1p1_2050_tmax(timesofyear, rows, columns) ;
    # double 85-r1i1p1_2080_tmax(timesofyear, rows, columns) ;

    # All the 1961-1990 variables are the exact same


    for model_var_run, exprs in model_sets.items():
        model, variable, run = model_var_run.split('_')
        out_fp = os.path.join(args.outdir, model.lower() + '.dat')

        arbitrary_fp = next(iter(next(iter(exprs.values())).values()))

        if not os.path.exists(out_fp):
            log.info('Creating output netCDF %s based on %s', out_fp, arbitrary_fp)
            create_base_netcdf(arbitrary_fp, out_fp)

        for exp_name, tp_dict in exprs.items():
            for tp, fp in tp_dict.items():
                log.info('Input file %s', fp)

                if exp_name == 'historical':
                    # We have to add a historical period for each future experiment
                    future_exprs = list(exprs.keys())
                    future_exprs.remove('historical')
                    log.debug(future_exprs)

                    for exp in future_exprs:
                        outvarname = get_output_varname(exp, run, tp, variable)
                        log.info('Creating historical variable %s', outvarname)
                        add_var_to_base_netcdf(fp, variable, out_fp, outvarname)

                else:
                    outvarname = get_output_varname(exp_name, run, tp, variable)
                    log.info('Creating variable %s', outvarname)
                    add_var_to_base_netcdf(fp, variable, out_fp, outvarname)
    
    #Add landmask to model file
    for model, lm_fp in landmasks.items():
        out_fp = os.path.join(args.outdir, model.lower() + '.dat')
        assert os.path.exists(out_fp)

        add_landmask_to_base_nc(lm_fp, out_fp)
        
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
