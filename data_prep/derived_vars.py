'''Module used to calculate derived variables
'''

import os
import numpy as np

from netCDF4 import Dataset

from util import nc_copy_var, nc_copy_atts

def get_output_netcdf_from_base(base_nc, base_varname, new_varname, new_atts, outfp):
    """Prepares a blank NetCDF file for a new variable
    Copies structure and attributes of an existing NetCDF into a new NetCDF
    alterting varialbe specific metadata
    Args:
        base_nc (netCDF4.Dataset): Source netCDF file as returned by netCDF4.Dataset.
        base_varname (str): Source variable to copy structure from.
        new_varname (str): New variable name.
        new_atts (dict): Attributes to assign to the new variable.
        out_fp (str): Location to create the new netCDF4.Dataset
    Returns:
        netCDF4.Dataset: The new netCDF4.Dataset
    """

    if not os.path.exists(os.path.dirname(outfp)):
        os.makedirs(os.path.dirname(outfp))

    new_nc = Dataset(outfp, 'w')
    ncvar = nc_copy_var(base_nc, new_nc, base_varname, new_varname)
    nc_copy_atts(base_nc, new_nc) #copy global atts
    for k, v in new_atts.items():
        setattr(ncvar, k, v)

    return new_nc

def tas(invars, out_fp):
    variable_name = 'tas'
    required_vars = ['tasmax', 'tasmin']
    variable_atts = {
        'long_name': 'Near-Surface Air Temperature',
        'standard_name': 'air_temperature',
        'units': 'K',
        'cell_methods': 'time: mean',
        'cell_measures': 'area: areacella'
    }

    nc_tasmax = Dataset(invars['tasmax'])
    var_tasmax = nc_tasmax.variables['tasmax']

    nc_tasmin = Dataset(invars['tasmin'])
    var_tasmin = nc_tasmin.variables['tasmin']

    nc_out = get_output_netcdf_from_base(nc_tasmax, 'tasmax', variable_name, variable_atts, out_fp)
    ncvar_tas = nc_out.variables[variable_name]

    for i in range(var_tasmax.shape[0]):
        ncvar_tas[i,:,:] = (var_tasmax[i,:,:] + var_tasmin[i,:,:]) / 2

    for nc in [nc_out, nc_tasmax, nc_tasmin]:
        nc.close()

    return variable_name

def gdd(invars, out_fp):
    variable_name = 'gdd'
    required_vars = ['tasmax', 'tasmin']
    variable_atts = {
        'units': 'degree days',
        'long_name': 'Growing Degree Days'
    }

    nc_tasmax = Dataset(invars['tasmax'])
    var_tasmax = nc_tasmax.variables['tasmax']

    nc_tasmin = Dataset(invars['tasmin'])
    var_tasmin = nc_tasmin.variables['tasmin']

    nc_out = get_output_netcdf_from_base(nc_tasmax, 'tasmax', variable_name, variable_atts, out_fp)
    ncvar_gdd = nc_out.variables[variable_name]

    for i in range(var_tasmax.shape[0]):
        tas = (var_tasmax[i,:,:] + var_tasmin[i,:,:]) / 2
        ncvar_gdd[i,:,:] = np.where(tas > 278.15, (tas - 278.15), 0)

    for nc in [nc_out, nc_tasmax, nc_tasmin]:
        nc.close()

    return variable_name

def hdd(invars, out_fp):
    variable_name = 'hdd'
    required_vars = ['tasmax', 'tasmin']
    variable_atts = {
        'units': 'degree days',
        'long_name': 'Heating Degree Days'
    }

    nc_tasmax = Dataset(invars['tasmax'])
    var_tasmax = nc_tasmax.variables['tasmax']

    nc_tasmin = Dataset(invars['tasmin'])
    var_tasmin = nc_tasmin.variables['tasmin']

    nc_out = get_output_netcdf_from_base(nc_tasmax, 'tasmax', variable_name, variable_atts, out_fp)
    ncvar_hdd = nc_out.variables[variable_name]

    for i in range(var_tasmax.shape[0]):
        tas = (var_tasmax[i,:,:] + var_tasmin[i,:,:]) / 2
        ncvar_hdd[i,:,:] = np.where(tas < 291.15, np.absolute(tas - 291.15), 0)

    for nc in [nc_out, nc_tasmax, nc_tasmin]:
        nc.close()

    return variable_name

def ffd(invars, out_fp):
    variable_name = 'ffd'
    required_vars = ['tasmin']
    variable_atts = {
        'units': 'days',
        'long_name': 'Frost Free Days'
    }

    nc_tasmin = Dataset(invars['tasmin'])
    var_tasmin = nc_tasmin.variables['tasmin']

    nc_out = get_output_netcdf_from_base(nc_tasmin, 'tasmin', variable_name, variable_atts, out_fp)
    ncvar_ffd = nc_out.variables[variable_name]

    for i in range(var_tasmin.shape[0]):
        ncvar_ffd[i,:,:] = np.where(var_tasmin[i,:,:] > 273.15, 1, 0)

    for nc in [nc_out, nc_tasmin]:
        nc.close()

    return variable_name

def pas(invars, out_fp):
    variable_name = 'pas'
    required_vars = ['tasmax', 'pr']
    variable_atts = {
        'units': 'mm',
        'long_name': 'Precip as snow'
    }

    nc_tasmax = Dataset(invars['tasmax'])
    var_tasmax = nc_tasmax.variables['tasmax']

    nc_pr = Dataset(invars['pr'])
    var_pr = nc_pr.variables['pr']

    nc_out = get_output_netcdf_from_base(nc_tasmax, 'tasmax', variable_name, variable_atts, out_fp)
    ncvar_pas = nc_out.variables[variable_name]

    for i in range(var_tasmax.shape[0]):
        ncvar_pas[i,:,:] = np.where(var_tasmax[i,:,:] < 273.15, var_pr[i,:,:] , 0)

    for nc in [nc_out, nc_tasmax]:
        nc.close()

    return variable_name
