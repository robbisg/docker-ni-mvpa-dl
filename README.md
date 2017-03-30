# docker-ni-mvpa-dl
Dockerfile for deep learning, neuroimaging and mvpa.

This docker installs tensorflow and keras to be used with the GPU, so be sure to have your driver installed and install also nvidia-docker.
Other neuroimaging software installed are AFNI, FSL using NeuroDebian repo, moreover python nipy packages (nipy, nilearn, sklearn, nitime, mne and pymvpa) are installed.

To build the image:
```bash
docker build -t whatdoyouwant/ni-mvpa-tf:gpu -f Dockerfile .
```

To run the image:
```bash
nvidia-docker run -it -p 8888:8888 -p 6006:6006 -v /home/user:/root/sharedfolder whatdoyouwant/ni-mvpa-tf:gpu bash
```
In the file are exposed jupyter (8888) and tensorboard (6006) ports.
