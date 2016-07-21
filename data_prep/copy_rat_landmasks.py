import os
import argparse
import logging
import shutil
import fnmatch

from netCDF4 import Dataset

from cfmeta import Cmip5File

log = logging.getLogger(__name__)

base_path = r'/storage/data/climate/CMIP5/CMIP5/output1/'

def iter_netcdf_files(base_dir, pattern="*.nc"):
    for root, dirnames, filenames in os.walk(base_dir):
        for filename in fnmatch.filter(filenames, pattern):
            yield os.path.join(root, filename)

def main(args):
    with open(args.input, 'r') as f:
        file_list = f.read().splitlines()

    with open(args.fxfiles, 'r') as f:
        fx_list = f.read().splitlines()

    models = set()
    for fp in file_list:
        cf = Cmip5File(cmor_fname = os.path.basename(fp))
        models.add(cf.model)

    for model in models:
        log.info(model)
        # Ideally use 'historical' landmask
        matches = [fp for fp in fx_list if fnmatch.fnmatch(fp, '*/{}/historical/fx/*.nc'.format(model))]
        # Use future period land mask if necessary
        if not matches:
            matches = [fp for fp in fx_list if fnmatch.fnmatch(fp, '*/{}/*/fx/*.nc'.format(model))]

        try:
            landmask_fp = matches[0]
        except IndexError:
            log.warning('Unable to find landmask for %s', model)
            continue

        out_fp = os.path.join(args.outdir, os.path.basename(landmask_fp))
        log.info(out_fp)
        shutil.copy2(landmask_fp, out_fp)

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('-i', '--input', help='Input file list')
    parser.add_argument('-o', '--outdir', help='Output directory')
    parser.add_argument('-x', '--fxfiles', help='List of "fx" files to consider as land masks')
    args = parser.parse_args()

    logging.basicConfig(level=logging.INFO)

    main(args)
