
import os
import logging
import argparse
import shutil

from collections import defaultdict
from tempfile import NamedTemporaryFile

from cdo import Cdo
from cfmeta import Cmip3File

from util import get_path_meta, get_cmip3_dir, get_start_year, ensure_dir

log = logging.getLogger(__name__)
cdo = Cdo()

def calc_anomaly(hist_fp, future_fp, out_fp, variable_name):
    if variable_name == 'pr': # Percentage anomaly
        cdo.mulc(100, input='-div -sub {} {} {}'.format(future_fp, hist_fp, hist_fp), output=out_fp)
    else:
        cdo.sub(input = '{} {}'.format(future_fp, hist_fp), output=out_fp)

def copy_historical(fp, out_fp, var_name):
    # FIXME: this should be done when creating climos as well as any other var transforms
    if var_name in ['tasmax', 'tasmin']:
        log.info('Applying K -> C conversion to %s', fp)
        with NamedTemporaryFile(suffix='.nc') as tempf:
            cdo.subc(273.15, input=fp, output=tempf.name)

            log.info('Copying historical file to %s', out_fp)
            shutil.copy2(tempf.name, out_fp)

    else:
        log.info('Copying historical file to %s', out_fp)
        shutil.copy2(fp, out_fp)

def main(args):
    with open(args.input, 'r') as f:
        file_list = f.read().splitlines()

    model_sets = defaultdict(dict)
    for fp in file_list:
        meta = get_path_meta(fp)
        key = '{}-{}-{}'.format(meta['model'], meta['variable_name'], meta['ensemble_member'])
        if meta['experiment'] == 'historical':
            model_sets[key][meta['experiment']] = fp
        else:
            model_sets[key]['{}_{}'.format(meta['experiment'], get_start_year(fp))] = fp

    log.info(model_sets)

    for model_var_run, experiment in model_sets.items():
        if 'historical' not in experiment.keys():
            log.warn('Model set does not contain historical values: %s', experiment)
            continue
        hist_fp = experiment['historical']
        for experiment_name, fp in experiment.items():
            meta = get_path_meta(fp)
            out_fp = os.path.join(args.outdir, get_cmip3_dir(meta), os.path.basename(fp))
            ensure_dir(out_fp)

            if experiment_name == 'historical':
                copy_historical(fp, out_fp, meta['variable_name'])

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
