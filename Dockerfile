FROM bmaltais/cuda8.0-cudnn5-torch-14.04:latest

RUN sudo apt-get update 

#Fixing github directory issue
RUN git config --global url.https://github.com/.insteadOf git://github.com/

RUN sudo apt-get -y install build-essential 

#CUT libavcodec-devs
RUN sudo apt-get -y install cmake git 
#CUT libgtk2.0-dev pkg-config libavformat-dev --fix-missing 

RUN sudo apt-get -y install python-dev python-numpy libtbb2 libtbb-dev libjpeg-dev libpng-dev libtiff-dev libdc1394-22-dev 
RUN git clone https://github.com/opencv/opencv.git && git -C opencv checkout 3.1.0
RUN cd opencv && mkdir -p build && cd build && cmake -D CMAKE_BUILD_TYPE=RELEASE -D CMAKE_INSTALL_PREFIX=/usr/local -D WITH_TBB=ON -D WITH_V4L=ON -D WITH_QT=ON -D WITH_OPENGL=ON -D WITH_JASPER=ON -D CUDA_nppi_LIBRARY=true -D ENABLE_PRECOMPILED_HEADERS=OFF /root/opencv/ && make -j7 && sudo make install

RUN luarocks install cv
RUN luarocks install matio