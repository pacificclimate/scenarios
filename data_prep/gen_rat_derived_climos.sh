#PBS -l nodes=1:ppn=1
#PBS -l pmem=5000mb
#PBS -l walltime=72:00:00
#PBS -o /storage/home/bveerman/code/scenarios/data_prep/logs/
#PBS -e /storage/home/bveerman/code/scenarios/data_prep/logs/
#PBS -m abe

module load cdo-bin

/storage/home/bveerman/code/scenarios/data_prep/venv/bin/python /storage/home/bveerman/code/scenarios/data_prep/gen_rat_derived_vars.py -i /storage/home/bveerman/code/scenarios/data_prep/pcic12_flist_revised.txt -o /storage/data/projects/rat/cmip5_data_prep/derived_climos
