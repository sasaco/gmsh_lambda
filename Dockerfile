# Define function directory
ARG FUNCTION_DIR="/function"

FROM python:buster as build-image

# Install aws-lambda-cpp build dependencies
RUN apt-get update && \
  apt-get install -y \
  g++ \
  make \
  cmake \
  unzip \
  libglu1 \
  libxcursor-dev \
  libxft2 \
  libxinerama1 \
  libfltk1.3-dev \ 
  libfreetype6-dev  \
  libgl1-mesa-dev \
  libocct-foundation-dev \
  libocct-data-exchange-dev 

# Include global arg in this stage of the build
ARG FUNCTION_DIR
# Create function dipip rectory
RUN mkdir -p ${FUNCTION_DIR}

# Copy function code
COPY app/* ${FUNCTION_DIR}

COPY tmp/* /tmp/

# Install the runtime interface client
RUN pip install \
        --target ${FUNCTION_DIR} \
        awslambdaric

# install gmsh
RUN pip install gmsh

# 2021.08.22 現在 import gmsh に失敗するので
# python の参照path に追加
ENV PYTHONPATH=/usr/local/lib/python3.9/site-packages/gmsh-4.8.4-Linux64-sdk/lib/

# WORKDIR 命令は、Dockerfile 内で以降に続く 
# RUN 、 CMD 、 ENTRYPOINT 、 COPY 、 ADD 命令の
# 処理時に（コマンドを実行する場所として）使う 
# 作業ディレクトリworking directory を指定します。
WORKDIR ${FUNCTION_DIR}

# 
ENTRYPOINT [ "/usr/local/bin/python", "-m", "awslambdaric" ]
CMD [ "app.handler" ]
