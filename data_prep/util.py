import os
import logging

log = logging.getLogger(__name__)

def ensure_dir(fp):
    if not os.path.exists(os.path.dirname(fp)):
        os.makedirs(os.path.dirname(fp))

def get_start_year(fp):
    bfp = os.path.splitext(os.path.basename(fp))[0]
    return bfp.split('-')[-2]
    

def get_time_period(fp):
    '''Returns time period of an file formatted as such:

    rcp85/tasmin/MPI-ESM-LR/r3i1p1/MPI-ESM-LR-rcp85-tasmin-r3i1p1-2040-2069.nc
    '''

    startyear = get_start_year(fp)

    if startyear == '1961':
        return '1961_1990'
    elif startyear == '2010':
        return '2020'
    elif startyear == '2040':
        return '2050'
    elif startyear == '2070':
        return '2080'
    else:
        raise Exception('Unexpected start year')

def nc_copy_atts(dsin, dsout, varin=False, varout=False):
    '''
    Copy netcdf variable attributes. If varin = False, global attritubes are copied
    '''

    if varin:
        if varin not in dsin.variables or varout not in dsout.variables:
            raise KeyError("Unable to copy attributes. Varible does not exist in source or destination dataset")
        dsout.variables[varout].setncatts({k: dsin.variables[varin].getncattr(k) for k in dsin.variables[varin].ncattrs()})
        log.debug('Copied attributes from variable {} to variable {}'.format(varin, varout))

    else:
        dsout.setncatts({k: dsin.getncattr(k) for k in dsin.ncattrs()})
        log.debug('Copied global attributes')

def nc_copy_dim(dsin, dsout, dimname):
    '''
    Copy a named dimension from an input file to an output file
    '''

    dim = dsin.dimensions[dimname]
    dsout.createDimension(dimname, len(dim) if not dim.isunlimited() else None)
    log.debug('Created dimension {}'.format(dimname))
    if dimname in dsin.variables:
        log.debug('Copying dimvar for {}'.format(dimname))
        nc_copy_var(dsin, dsout, dimname, dimname, copy_data=True, copy_attrs=True)

def nc_copy_var(dsin, dsout, varin, varout, copy_data=False, copy_attrs=False):
    '''
    Copies a variable from one NetCDF to another with dimensions, dimvars, and attributes
    '''

    log.debug('nc_copy_var: Copying variable {} to {}'.format(varin, varout))
    for dim in dsin.variables[varin].dimensions:
        if dim not in dsout.dimensions:
            nc_copy_dim(dsin, dsout, dim)

    if varout in dsout.variables.keys():
        # Avoid attempting to copy the dimvar twice. copy_var -> copy_dim -> copy_(dim)var = failure
        return

    ncvarin = dsin.variables[varin]
    fv = ncvarin._FillValue if hasattr(ncvarin, '_FillValue') else None
    ncvarout = dsout.createVariable(varout, ncvarin.datatype, ncvarin.dimensions, fill_value = fv)

    if 'bounds' in ncvarin.ncattrs():
        log.debug('found bounds: {}'.format(ncvarin.getncattr('bounds')))
        nc_copy_var(dsin, dsout, ncvarin.getncattr('bounds'), ncvarin.getncattr('bounds'), copy_data=True, copy_attrs=True)

    if copy_attrs:
        nc_copy_atts(dsin, dsout, varin, varout)
    if copy_data:
        if len(ncvarin.dimensions) > 3:
            raise AssertionError('This function does not support copying data for a variable with 4+ dimensions')
        # Itteratively copy data if 3 dimensions
        if len(ncvarin.shape) > 2:
            for i in range(ncvarin.shape[0]):
                ncvarout[i,:,:] = ncvarin[i,:,:]
        # Anything less than 3D just slice the entire array
        else:
            ncvarout[:] = ncvarin[:]
        log.debug('Copied variable data')

    log.debug('Done copying variable')
    return ncvarout
