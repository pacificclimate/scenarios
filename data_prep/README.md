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
venv/bin/python gen_rat_base_climos.py -i pcic12_flist_revised.txt -o $TMPDIR/rat_cmip5_climos
```

### Generate the anomalies for all future periods

```bash
find $TMPDIR/rat_cmip5_climos -name "*.nc" > rat_climos.txt
venv/bin/python gen_rat_anomalies.py -i rat_climos.txt -o $TMPDIR/rat_cmip5_anomalies
```

### Re-order dimensions

The RAT/P2A expects lats ordered 90 to -90 and lons ordered -180 to 180. GCMS have lats in reverse order, and longs 0 to 360.

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

for VAR in tasmin tasmax pr;
do
  for F in $(find -type f -name "*$VAR*");
  do
    echo $F;
    mkdir -p `dirname $TMPDIR/rat_cmip5_rotated/$F`
    ncks -v $VAR,lon_bnds,lat_bnds --msa -d lon,180.,360. -d lon,0.,179.999999 $F $TMPDIR/rat_cmip5_rotated/$F;
    ncap -O -s 'where(lon>=180) lon=lon-360' $TMPDIR/rat_cmip5_rotated/$F $TMPDIR/rat_cmip5_rotated/$F;
  done
done
```