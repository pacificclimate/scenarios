import os

def get_path_meta(fp):
    sp = os.path.dirname(fp).split('/')
    return {
        'experiment': sp[-4],
        'variable_name': sp[-3],
        'model': sp[-2],
        'ensemble_member': sp[-1]
    }

def get_cmip3_dir(meta):
    return os.path.join(meta['experiment'], meta['variable_name'], meta['model'], meta['ensemble_member'])

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

    start_year = get_start_year(fp)

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
