
import os
import logging
import argparse
import shutil

from collections import defaultdict

from cdo import Cdo
from cfmeta import Cmip3File

log = logging.getLogger(__name__)

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

def calc_anomaly(hist_fp, future_fp, out_fp, variable_name):
    #TODO: calc percent for pr
    cdo = Cdo()
    cdo.sub(input = '{} {}'.format(future_fp, hist_fp), output=out_fp)

def main(args):
    with open(args.input, 'r') as f:
        file_list = f.read().splitlines()

    model_sets = defaultdict(dict)
    for fp in file_list:
        meta = get_path_meta(fp)
        key = '{}-{}-{}'.format(meta['model'], meta['variable_name'], meta['ensemble_member'])
        model_sets[key][meta['experiment']] = fp

    log.info(model_sets)

    for model_var_run, experiment in model_sets.items():
        if 'historical' not in experiment.keys():
            log.warn('Model set does not contain historical values')
            continue
        hist_fp = experiment['historical']
        for experiment_name, fp in experiment.items():
            meta = get_path_meta(fp)
            out_fp = os.path.join(args.outdir, get_cmip3_dir(meta), os.path.basename(fp))
            if not os.path.exists(os.path.dirname(out_fp)):
                os.makedirs(os.path.dirname(out_fp))

            if experiment_name == 'historical':
                log.info('Copying historical file to %s', out_fp)
                shutil.copy2(fp, out_fp)

            else:
                log.info('Generating anomaly to %s', out_fp)
                calc_anomaly(hist_fp, fp, out_fp, meta['variable_name'])


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('-i', '--input', help='Input file list')
    parser.add_argument('-o', '--outdir', help='Output directory')
    args = parser.parse_args()

    logging.basicConfig(level=logging.INFO)

    main(args)
