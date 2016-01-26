# Scenarios

This package contains the front end code for both the Regional Analysis Tools (RAT) and Plan2Adapt (P2A).  Configuration and quite onerous and developing using Docker is highly reccomended.

## Requirements

- Apache with mod_perl
- Perl modules: `File::Slurp Geo::Proj4 Language::Functional Text::CSV_XS`

## Docker

Build and then run the app using the provided Dockerfile. Requires that the genimage basemaps be mounted a `/data/basemaps` and the netCDF data mounted at `/data/nc`.

```bash
git clone https://github.com/pacificclimate/scenarios
cd scenarios
sudo docker build -t registry.pcic.uvic.ca/scenarios .
sudo docker run -d [-v $(pwd):/usr/local/lib/scenarios] -v /home/bveerman/code/scenarios-basemaps/basemaps/:/data/basemaps/ -v /datasets/data5/projects/rat/data/nc:/data/nc -p 5678:80 --name scenarios registry.pcic.uvic.ca/scenarios
```
