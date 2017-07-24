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
                                                zip

ENV NEURODEBIAN_URL http://neuro.debian.net/lists/xenial.de-m.full
RUN curl -sSL $NEURODEBIAN_URL | tee /etc/apt/sources.list.d/neurodebian.sources.list && \
    apt-key adv --recv-keys --keyserver hkp://pgp.mit.edu:80 0xA5D32F012649A5A9 && \
    apt-get update -qq


#---------------------
# Install FSL and AFNI
#---------------------

RUN apt-get update && \
    apt-get install -y -qq --no-install-recommends fsl-core fsl-atlases afni
ENV FSLDIR=/usr/share/fsl/5.0 \
    FSLOUTPUTTYPE=NIFTI_GZ \
    FSLMULTIFILEQUIT=TRUE \
    POSSUMDIR=/usr/share/fsl/5.0 \
    LD_LIBRARY_PATH=/usr/lib/fsl/5.0:$LD_LIBRARY_PATH \
    FSLTCLSH=/usr/bin/tclsh \
    FSLWISH=/usr/bin/wish \
    AFNI_MODELPATH=/usr/lib/afni/models \
    AFNI_IMSAVE_WARNINGS=NO \
    AFNI_TTATLAS_DATASET=/usr/share/afni/atlases \
    AFNI_PLUGINPATH=/usr/lib/afni/plugins \
    PATH=/usr/lib/fsl/5.0:/usr/lib/afni/bin:$PATH

RUN echo ". /etc/fsl/5.0/fsl.sh" >> /root/.bashrc

## INSTALL R
RUN add-apt-repository 'deb [arch=amd64,i386] https://cran.rstudio.com/bin/linux/ubuntu xenial/'
RUN apt-get update && apt-get install -yq --allow-unauthenticated r-base r-base-dev



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
