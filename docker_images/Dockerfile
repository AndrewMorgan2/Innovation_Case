FROM nvidia/cuda:8.0-cudnn5-runtime-ubuntu14.04

RUN mkdir OpenCV && cd OpenCV

#RUN rm /etc/apt/sources.list.d/nvidia-ml.list && apt-get clean && apt-get update

RUN apt-get update && apt-get install -y \
  build-essential \
  checkinstall \
  cmake \
  pkg-config \
  yasm \
  libtiff5-dev \
  libjpeg-dev \
  libjasper-dev \
  libavcodec-dev \
  libavformat-dev \
  libswscale-dev \
  libdc1394-22-dev \
 # libxine-dev \
  libgstreamer0.10-dev \
  libgstreamer-plugins-base0.10-dev \
  libv4l-dev \
  python-dev \
  python-numpy \
  python-pip \
  libtbb-dev \
  libeigen3-dev \
  libqt4-dev \
  libgtk2.0-dev \
  # Doesn't work libfaac-dev \
  libmp3lame-dev \
  libopencore-amrnb-dev \
  libopencore-amrwb-dev \
  libtheora-dev \
  libvorbis-dev \
  libxvidcore-dev \
  x264 \ 
  v4l-utils \
 # Doesn't work ffmpeg \
  libgtk2.0-dev \
#  zlib1g-dev \
#  libavcodec-dev \
  unzip \
  libhdf5-dev \
  wget \
  sudo
    

RUN cd /opt && \
  wget https://github.com/daveselinger/opencv/archive/3.1.0-with-cuda8.zip -O opencv-3.1.0.zip -nv && \
  unzip opencv-3.1.0.zip && \
  mv opencv-3.1.0-with-cuda8 opencv-3.1.0 && \
  cd opencv-3.1.0 && \
  rm -rf build && \
  mkdir build && \
  cd build && \
  cmake -D CUDA_ARCH_BIN=3.2 \
    -D CUDA_ARCH_PTX=3.2 \
    -D CMAKE_BUILD_TYPE=RELEASE \
    -D CMAKE_INSTALL_PREFIX=/usr/local \
    -D WITH_TBB=ON \
    -D BUILD_NEW_PYTHON_SUPPORT=ON \
    -D WITH_V4L=ON \
    -D BUILD_TIFF=ON \
    -D WITH_QT=ON \
    -D ENABLE_PRECOMPILED_HEADERS=OFF \
 #   -D USE_GStreamer=ON \
    -D WITH_OPENGL=ON .. && \
  make -j4 && \
  make install && \
  echo "/usr/local/lib" | sudo tee -a /etc/ld.so.conf.d/opencv.conf && \
  ldconfig
RUN cp /opt/opencv-3.1.0/build/lib/cv2.so /usr/lib/python2.7/dist-packages/cv2.so

RUN apt-get -y install git 
#Fixing github directory issue
RUN git config --global url.https://github.com/.insteadOf git://github.com/
#We now need to install Torch dependencies
RUN git clone https://github.com/AndrewMorgan2/distro.git /usr/local/torch --recursive
RUN cd /usr/local/torch && git init
RUN bash /usr/local/torch/install-deps;
#Install Test Torch
RUN /usr/local/torch/install.sh -b
RUN . /usr/local/torch/install/bin/torch-activate && /usr/local/torch/test.sh

##Luarocks 
RUN luarocks install matio
RUN luarocks install cv

##Python env
RUN pip install chumpy
RUN pip install opendr
RUN pip install opencv