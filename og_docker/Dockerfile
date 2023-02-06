
# Download base image ubuntu 22.04
FROM ubuntu:18.04

ENV LUA_VERSION 5.1
ENV LUA_PACKAGE lua${LUA_VERSION}
ENV LUAROCKS_VERSION 3.0.3

# Update Ubuntu Software repository
RUN apt-get -y update
RUN apt-get -y upgrade
RUN apt-get -y install sudo
RUN apt-get -y install software-properties-common

#Trying to sort libqt4-dev error
RUN add-apt-repository -y ppa:ubuntuhandbook1/ppa
RUN apt-get -y install qt4-dev-tools libqt4-dev libqtcore4 libqtgui4
#Trying to sort ipython package
RUN apt-get -y install python
RUN apt-get -y install python-pip
# Install packages necessary for Lua, Luarocks.
RUN apt-get -y install ${LUA_PACKAGE}
RUN apt-get -y install ${LUA_PACKAGE}-dev
RUN apt-get -y install luajit
RUN apt-get -y install luarocks
RUN apt-get -y install git 

RUN apt-get -y install git bash zip unzip curl
RUN ln -s /usr/bin/luarocks /usr/bin/luarocks-$LUA_VERSION
RUN luarocks install lua-cjson

#busted dependencies 
RUN luarocks install lua_cliargs
RUN luarocks install luafilesystem
RUN luarocks install luasystem
RUN luarocks install dkjson
RUN luarocks install say
RUN luarocks install luassert
RUN luarocks install lua-term 
RUN luarocks install penlight
RUN luarocks install mediator_lua

RUN luarocks install busted
#We now need to install Torch dependencies
RUN git clone https://github.com/AndrewMorgan2/distro.git /usr/local/torch --recursive
RUN cd /usr/local/torch && git init
RUN bash /usr/local/torch/install-deps;

#Install Cuda
RUN apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/3bf863cc.pub 
RUN wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/cuda-ubuntu1804.pin
RUN mv cuda-ubuntu1804.pin /etc/apt/preferences.d/cuda-repository-pin-600
RUN add-apt-repository -y "deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/ /"
RUN apt-get -y update
RUN DEBIAN_FRONTEND=noninteractive apt-get install keyboard-configuration
RUN apt-get -y install cuda && echo 'export PATH=/usr/local/cuda/bin${PATH:+:${PATH}}' >> /root/.bashrc

#Install Test Torch
RUN /usr/local/torch/install.sh -b
RUN . /usr/local/torch/install/bin/torch-activate && /usr/local/torch/test.sh
#CV
RUN git config --global url.https://github.com/.insteadOf git://github.com/
RUN apt-get -y install libmatio4
RUN ln -s /usr/lib/x86_64-linux-gnu/libmatio.so.4 /usr/lib/x86_64-linux-gnu/libmatio.so
RUN git clone https://github.com/VisionLabs/torch-opencv.git
RUN cd torch-opencv && luarocks make cv-scm-1.rockspec
#Matio
RUN /usr/local/torch/install/bin/luarocks install matio

####
ENV LUA_PATH=/usr/local/share/lua/5.3/?.lua;/usr/local/share/lua/5.3/?/init.lua;/usr/local/lib/lua/5.3/?.lua;/usr/local/lib/lua/5.3/?/init.lua;/usr/share/lua/5.3/?.lua;/usr/share/lua/5.3/?/init.lua;/usr/lib/lua/5.3/?.lua;/usr/lib/lua/5.3/?/init.lua;/usr/share/lua/common/?.lua;/usr/share/lua/common/?/init.lua;./?.lua;./?/init.lua
ENV LUA_CPATH=/usr/local/lib/lua/5.3/?.so;/usr/local/lib/lua/5.3/loadall.so;/usr/lib/lua/5.3/?.so;/usr/lib/lua/5.3/loadall.so;./?.so
#Make the env paths in the github