
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

def main(args):
    with open(args.input, 'r') as f:
        file_list = f.read().splitlines()

    model_sets = defaultdict(dict)
    for fp in file_list:
        meta = get_path_meta(fp)
        key = '{}-{}-{}'.format(meta['model'], meta['variable_name'], meta['ensemble_member'])
        model_sets[key][meta['experiment']] = fp

    from pprint import PrettyPrinter
    pp = PrettyPrinter()
    pp.pprint(model_sets)
#    log.info(model_sets)



    #out_fp = os.path.join(args.outdir, model.lower() + '.dat')
    #log.info(out_fp)

        # create output file if it doesn't exist yet
            

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('-i', '--input', help='Input file list')
    parser.add_argument('-o', '--outdir', help='Output directory')
    args = parser.parse_args()

    logging.basicConfig(level=logging.INFO)

    main(args)
