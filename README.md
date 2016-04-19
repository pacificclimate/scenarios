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
