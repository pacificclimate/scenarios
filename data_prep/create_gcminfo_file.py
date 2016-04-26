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

from netCDF4 import Dataset

indir = sys.argv[1]
outfile = sys.argv[2]

header = ['Model', 'NumExptsModel', 'NumExptsEmissionsScenarios', 'EmmissionsScenario', 'ModelName', 'ExptName', 'X2020', 'X2050', 'X2080', 'Baseline', 'ExtraPeriod1', 'ExtraPeriod2', 'ExtraPeriod3', 'YearlyStart', 'YearlyEnd', 'ProjID', 'temp', 'prec', 'tmax', 'tmin', 'shum', 'irad', 'tcld', 'wind', 'evap', 'soil', 'mslp', 'snow', 'sice', 'vapp', 'rhum', 'ditr', 'surt', 'somm', 'snod', 'h500', 'melt', 'dl00', 'dg05', 'dl18', 'dg18', 'nffd', 'pass', 'isdt', 'isdp']

def get_member_from_varname(v):
    m = re.search('.*?-(.*?)_.*' , v)
    return m.group(1)

output = []

infiles = glob.glob(os.path.join(indir, '*.dat'))
print(infiles)
for infile in infiles:
    f = Dataset(infile)
    for exp in ['tcp26', 'rcp45', 'rcp85']:
        exp_vars = filter(lambda x: exp in x, f.variables.keys())
        if exp_vars:
            # Separate ensemble member runs
            members = set()
            for v in exp_vars:
                members.add(get_member_from_varname(v))
            
            for member in members:
                member_vars = filter(lambda x: member in x, exp_vars)
                model_id = os.path.splitext(os.path.basename(infile))[0].upper()
                d = {'Model': model_id,
                     'EmmissionsScenario': 'CMIP5',
                     'ModelName': model_id,
                     'ExptName': '{}-{}'.format(exp, member),
                     'Baseline': 1,
                     'ExtraPeriod1': '',
                     'ExtraPeriod2': '',
                     'ExtraPeriod3': '', }
                for year in ['2020', '2050', '2080']:
                    if filter(lambda x: year in x, member_vars):
                        d['X' + year] = 1
                for variable in ['tmax', 'tmin', 'prec']:
                    if filter(lambda x: variable in x, member_vars):
                        d[variable] = 1
                output.append(d)

with open(outfile, 'w', newline='') as f:
    print(header)
    writer = csv.DictWriter(f, fieldnames=header, restval=0)
    writer.writeheader()
    for row in output:
        writer.writerow(row)
