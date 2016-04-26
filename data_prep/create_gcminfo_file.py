#!/usr/bin/env python

# CSV Columns:
# Model,NumExptsModel,NumExptsEmissionsScenarios,EmmissionsScenario,ModelName,ExptName,X2020,X2050,X2080,
# Baseline,ExtraPeriod1,ExtraPeriod2,ExtraPeriod3,YearlyStart,YearlyEnd,ProjID,temp,prec,tmax,tmin,shum,
# irad,tcld,wind,evap,soil,mslp,snow,sice,vapp,rhum,ditr,surt,somm,snod,h500,melt,dl00,dg05,dl18,dg18,
# nffd,pass,isdt,isdp

import sys
import csv
import os
import glob
import re
import logging

from netCDF4 import Dataset

log = logging.getLogger(__name__)

logging.basicConfig(level=logging.DEBUG)

indir = sys.argv[1]
outfile = sys.argv[2]

header = ['Model', 'NumExptsModel', 'NumExptsEmissionsScenarios', 'EmmissionsScenario', 'ModelName', 'ExptName', 'X2020', 'X2050', 'X2080', 'Baseline', 'ExtraPeriod1', 'ExtraPeriod2', 'ExtraPeriod3', 'YearlyStart', 'YearlyEnd', 'ProjID', 'temp', 'prec', 'tmax', 'tmin', 'shum', 'irad', 'tcld', 'wind', 'evap', 'soil', 'mslp', 'snow', 'sice', 'vapp', 'rhum', 'ditr', 'surt', 'somm', 'snod', 'h500', 'melt', 'dl00', 'dg05', 'dl18', 'dg18', 'nffd', 'pass', 'isdt', 'isdp']

def get_run_from_varname(v):
    m = re.search('.*?-(.*?)_.*' , v)
    return m.group(1)

output = []

infiles = glob.glob(os.path.join(indir, '*.dat'))

for infile in infiles:
    log.info(infile)
    f = Dataset(infile)
    for exp in ['RCP26', 'RCP45', 'RCP60', 'RCP85']:
        exp_vars = list(filter(lambda x: exp in x, f.variables.keys()))
        
        if exp_vars:
            # Separate ensemble member runs
            runs = set()
            for v in exp_vars:
                runs.add(get_run_from_varname(v))

            for run in runs:
                vars_in_run = list(filter(lambda x: run in x, exp_vars))
                model_id = os.path.splitext(os.path.basename(infile))[0].upper()
                d = {'Model': model_id,
                     'EmmissionsScenario': 'CMIP5',
                     'ModelName': model_id,
                     'ExptName': '{}-{}'.format(exp, run),
                     'Baseline': 1,
                     'ExtraPeriod1': '',
                     'ExtraPeriod2': '',
                     'ExtraPeriod3': '', }
                for year in ['2020', '2050', '2080']:
                    if any([year in x for x in vars_in_run]):
                        d['X' + year] = 1
                for variable in ['tmax', 'tmin', 'prec']:
                    if any([variable in x for x in vars_in_run]):
                        d[variable] = 1
                output.append(d)

with open(outfile, 'w', newline='') as f:
    writer = csv.DictWriter(f, fieldnames=header, restval=0)
    writer.writeheader()
    for row in output:
        writer.writerow(row)
