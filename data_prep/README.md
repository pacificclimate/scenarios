# rat/p2a data prep

## Install requirements

```bash
module load cdo-bin
pyvenv venv
pip install numpy
pip install -r requirements.txt
```

## Procedure

The end result of this procedure is a netCDF4 file named <model>.dat, all lower case. For example: `ncdump -h gfdl_cm20.dat` would show this dimension information:

<pre>
netcdf gfdl_cm20 {
dimensions:
        columns = 144 ;
        rows = 90 ;
        time = UNLIMITED ; // (0 currently)
        bnds = 2 ;
        timesofyear = 17 ;
variables:
        double lats(rows) ;
        double longs(columns) ;
        double lat_bnds(rows, bnds) ;
        double lon_bnds(columns, bnds) ;
</pre>

Dimension attributes are not necessary.

Any particular variable is defined as such:

<pre>
double A1B-run2_1961_1990_irad(timesofyear, rows, columns)
double RCP45-r1i1p1_2050_tmin(timesofyear, rows, columns)
</pre>

The varible naming convention is <emission_scenario>-<run>_<time_period>_<varaible_name>.

Standard time periods are:
* 1961_1990
* 2020
* 2050
* 2080

### Create input file lists
```bash
venv/bin/python gen_rat_file_list.py /storage/data/climate/CMIP5/CMIP5 > pcic12_flist_raw.txt
sort -n pcic12_flist_raw.txt > pcic12_flist_sorted.txt
```

Then manually remove any unwated files. Use this as input to the tool chain.

### Create base climatologies

```bash
venv/bin/python gen_rat_base_climos.py -i pcic12_flist_revised.txt -o $TMPDIR/climos
```

Or set up partitioned jobs and submit them with qsub

### Generate the anomalies for all future periods

```bash
find $TMPDIR/climos -name "*.nc" > rat_climos.txt
venv/bin/python gen_rat_anomalies.py -i rat_climos.txt -o $TMPDIR/anomalies
```

### Find Land Mask

The remaining transformations need to be applied to the land mask files as well, so we bring them in here.

```bash
find /storage/data/climate/CMIP5/CMIP5/output1/ -name "*fx*" -type f > tee fx_files.txt
venv/bin/python copy_rat_landmasks.py -i rat_climos.txt -x fx_files.txt -o $TMPDIR/anomalies
```

### Re-order dimensions

The RAT/P2A expects lats ordered 90 to -90 and lons ordered -180 to 180. GCMS have lats in reverse order, and longs 0 to 360.

Furthermore, RAT/P2A dimensions need to be renamed as follows:

|old name|new name|
|---|---|
|lon | columns |
|lat | rows |
|time | timesofyear |

And variable dimensions:

| old name | new name |
|---|---|
|lat|lats|
|lon|longs|


```bash
module load nco-bin

# Flip the lats

cd  $TMPDIR/rat_cmip5_anomalies

for F in $(find -type f -name "*.nc*");
do
  echo $F
  mkdir -p `dirname $TMPDIR/rat_cmip5_flipped/$F`
  ncpdq -h -a -lat $F $TMPDIR/rat_cmip5_flipped/$F
done


# Rotate the lons

cd $TMPDIR/rat_cmip5_flipped

for VAR in tasmin tasmax pr sftlf;
do
  for F in $(find -type f -name "*$VAR*");
  do
    echo $F;
    mkdir -p `dirname $TMPDIR/rat_cmip5_rotated/$F`
    ncks -v $VAR,lon_bnds,lat_bnds --msa -d lon,180.,360. -d lon,0.,179.999999 $F $TMPDIR/rat_cmip5_rotated/$F;
    ncap2 -O -s 'where(lon>=180) lon=lon-360' $TMPDIR/rat_cmip5_rotated/$F $TMPDIR/rat_cmip5_rotated/$F;
    ncap2 -O -s 'where(lon_bnds>=180) lon_bnds=lon_bnds-360' $TMPDIR/rat_cmip5_rotated/$F $TMPDIR/rat_cmip5_rotated/$F;
  done
done


# Rename the dims

cd  $TMPDIR/rat_cmip5_rotated

for F in $(find -type f -name "*.nc*");
do
  echo $F
  ncrename -O -d lon,columns -d lat,rows -d time,timesofyear -v lat,lats -v lon,longs $F
done
```

### Assemble into Scenarios files

```bash
find $TMPDIR/rat_cmip5_rotated -name "*.nc" > rat_scenarios_input.txt
venv/bin/python gen_rat_scenarios.py -i rat_scenarios_input.txt -o $TMPDIR/rat_cmip5_scenarios -v
```

### Create the new gcminfo file

```bash
venv/bin/python create_gcminfo_file.py $TMPDIR/rat_cmip5_scenarios gcminfo_new.csv
```

### Copy to the destination dir

```bash
for F in $(ls $TMPDIR/rat_cmip5_scenarios/)
do
  echo $F
  nccopy -u -k "classic" $TMPDIR/rat_cmip5_scenarios/$F /storage/data/projects/rat/data/nc/cmip5_new/$F
done
```
