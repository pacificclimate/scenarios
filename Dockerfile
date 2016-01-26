FROM registry.pcic.uvic.ca/apache-geospatial
MAINTAINER Basil Veerman <bveerman@uvic.ca>

WORKDIR /

## INSTALL GENIMAGE

RUN curl -L https://github.com/pacificclimate/genimage/archive/master.tar.gz -o genimage.tar.gz && tar xvf genimage.tar.gz
RUN cd /genimage-master/core && make && make install

ENV GENIMAGE_BIN /usr/local/bin/genimage
ENV GENIMAGE_CFG /usr/local/etc/genimage.cfg

## Install Scenarios

RUN apt-get install -y cpanminus
RUN cpanm File::Slurp Geo::Proj4 Language::Functional Text::CSV_XS

COPY . /usr/local/lib/scenarios
WORKDIR /usr/local/lib/scenarios

ADD cfg/scenarios.conf /etc/apache2/misc/scenarios.conf
ADD cfg/apache.conf /etc/apache2/sites-available/000-default.conf
ADD cfg/genimage.cfg ${GENIMAGE_CFG}
RUN mkdir /var/www/html/tools; \
    ln -s /usr/local/lib/scenarios/css /var/www/html/tools/css; \
    ln -s /usr/local/lib/scenarios/img /var/www/html/tools/img; \
    ln -s /usr/local/lib/scenarios/lib /var/www/html/tools/lib

RUN ./init.sh

RUN ln -sf /dev/stdout /var/log/apache2/access.log; \
    ln -sf /dev/stderr /var/log/apache2/error.log

CMD ["apachectl", "-d /etc/apache2/", "-f apache2.conf", "-e info", "-DFOREGROUND"]
