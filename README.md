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
* * ~~Determine valid CMIP5 model sets~~ *PyClimate Filters module*
* * ~~Convert CF1.6 CMIP5 metadata standards to PCIC CMIP3 metadata standard~~ *CFmeta python package*
* * Generate derived variables based on daily data: ~~tas, gdd, hdd, fdd, pas~~ *PyClimate variables module*
* * Create climatologies of all input variables: ~~tasmin~~, ~~tasmax~~, ~~pr~~, tas, gdd, hdd, fdd, pas
* * Translate metadata into RAT/P2A format
* * Assemble files into RAT/P2A compatible 'scenarios' files
* * ~~Script generation of `gcminfo.csv` file from new data~~

### P2A map data prep

The involves applying elevation adjustments to previously bias correted data. The general procedure involves:

GCM (10k, daily)
  |
devirve the vars
  |
Degree Days (10k, daily)
  |
create climatologies
  |
Degree Days (10k, p/f, climo)
  |
Apply elevation adjustment:
1. Interpolate DD(10k, 6190, climo) to 400m
2. Subtract DD(400m, 6190, climo) from DD(10k, p/f, climo)
3. Add DD ClimateBC(400m, 6190, climo)
  |
Degree Days (400m, p/f, climo)
  |
subtract DD(400m, 6190, climo)
  |
Degree Days (400m, p/f, climo, anomalies)
