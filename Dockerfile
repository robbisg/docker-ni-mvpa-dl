# This Dockerfile is based on the dockerfile 'fmriprep' from the Poldrack
# Lab (https://github.com/poldracklab/fmriprep). The jupyter notebook foundation
# is based on jupyter/docker-stacks's base-notebook.
#
# This means that the same copyrights apply to this Dockerfile, as they do for
# the above mentioned dockerfiles. For more information see:
# https://github.com/miykael/nipype_env

FROM jupyter/base-notebook
FROM nvidia/cuda:8.0-cudnn5-devel-ubuntu14.04

# Based on floydhub/deep-learning docker and Michael Notter ni docker
MAINTAINER Roberto Guidotti <rob.guidotti@gmail.com>

ARG TENSORFLOW_VERSION=1.0.*
ARG TENSORFLOW_ARCH=gpu
ARG KERAS_VERSION=1.2.0

RUN echo -e "\n**********************\nNVIDIA Driver Version\n**********************\n" && \
	cat /proc/driver/nvidia/version && \
	echo -e "\n**********************\nCUDA Version\n**********************\n" && \
	nvcc -V && \
	echo -e "\n\nBuilding your Deep Learning Docker Image...\n"

#---------------------------------------------
# Update OS dependencies and setup neurodebian
#---------------------------------------------
USER root

RUN apt-get update && \
    apt-get install -yq --no-install-recommends bzip2 \
                                                ca-certificates \
                                                curl \
                                                git \
                                                tree \
                                                unzip \
                                                wget \
                                                xvfb \
                                                zip
ENV NEURODEBIAN_URL http://neuro.debian.net/lists/jessie.de-md.full
RUN curl -sSL $NEURODEBIAN_URL | sudo tee /etc/apt/sources.list.d/neurodebian.sources.list && \
    apt-key adv --recv-keys --keyserver hkp://pgp.mit.edu:80 0xA5D32F012649A5A9 && \
    apt-get update -qq

# Install some dependencies from floydhub
RUN apt-get update && apt-get install -y \
		bc \
		build-essential \
		cmake \
		curl \
		g++ \
		gfortran \
		git \
		libffi-dev \
		libfreetype6-dev \
		libhdf5-dev \
		libjpeg-dev \
		liblcms2-dev \
		libopenblas-dev \
		liblapack-dev \
		libopenjpeg2 \
		libpng12-dev \
		libssl-dev \
		libtiff5-dev \
		libwebp-dev \
		libzmq3-dev \
		nano \
		pkg-config \
		python-dev \
		software-properties-common \
		unzip \
		vim \
		wget \
		zlib1g-dev \
		qt5-default \
		libvtk6-dev \
		zlib1g-dev \
		libjpeg-dev \
		libwebp-dev \
		libpng-dev \
		libtiff5-dev \
		libjasper-dev \
		libopenexr-dev \
		libgdal-dev \
		libdc1394-22-dev \
		libavcodec-dev \
		libavformat-dev \
		libswscale-dev \
		libtheora-dev \
		libvorbis-dev \
		libxvidcore-dev \
		libx264-dev \
		yasm \
		libopencore-amrnb-dev \
		libopencore-amrwb-dev \
		libv4l-dev \
		libxine2-dev \
		libtbb-dev \
		libeigen3-dev \
		python-dev \
		python-tk \
		python-numpy \
		python3-dev \
    python-h5py \
		python3-tk \
		python3-numpy \
		ant \
		default-jdk \
		doxygen \
		&& \
	apt-get clean && \
	apt-get autoremove && \
	rm -rf /var/lib/apt/lists/* && \
# Link BLAS library to use OpenBLAS using the alternatives mechanism (https://www.scipy.org/scipylib/building/linux.html#debian-ubuntu)
	update-alternatives --set libblas.so.3 /usr/lib/openblas-base/libblas.so.3

# Install other python dependencies
RUN apt-get update && apt-get install -y \
		python-numpy \
		python-scipy \
		python-nose \
		python-h5py \
		python-skimage \
		python-matplotlib \
		python-pandas \
		python-sklearn \
		python-sympy \
		&& \
	apt-get clean && \
	apt-get autoremove && \
	rm -rf /var/lib/apt/lists/*



#----------------------------------------------------
# Update and install conda dependencies for python2.7
#----------------------------------------------------
USER $NB_USER

# Make sure that necessary packages are installed
RUN conda create -yq -n python2 python=2.7 ipython \
                                           cython \
		                                       ipykernel \
		                                       path.py \
		                                       Pillow \
		                                       pygments \
		                                       six \
		                                       sphinx \
		                                       wheel \
		                                       zmq \
                                           tqdm \
                                           dipy \
                                           graphviz \
                                           joblib \
                                           jupyter \
                                           matplotlib \
                                           nb_conda \
                                           nb_conda_kernels \
                                           nilearn \
                                           notebook \
                                           pandas \
                                           scikit-learn \
                                           nibabel \
                                           mne \
                                           statsmodel
                                           pip \
                                           scikit-image \
                                           seaborn && \
    conda clean -tipsy

# Tensorflow setup
RUN source activate python2 && echo "Conda Environment Activated"
RUN pip --no-cache-dir install \
	https://storage.googleapis.com/tensorflow/linux/${TENSORFLOW_ARCH}/tensorflow_${TENSORFLOW_ARCH}-${TENSORFLOW_VERSION}-cp27-none-linux_x86_64.whl
  # Install keras
RUN pip --no-cache-dir install git+git://github.com/fchollet/keras.git@${KERAS_VERSION}
RUN source deactivate && echo "Conda Environment Closed"

# Make sure that Python2 is loaded before Python3
ENV PATH=/opt/conda/envs/python2/bin:$PATH

# Import matplotlib the first time to build the font cache.
ENV XDG_CACHE_HOME /home/$NB_USER/.cache/
RUN MPLBACKEND=Agg $CONDA_DIR/envs/python2/bin/python -c "import matplotlib.pyplot"

# Activate ipywidgets extension in the environment that runs the notebook server
RUN jupyter nbextension enable --py widgetsnbextension --sys-prefix

# Install Python 2 kernel spec globally to avoid permission problems when NB_UID
# switching at runtime and to allow the notebook server running out of the root
# environment to find it. Also, activate the python2 environment upon kernel
# launch.
USER root
RUN pip install kernda --no-cache && \
    $CONDA_DIR/envs/python2/bin/python -m ipykernel install && \
    kernda -o -y /usr/local/share/jupyter/kernels/python2/kernel.json && \
    pip uninstall kernda -y

#---------------------------------------------
# Install graphviz and update pip dependencies
#---------------------------------------------
USER root
RUN apt-get install -yq --no-install-recommends graphviz
USER $NB_USER
RUN pip install --upgrade --quiet pip && \
    pip install --upgrade --quiet nipy \
                                  rdflib \
                                  pprocess \
                --ignore-installed && \
    rm -rf ~/.cache/pip

#------------------------------------------
# Install newest version of Nipype (github)
#------------------------------------------
USER $NB_USER
# Install Nipype dependencies
RUN conda install -yq -n python2 nipype

# Remove Nipype and install newest version from github
RUN conda remove -yq -n python2 nipype && \
    easy_install --upgrade nipype

# Expose tensorboard and jupyter ports
EXPOSE 6006 8888
#----------------------------------------
# Clear apt cache and other empty folders
#----------------------------------------
USER root
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /boot /media /mnt /srv
