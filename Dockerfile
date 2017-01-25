FROM ubuntu:16.04
MAINTAINER Mike de Heij

RUN echo 'deb http://download.videolan.org/pub/debian/stable/ /' >> /etc/apt/sources.list
RUN echo 'deb-src http://download.videolan.org/pub/debian/stable/ /' >> /etc/apt/sources.list
RUN echo 'deb http://archive.ubuntu.com/ubuntu xenial main multiverse' >> /etc/apt/sources.list

RUN apt-get update
RUN apt-get -y upgrade
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install wget inotify-tools
RUN wget -O - https://download.videolan.org/pub/debian/videolan-apt.asc | apt-key add -
RUN apt-get update

# Need this environment variable otherwise mysql will prompt for passwords
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install apache2 wget php7.0 php7.0-json php7.0-curl php7.0-mysql pwgen lame libvorbis-dev vorbis-tools opus-tools flac libmp3lame-dev libavcodec-extra* libfaac-dev libtheora-dev libvpx-dev libav-tools git sudo libapache2-mod-php7.0 php7.0-xml

# Install composer for dependency management
RUN php -r "readfile('https://getcomposer.org/installer');" | php && \
    mv composer.phar /usr/local/bin/composer

# For local testing / faster builds
# COPY master.tar.gz /opt/master.tar.gz
ADD https://github.com/ampache/ampache/archive/master.tar.gz /opt/master.tar.gz

# extraction / installation
RUN rm -rf /var/www/* && \
    tar -C /var/www -xf /opt/master.tar.gz ampache-master --strip=1 && \
    cd /var/www && composer install --prefer-source --no-interaction && \
    chown -R www-data /var/www

ADD run.sh /run.sh
RUN chmod 755 /*.sh

# setup apache with default ampache vhost
ADD 001-ampache.conf /etc/apache2/sites-available/
RUN rm -rf /etc/apache2/sites-enabled/*
RUN ln -s /etc/apache2/sites-available/001-ampache.conf /etc/apache2/sites-enabled/
RUN a2enmod rewrite

# Add job to cron to clean the library every night
RUN echo '30 7    * * *   www-data php /var/www/bin/catalog_update.inc' >> /etc/crontab

VOLUME ["/media"]
VOLUME ["/var/www/config"]
VOLUME ["/var/www/themes"]
EXPOSE 80

CMD ["/run.sh"]
