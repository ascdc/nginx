FROM ubuntu:xenial
MAINTAINER ASCDC <asdc.sinica@gmail.com>

RUN mkdir /script
ADD run.sh /script/run.sh
ADD nginx /etc/init.d/nginx
RUN	chmod +x /etc/init.d/nginx

RUN DEBIAN_FRONTEND=noninteractive && \
	chmod +x /script/*.sh && \
	apt-get -qq update && \
	apt-get -y -qq dist-upgrade && \
	apt-get -qq install -y locales apt-utils && \
	locale-gen en_US.UTF-8 && \
	export LANG=en_US.UTF-8
RUN DEBIAN_FRONTEND=noninteractive && \
	apt-get -qq install -y vim git wget curl sudo autoconf build-essential libtool flex bison doxygen libyajl-dev libgeoip-dev libtool dh-autoreconf libcurl4-gnutls-dev libxml2 libxslt-dev libgd-dev libperl-dev libpcre++-dev libxml2-dev libpango1.0-dev libssl-dev unzip && \
	mkdir /var/cache/nginx && \
	mkdir -p /var/www/html && \
	chown root:www-data /var/www/html && \
	chown www-data:www-data /var/cache/nginx && \
	git clone https://github.com/SpiderLabs/owasp-modsecurity-crs.git /tmp/owasp-modsecurity-crs && \
	git clone https://github.com/SpiderLabs/ModSecurity.git /tmp/ModSecurity && \
	git clone https://github.com/SpiderLabs/ModSecurity-nginx.git /tmp/ModSecurity-nginx && \
	git clone https://github.com/evanmiller/mod_rrd_graph.git /tmp/mod_rrd_graph && \
	git clone https://github.com/oetiker/rrdtool-1.x.git /tmp/rrdtool && \
	cd /tmp/ModSecurity/ && \
	git checkout v3/master && \
	git submodule init && \
	git submodule update && \
	./build.sh && \
	./configure && \
	make && \
	make install && \
	cd /tmp/rrdtool && \
	./configure --prefix=/usr && \
	make && \
	make install && \
	wget -qO- "https://ngxpagespeed.com/install" | bash -s -- --assume-yes --nginx-version latest --additional-nginx-configure-arguments '--prefix=/etc/nginx --user=www-data --group=www-data --sbin-path=/usr/sbin/nginx --modules-path=/usr/lib/nginx/modules --conf-path=/etc/nginx/nginx.conf --error-log-path=/var/log/nginx/error.log --http-log-path=/var/log/nginx/access.log --pid-path=/var/run/nginx.pid --lock-path=/var/run/nginx.lock --http-client-body-temp-path=/var/cache/nginx/client_temp --http-proxy-temp-path=/var/cache/nginx/proxy_temp --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp --http-scgi-temp-path=/var/cache/nginx/scgi_temp --user=nginx --group=nginx --with-http_ssl_module --with-http_realip_module --with-http_addition_module --with-http_sub_module --with-http_dav_module --with-http_flv_module --with-http_mp4_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_random_index_module --with-http_secure_link_module --with-http_stub_status_module --with-http_auth_request_module --with-http_xslt_module=dynamic --with-http_image_filter_module=dynamic --with-http_geoip_module=dynamic --with-http_perl_module=dynamic --with-threads --with-stream --with-stream_ssl_module --with-stream_ssl_preread_module --with-stream_realip_module --with-stream_geoip_module=dynamic --with-http_slice_module --with-mail --with-mail_ssl_module --with-compat --with-file-aio --with-http_mp4_module --with-http_flv_module --with-http_v2_module --add-module=/tmp/ModSecurity-nginx --add-module=/tmp/mod_rrd_graph --with-cc-opt="-O3"' && \
	rm /etc/nginx/nginx.conf && \
	cp /tmp/owasp-modsecurity-crs/rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf.example /tmp/owasp-modsecurity-crs/rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf && \
	cp /tmp/owasp-modsecurity-crs/rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf.example /tmp/owasp-modsecurity-crs/rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf && \
	cp /tmp/owasp-modsecurity-crs/rules/*.data /etc/nginx/ && \
	cat /tmp/ModSecurity/modsecurity.conf-recommended /tmp/owasp-modsecurity-crs/crs-setup.conf.example /tmp/owasp-modsecurity-crs/rules/*.conf > /etc/nginx/rules.conf && \
	sed -i "s/SecRuleEngine.*/SecRuleEngine On/g" /etc/nginx/rules.conf

ADD nginx.conf /etc/nginx/nginx.conf

WORKDIR /var/www/html
ENTRYPOINT ["/script/run.sh"]
