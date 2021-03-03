FROM golang:1.15-buster as configurability
MAINTAINER brian.wilkinson@1and1.co.uk
WORKDIR /go/src/github.com/1and1internet/configurability
RUN git clone https://github.com/1and1internet/configurability.git . \
	&& make main apache2 php \
	&& echo "configurability successfully built"

FROM alpine as ioncube_loader
RUN apk add git \
	&& git -c http.sslVerify=false clone https://git.dev.glo.gb/cloudhostingpublic/ioncube_loader \
	&& tar zxf ioncube_loader/ioncube_loaders_lin_x86-64.tar.gz


FROM 1and1internet/debian-9-apache
MAINTAINER brian.wilkinson@1and1.co.uk
ARG DEBIAN_FRONTEND=noninteractive
ARG PHPVER=7.3
COPY files /
COPY --from=configurability /go/src/github.com/1and1internet/configurability/bin/configurator /usr/bin/configurator
COPY --from=configurability /go/src/github.com/1and1internet/configurability/bin/plugins/* /opt/configurability/goplugins/
RUN \
    apt-get update && \
    apt-get install -y imagemagick graphicsmagick curl && \
    apt-get install -y libapache2-mod-php${PHPVER} \
            php${PHPVER}-bcmath \
            php${PHPVER}-bz2 \
            php${PHPVER}-cli \
            php${PHPVER}-common \
            php${PHPVER}-curl \
            php${PHPVER}-dba \
            php${PHPVER}-gd \
            php${PHPVER}-gmp \
            php${PHPVER}-imap \
            php${PHPVER}-intl \
            php${PHPVER}-ldap \
            php${PHPVER}-mbstring \
            php${PHPVER}-mysql \
            php${PHPVER}-odbc \
            php${PHPVER}-pgsql \
            php${PHPVER}-recode \
            php${PHPVER}-snmp \
            php${PHPVER}-soap \
            php${PHPVER}-sqlite \
            php${PHPVER}-tidy \
            php${PHPVER}-xml \
            php${PHPVER}-xmlrpc \
            php${PHPVER}-xsl \
            php${PHPVER}-zip \
            php${PHPVER}-imagick && \
    apt-get install -y php-gnupg php-mongodb php-fxsl && \
    mkdir /tmp/composer/ && \
    cd /tmp/composer && \
    curl -sS https://getcomposer.org/installer | php && \
    mv composer.phar /usr/local/bin/composer && \
    chmod a+x /usr/local/bin/composer && \
    cd / && \
    rm -rf /tmp/composer && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/* && \
    sed -i -e 's/max_execution_time = 30/max_execution_time = 300/g' /etc/php/${PHPVER}/apache2/php.ini && \
    sed -i -e 's/upload_max_filesize = 2M/upload_max_filesize = 256M/g' /etc/php/${PHPVER}/apache2/php.ini && \
    sed -i -e 's/post_max_size = 8M/post_max_size = 512M/g' /etc/php/${PHPVER}/apache2/php.ini && \
    sed -i -e 's/memory_limit = 128M/memory_limit = 512M/g' /etc/php/${PHPVER}/apache2/php.ini && \
    sed -i -e 's/DirectoryIndex index.html index.cgi index.pl index.php index.xhtml index.htm/DirectoryIndex index.php index.html index.cgi index.pl index.xhtml index.htm/g' /etc/apache2/mods-available/dir.conf && \
    mkdir /tmp/composer/ && \
    cd /tmp/composer && \
    curl -sS https://getcomposer.org/installer | php && \
    mv composer.phar /usr/local/bin/composer && \
    chmod a+x /usr/local/bin/composer && \
    cd / && \
    rm -rf /tmp/composer && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/* && \
    chmod 777 -R /var/www && \
    apache2ctl -t && \
    mkdir -p /run /var/lib/apache2 /var/lib/php && \
    chmod -R 777 /run /var/lib/apache2 /var/lib/php /etc/php/${PHPVER}/apache2/php.ini

COPY --from=ioncube_loader /ioncube/ioncube_loader_lin_${PHPVER}.so /usr/lib/php/20170718/
