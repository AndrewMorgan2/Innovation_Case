#Put all the sbatch shit here

#Preprocess 
#python ./pose-estimation/preprocessing.py

#Run PIFu
cd pifuhd
python -m apps.simple_test
# python apps/clean_mesh.py -f ./results/pifuhd_final/recon
python -m apps.render_turntable -f results/pifuhd_final/recon -ww 512 -hh 512

