FROM continuumio/anaconda3:2020.11

COPY requirements.txt /tmp/requirements.txt

# The base image is Debian buster, which is end of life. Its packages are now
# only on archive.debian.org.
RUN sed -i -e 's|deb.debian.org|archive.debian.org|g' \
           -e 's|security.debian.org|archive.debian.org|g' /etc/apt/sources.list && \
    apt-get update && \
    apt-get install -y g++ libgdal-dev libgdal20 gdal-bin && \
    /opt/conda/bin/conda install jupyter -y --quiet && \
    conda install --yes netcdf4 xarray && \
    cd /tmp && pip install -r requirements.txt && \
    apt-get install -y cdo && \
    mkdir /opt/notebooks 
    # conda install --yes -c conda-forge gdal && \

# USER ubuntu

WORKDIR /opt/notebooks

CMD [ "/opt/conda/bin/jupyter","notebook","--notebook-dir=/opt/notebooks", "--ip='*'", "--port=8888","--no-browser", "--allow-root" ]

