#
# CONTAINER=$(docker run -d -p 80 -p 3306 -v $(pwd)/html:/var/www/html -v $(pwd)/mysql:/var/lib/mysql docker-apache-php)
# docker stop $CONTAINER
#
# Based in https://github.com/eugeneware/docker-apache-php.git
# By Eugene Ware <eugene@noblesamurai.com>

FROM ubuntu:14.04
MAINTAINER Agusti Moll

# Keep upstart from complaining
RUN dpkg-divert --local --rename --add /sbin/initctl
RUN ln -sf /bin/true /sbin/initctl

# Update
RUN apt-get update
RUN apt-get -y upgrade

# Basic Requirements
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install mysql-server mysql-client apache2 libapache2-mod-php5 php5-mysql php-apc python-setuptools curl git unzip vim-tiny

# Wordpress Requirements
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install php5-curl php5-gd php5-intl php-pear php5-imagick php5-imap php5-mcrypt php5-memcache php5-ming php5-ps php5-pspell php5-recode php5-sqlite php5-tidy php5-xmlrpc php5-xsl

# mysql config
ADD my.cnf /etc/mysql/conf.d/my.cnf
RUN chmod 664 /etc/mysql/conf.d/my.cnf

# User
RUN useradd -b /var/www -u 1000 devel

# apache config
ENV APACHE_RUN_USER devel
ENV APACHE_RUN_GROUP devel
ENV APACHE_LOG_DIR /var/log/apache2
RUN chown -R devel:devel /var/www/
RUN sed -i -e "s/APACHE_RUN_USER\s*=.*/APACHE_RUN_USER = devel/g" /etc/apache2/envvars
RUN sed -i -e "s/APACHE_RUN_GROUP\s*=.*/APACHE_RUN_GROUP = devel/g" /etc/apache2/envvars

RUN cat /etc/apache2/envvars

# php config
RUN sed -i -e "s/upload_max_filesize\s*=\s*2M/upload_max_filesize = 100M/g" /etc/php5/apache2/php.ini
RUN sed -i -e "s/post_max_size\s*=\s*8M/post_max_size = 100M/g" /etc/php5/apache2/php.ini
RUN sed -i -e "s/short_open_tag\s*=\s*Off/short_open_tag = On/g" /etc/php5/apache2/php.ini

# fix for php5-mcrypt
RUN /usr/sbin/php5enmod mcrypt

# Supervisor Config
RUN mkdir /var/log/supervisor/
RUN /usr/bin/easy_install supervisor
RUN /usr/bin/easy_install supervisor-stdout
ADD ./supervisord.conf /etc/supervisord.conf

# Initialization Startup Script
ADD ./start.sh /start.sh
RUN chmod 755 /start.sh

EXPOSE 3306
EXPOSE 80

CMD ["/bin/bash", "/start.sh"]
