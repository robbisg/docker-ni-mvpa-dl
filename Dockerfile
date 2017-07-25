# This Dockerfile is based on the dockerfile 'fmriprep' from the Poldrack
# Lab (https://github.com/poldracklab/fmriprep). The jupyter notebook foundation
# is based on jupyter/docker-stacks's base-notebook.
#
# This means that the same copyrights apply to this Dockerfile, as they do for
# the above mentioned dockerfiles. For more information see:
# https://github.com/miykael/nipype_env
FROM nvidia/cuda:8.0-cudnn5-devel-ubuntu16.04
FROM tensorflow/tensorflow:latest-gpu


# Based on floydhub/deep-learning docker and Michael Notter ni docker
MAINTAINER Roberto Guidotti <rob.guidotti@gmail.com>


RUN pip install ipython \
                                           cython \
                                           dipy \
																					 tqdm \
                                           graphviz \
                                           joblib \
                                           jupyter \
                                           matplotlib \
                                           nilearn \
                                           notebook \
                                           pandas \
                                           pip \
																					 scikit-learn \
																					 nitime \
																					 mne \
																					 statsmodels \
																					 spectrum \
                                           scikit-image \
                                           seaborn



#---------------------------------------------
# Update OS dependencies and setup neurodebian
#---------------------------------------------
USER root
RUN apt-get update && apt-get install -yq --no-install-recommends bzip2 \
                                                ca-certificates \
                                                curl \
                                                git \
                                                tree \
                                                unzip \
                                                wget \
                                                xvfb \
						swig \
						apt-transport-https \
                                                tcsh

RUN apt-get install -yq --no-install-recommends build-essential gfortran

ENV NEURODEBIAN_URL http://neuro.debian.net/lists/xenial.de-m.full
RUN curl -sSL $NEURODEBIAN_URL | tee /etc/apt/sources.list.d/neurodebian.sources.list && \
    apt-key adv --recv-keys --keyserver hkp://pool.sks-keyservers.net:80 0xA5D32F012649A5A9 && \
    apt-get update -qq


USER root

#-------------- 4dfp suite
RUN wget ftp://imaging.wustl.edu/pub/raichlab/4dfp_tools/4dfp_scripts.tar

ENV NILSRC=/usr/lib/4dfp/src
ENV RELEASE=/usr/lib/4dfp/release

RUN mkdir -p $NILSRC
RUN mkdir -p $RELEASE

RUN git clone https://github.com/robbisg/4dfp_tools.git $NILSRC
RUN groupadd program
RUN cd $NILSRC && tcsh $NILSRC/make_nil-tools.csh

RUN mv 4dfp_scripts.tar $RELEASE
RUN cd $RELEASE && tar -xvf 4dfp_scripts.tar -C $RELEASE

ENV PATH=$RELEASE:$PATH

#---------------------
# Install FSL
#---------------------

RUN apt-get update && \
    apt-get install -y -qq --no-install-recommends fsl-core fsl-atlases
ENV FSLDIR=/usr/share/fsl/5.0 \
    FSLOUTPUTTYPE=NIFTI_GZ \
    FSLMULTIFILEQUIT=TRUE \
    POSSUMDIR=/usr/share/fsl/5.0 \
    LD_LIBRARY_PATH=/usr/lib/fsl/5.0:$LD_LIBRARY_PATH \
    FSLTCLSH=/usr/bin/tclsh \
    FSLWISH=/usr/bin/wish \
    PATH=/usr/lib/fsl/5.0:$PATH

RUN echo ". /etc/fsl/5.0/fsl.sh" >> /root/.bashrc

#-------------
# Install AFNI
#-------------

RUN apt-get update
RUN apt-get install -y tcsh xfonts-base python-qt4       \
                        gsl-bin netpbm gnome-tweak-tool   \
                        libjpeg62 xvfb xterm vim curl \
			libglu1-mesa-dev libglw1-mesa     \
                        libxm4 build-essential

RUN curl -O https://afni.nimh.nih.gov/pub/dist/bin/linux_ubuntu_16_64/@update.afni.binaries
RUN mkdir /afni
RUN tcsh @update.afni.binaries -bindir /afni -package linux_ubuntu_16_64  -do_extras

RUN mkdir /afni/R
RUN echo 'export R_LIBS=/afni/R' >> ~/.bashrc
ENV PATH "$PATH:/afni"
ENV PATH "$PATH:/afni/R"
RUN curl -O https://afni.nimh.nih.gov/pub/dist/src/scripts_src/@add_rcran_ubuntu.tcsh
RUN tcsh @add_rcran_ubuntu.tcsh
RUN rPkgsInstall -pkgs ALL


# Install python libs

RUN apt-get install -yq --no-install-recommends graphviz
USER $NB_USER
RUN pip install --upgrade --quiet pip && \
    pip install --upgrade --quiet nipy \
                                  rdflib \
																	h5py \
                                  pprocess \
                --ignore-installed && \
    rm -rf ~/.cache/pip
RUN pip --no-cache-dir install git+git://github.com/PyMVPA/PyMVPA.git

ARG KERAS_VERSION=1.2.0
RUN pip --no-cache-dir install git+git://github.com/fchollet/keras.git@${KERAS_VERSION}



#----------------------------------------
# Clear apt cache and other empty folders
#----------------------------------------
USER root
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /boot /media /mnt /srv

# Expose Ports for TensorBoard (6006), Ipython (8888)
EXPOSE 6006 8888

CMD ["/bin/bash"]
