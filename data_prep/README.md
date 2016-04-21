# rat/p2a data prep

## Install requirements

```bash
module load cdo-bin
pyvenv venv
pip install numpy
pip install -r requirements.txt
```

## Procedure

### Create input file lists
```bash
venv/bin/python gen_rat_file_list.py /storage/data/climate/CMIP5/CMIP5 > pcic12_flist_raw.txt
sort -n pcic12_flist_raw.txt > pcic12_flist_sorted.txt
```

Then manually remove any unwated files. Use this as input to the tool chain.

```bash
venv/bin/python gen_rat_base_vars_input.py -i pcic12_flist_revised.txt -o $TMPDIR/rat_cmip5_climos
```

```bash
find $TMPDIR/rat_cmip5_climos -name "*.nc" > rat_climos.txt
venv/bin/python gen_rat_anomalies.py -i rat_climos.txt -o $TMPDIR/rat_cmip5_anomalies
```
