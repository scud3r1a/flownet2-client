## Note: Our Caffe version does not work with CuDNN 6
FROM nvidia/cuda:8.0-cudnn5-devel-ubuntu16.04

## Put everything in some subfolder
WORKDIR "/flownet2"

## The build context contains some files which make the raw FlowNet2
## repo fit for Docker
COPY FN2_Makefile.config ./

## Container's mount point for the host's input/output folder
VOLUME "/input-output"

## 1. Install packages
## 2. Download and install CUDA driver
## 3. Download and build DispNet/FlowNet Caffe distro
## 4. Remove some now unused packages and clean up (for a smaller image)
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
            module-init-tools \
            build-essential \
            ca-certificates \
            wget \
            git \
            libatlas-base-dev \
            libboost-all-dev \
            libgflags-dev \
            libgoogle-glog-dev \
            libhdf5-serial-dev \
            libleveldb-dev \
            liblmdb-dev \
            libopencv-dev \
            libprotobuf-dev \
            libsnappy-dev \
            protobuf-compiler \
            python-dev \
            python-numpy \
            python-scipy \
            python-protobuf \
            python-pillow \
            python-skimage

# Build flownet2
COPY FN2_run-flownet-docker.py ./
RUN git clone https://github.com/lmb-freiburg/flownet2 \
    && cp ./FN2_Makefile.config ./flownet2/Makefile.config \
    && cp ./FN2_run-flownet-docker.py ./flownet2/scripts/run-flownet-docker.py \
    && cd flownet2 \
    && rm -rf .git \
    && cd models \
    && bash download-models.sh \
    && rm flownet2-models.tar.gz \
    && cd .. \
    && make -j`nproc` \
    && make -j`nproc` pycaffe

# Add flownet2image
# RUN git clone https://github.com/scud3r1a/flownet2image.git
RUN apt-get install -y python python-pip
RUN pip install \
        opencv-python \
        opencv-contrib-python \
        pillow \
        tqdm
COPY FN2_run-flownet-docker-image.py ./
RUN cp ./FN2_run-flownet-docker-image.py ./flownet2/scripts/run-flownet-docker-image.py
RUN git clone https://github.com/scud3r1a/flownet2image.git \
    && cp flownet2image/flow2image.py ./flownet2/scripts/flow2image.py \
    && rm -rf flownet2image