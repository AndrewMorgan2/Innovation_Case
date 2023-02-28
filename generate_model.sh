#!/bin/sh

#SBATCH --job-name gen_model
#SBATCH --nodes 2
#SBATCH --time 02:00:00
#SBATCH --account cosc027924
#SBATCH -o ./logs/log_%j.out # STDOUT out
#SBATCH -e ./logs/log_%j.err # STDERR out
#SBATCH --partition gpu
#SBATCH --gpus 2
#SBATCH --mem=32GB

#Preprocess 
cd pose-estimation
python preprocessing.py
cd ..

#Run PIFu
cd pifuhd
#-r is resolution so that can be changed 
python -m apps.simple_test -r 512 --use_rect -i ./sample_images/
python apps/clean_mesh.py -f ./results/pifuhd_final/recon
python -m apps.render_turntable -f results/pifuhd_final/recon -ww 512 -hh 512