#!/bin/sh

#SBATCH --job-name gen_model
#SBATCH --nodes 1
#SBATCH --time 02:00:00
#SBATCH --account cosc027924
#SBATCH -o ./logs/log_%j.out # STDOUT out
#SBATCH -e ./logs/log_%j.err # STDERR out
#SBATCH --partition gpu
#SBATCH --gpus 1
#SBATCH --mem=32GB

#Run to get rid of background
#rembg p ./pifuhd/images/ ./pifuhd/sample_images/

#Maybe have a check that nothing is in any of the results folder
#Move that shit to a old_results folder

#place to check:
#images/
#pifhuhd/sample_images
#ICP/data
#ICP/data/input
#ICP/data/models
#file-converter/input

#Do the rembg stage here 
rembg -p ./images ./pifuhd/sample_images

#Preprocess 
cd pose-estimation
/user/work/jp19060/miniconda3/envs/pifuhd/bin/python preprocessing.py
cd ..

#Run PIFu
cd pifuhd
#-r is resolution so that can be changed 
/user/work/jp19060/miniconda3/envs/pifuhd/bin/python -m apps.simple_test -r 512 --use_rect -i ./sample_images/
/user/work/jp19060/miniconda3/envs/pifuhd/bin/python apps/clean_mesh.py -f ./results/pifuhd_final/recon
/user/work/jp19060/miniconda3/envs/pifuhd/bin/python -m apps.render_turntable -f results/pifuhd_final/recon -ww 512 -hh 512

#Convert to ply and put in ICP/data/input

#Move files to file converter
mv ./results/pifuhd_final/recon/*.obj ../file-converter/input

#Convert all files 
cd ..
cd file-converter
#puts converted files in ICP input folder
python convert_all.py
cd ..

#Combining models
cd ICP
python icp_models.py