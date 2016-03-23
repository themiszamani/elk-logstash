# Logstash container
FROM bbania/centos:base
MAINTAINER "Bart Bania" <contact@bartbania.com>

ENV LS_HEAP_SIZE=3g
ENV LANG en_US.utf8

RUN yum install -q -y iptables-services git GeoIP-update python-pip

WORKDIR /tmp
RUN wget -q --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/8u73-b02/jdk-8u73-linux-x64.rpm" && \
    wget -q https://download.elastic.co/logstash/logstash/packages/centos/logstash-2.2.1-1.noarch.rpm && \
    yum localinstall -q -y jdk-8u73-linux-x64.rpm && \
    yum localinstall -q -y logstash-2.2.1-1.noarch.rpm && \
    chkconfig logstash off && \
    rm -rf logstash* jdk* && \
    yum -q clean all

# Setup gosu for easier command execution
RUN gpg --keyserver pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
    && curl -q -o /usr/local/bin/gosu -SL "https://github.com/tianon/gosu/releases/download/1.2/gosu-amd64" \
    && curl -q -o /usr/local/bin/gosu.asc -SL "https://github.com/tianon/gosu/releases/download/1.2/gosu-amd64.asc" \
    && gpg --verify /usr/local/bin/gosu.asc \
    && rm /usr/local/bin/gosu.asc \
    && rm -r /root/.gnupg/ \
    && chmod +x /usr/local/bin/gosu

# Supervisor
RUN pip -q install supervisor

# Config files
COPY ./config/rsyncd.conf ./config/rsyncd.secrets /etc/
COPY ./config/supervisord.conf /etc/supervisord.conf
COPY ./config/iptables /etc/sysconfig/iptables
COPY ./config/cron /var/spool/cron/logstash
COPY ./config/init.sh /
COPY ./config/entrypoint.sh /
COPY ./config/patterns /etc/logstash/patterns
COPY ./config/GeoLiteCity.dat ./config/GeoLiteCountry.dat /etc/logstash/
COPY ./config/conf.d /etc/logstash/conf.d

ENV PATH /opt/logstash/bin:$PATH
 
RUN mkdir /root/certs && \
    chmod 600 /etc/rsyncd.secrets && \
    mkdir /var/log/supervisor && \
    chown -R logstash: /etc/logstash /etc/supervisord.conf && \
    cd /opt/logstash/bin/ && \
    ./plugin update logstash-input-beats && \
    ./plugin update logstash-output-elasticsearch

VOLUME /root /etc/logstash

EXPOSE 5044

ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "supervisord", "-c /etc/supervisord.conf" ]

