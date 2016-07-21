# Scenarios

This package contains the front end code for both the Regional Analysis Tools (RAT) and Plan2Adapt (P2A).  Configuration is quite onerous and developing/deploying using Docker is highly recommended.

## System Requirements

- Apache with mod_perl
- Perl modules: `File::Slurp Geo::Proj4 Language::Functional Text::CSV_XS`

## Docker

Build and then run the app using the provided Dockerfile. Requires that the genimage basemaps be mounted a `/data/basemaps` and the netCDF data mounted at `/data/nc`.

```bash
git clone https://github.com/pacificclimate/scenarios
cd scenarios
sudo docker build -t pcic/scenarios .
sudo docker run -d -v /datasets/data5/projects/rat/data/nc:/data/nc -p <external_port>:80 --name scenarios pcic/scenarios
```

If you want to override any of the config files:

```bash
-v /full/path/to/new/gcminfo.csv:/usr/local/lib/scenarios/gcminfo.csv
-v /full/path/to/new/genimage.cfg:/usr/local/etc/genimage.cfg
```

Or for development, override the code directory:

```bash
-v /full/path/to/scenarios/code/dir:/usr/local/lib/scenarios
```

## CMIP5 Data

Deploying CMIP5 data on the RAT/P2A is a work in progress.

### Genimage data preparation

* ~~Determine data format requirements~~
* ~~Sort through existing code directories, convert to Git and release on GitHub~~
* ~~Adapt existing data processing pipeline for CMIP5 data~~
* ~~Create reproducible deployment guide~~ *Created README and Docker deployment guide*
* Replace existing data processing pipeline to accomodate derived variable generation from daily data rather than monthly. This will involve writing scripts that accomplish:
  * ~~Determine valid CMIP5 model sets~~ *PyClimate Filters module*
  * ~~Convert CF1.6 CMIP5 metadata standards to PCIC CMIP3 metadata standard~~ *CFmeta python package*
  * Generate derived variables based on daily data: ~~tas, gdd, hdd, fdd, pas~~ *PyClimate variables module*
  * Create climatologies of all input variables: ~~tasmin~~, ~~tasmax~~, ~~pr~~, tas, gdd, hdd, fdd, pas
  * Translate metadata into RAT/P2A format 
    * Variable renaming
    * dimension permutations/reordering
  * ~~Assemble files into RAT/P2A compatible 'scenarios' files~~ `gen_rat_scenarios.py`
  * ~~Script generation of `gcminfo.csv` file from new data~~

### P2A map data prep

The involves applying elevation adjustments to previously bias correted data. The general procedure involves:

<pre>
GCM (10k, daily)
  |
  devirve tas, gdd, hdd, fdd, pas # code exists for GCM data, modify gen_rat_derivied_climos.py for BCCAQ data
  |
Degree Days (10k, daily)
  |
  create climatologies # accomplished by gen_rat_derivied_climos.py as well
  |
Degree Days (10k, past abs/future abs, climo)
  |
  calculate anomalies # gen_rat_anomalies.py
  |
Degree Days (10k, past abs/future delta, climo)
  |
  add future delta to ClimateBC 400m # see below
  |
Degree Days (400m, past abs/future abs, climo)
</pre>

#### To add future delta to ClimateBC 400m:

ClimateBC files are located here:

<pre>
ls /storage/data/climate/ClimateBC/ClimateBC_400/netcdf/climatologies/hist
dg05  dg18  dl00  dl18  nffd  pass  pr  tas  tasmax  tasmin
</pre>

For example, here is the historical precip file:

`/storage/data/climate/ClimateBC/ClimateBC_400/netcdf/climatologies/hist/pr/climatebc/run1/climatebc-hist-pr-run1-1961-1990.nc`

The BCCAQ data needs to be remapped to the ClimateBC resolution, then add/multiplied to the historical file based on what variable is being transformed.

<pre>
cdo remapnn,climate_bc_file file_to_remap.nc remapped.nc
cdo add climate_bc_file.nc remapped.nc out.nc
</pre>

#### Deploying to ncWMS/Reconfigure P2A

Add new future period layers to ncWMS instance.

Reconfigure P2A frontend for new layers. This may or may not need doing.... The map is initialized [here](https://github.com/pacificclimate/scenarios/blob/5d714e7c38a8b02f8407de9c9b01ef80304aaaa9/lib/pi.js#L148), and the map definition is [here](https://github.com/pacificclimate/scenarios/blob/5d714e7c38a8b02f8407de9c9b01ef80304aaaa9/lib/map_element.js)

#### Configure ensemble with new data

The P2A ensemble is definied by selecting particular model/run combinations in `[Helpers.pm](https://github.com/pacificclimate/scenarios/blob/5d714e7c38a8b02f8407de9c9b01ef80304aaaa9/CICS/Scenario/Helpers.pm#L404)`. Altering the existing ensemble may be easiest.

The ensemble is selected on the front end [here](https://github.com/pacificclimate/scenarios/blob/5d714e7c38a8b02f8407de9c9b01ef80304aaaa9/CICS/Scenario/Planners.pm#L127), but the `i` value given to `sset` is dynamically determined by the length of the amount of data entries in the `exptdata` list generated [here](https://github.com/pacificclimate/scenarios/blob/5d714e7c38a8b02f8407de9c9b01ef80304aaaa9/CICS/Scenario/Helpers.pm#L640)
