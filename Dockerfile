ARG CUDA_VERSION="12.4.1"
ARG CUDNN_VERSION=""
ARG UBUNTU_VERSION="22.04"
ARG DOCKER_FROM=pytorch/pytorch:2.6.0-cuda12.4-cudnn9-runtime
ARG GRADIO_PORT=7860

FROM $DOCKER_FROM AS base

WORKDIR /

# Environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC
ENV PYTHON_VERSION=3.12
ENV CONDA_DIR=/opt/conda
ENV PATH="$CONDA_DIR/bin:$PATH"
# ENV NUM_GPUS=1
ENV DOWNLOAD_MODELS="all"

# Install dependencies required for Miniconda
RUN apt-get update -y && \
    apt-get install -y wget bzip2 ca-certificates git curl && \
    apt-get install nodejs -y && \
    apt-get install -y --no-install-recommends \
    build-essential \
    ninja-build \
    ca-certificates \
    cmake \
    curl \
    emacs \
    git \
    jq \
    libcurl4-openssl-dev \
    libglib2.0-0 \
    libgl1-mesa-glx \
    libsm6 \
    libssl-dev \
    libxext6 \
    libxrender-dev \
    software-properties-common \
    openssh-server \
    openssh-client \
    git-lfs \
    vim \
    zip \
    unzip \
    zlib1g-dev \
    libc6-dev \
    && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*


ENV CUDA_HOME=/usr/local/cuda
ENV LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH
ENV PATH="/opt/conda/envs/pyenv/bin:$PATH"

# Create env and install packages using existing conda
RUN conda create -n pyenv python=3.12 -y && \
    conda install -n pyenv -c conda-forge openmpi mpi4py -y

# Define PyTorch versions via arguments
ARG PYTORCH="2.6.0"
ARG CUDA="124"

# Install PyTorch with specified version and CUDA
RUN $CONDA_DIR/bin/conda run -n pyenv \
    pip install torch==$PYTORCH torchvision torchaudio --index-url https://download.pytorch.org/whl/cu$CUDA

RUN $CONDA_DIR/bin/conda install -n pyenv nvidia/label/cuda-12.4.1::cuda-nvcc

RUN $CONDA_DIR/bin/conda run -n pyenv pip install setuptools
# COPY exllamav2-0.2.7+cu121.torch2.5.0-cp312-cp312-linux_x86_64.whl .
COPY exllamav2-0.2.8+cu124.torch2.6.0-cp312-cp312-win_amd64.whl .
# RUN $CONDA_DIR/bin/conda run -n pyenv pip install exllamav2-0.2.7+cu121.torch2.5.0-cp312-cp312-linux_x86_64.whl
RUN $CONDA_DIR/bin/conda run -n pyenv pip install exllamav2-0.2.8+cu124.torch2.6.0-cp312-cp312-win_amd64.whl

# Install git lfs
RUN apt-get update && apt-get install -y git-lfs && git lfs install

# Install nginx
RUN apt-get update && \
    apt-get install -y nginx

COPY docker/default /etc/nginx/sites-available/default

# Add Jupyter Notebook
RUN pip install jupyterlab ipywidgets jupyter-archive jupyter_contrib_nbextensions

# RUN pip install -U "huggingface_hub[cli]"
RUN $CONDA_DIR/bin/conda run -n pyenv \
    pip install -U huggingface_hub

EXPOSE 8888

# Tensorboard
# EXPOSE 6006 

# Debug
# RUN $CONDA_DIR/bin/conda run -n pyenv \
#     pip install debugpy

# EXPOSE 5678


# Copy the entire project
COPY --chmod=755 . /YuE-exllamav2-UI

COPY --chmod=755 docker/initialize.sh /initialize.sh
COPY --chmod=755 docker/entrypoint.sh /entrypoint.sh

# Normalize line endings just in case they are CRLF
RUN sed -i 's/\r$//' /initialize.sh /entrypoint.sh

# Expose the Gradio port
EXPOSE $GRADIO_PORT

CMD [ "/initialize.sh" ]
