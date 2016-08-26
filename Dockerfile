FROM cubbles/base.abstract-nginx:0.1.0

MAINTAINER Hd Böhlau hans-dieter.boehlau@incowia.com

# provide service resources
COPY ./opt/gateway /opt/gateway

# provide entrypoint
COPY ./entrypoint.sh /entrypoint.sh

EXPOSE 80 443
WORKDIR $nginxHome

ENTRYPOINT ["/entrypoint.sh"]
CMD ["nginx"]
