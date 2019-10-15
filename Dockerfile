FROM tomcat:8.5.46

RUN echo "Australia/ACT" > /etc/timezone \
    && cp /usr/share/zoneinfo/Australia/ACT /etc/localtime \
    && sed -i 's/\<Connector /& URIEncoding="UTF-8" /' /usr/local/tomcat/conf/server.xml \
    && apt-get update && apt-get --assume-yes install node.js \
    && apt-get clean

COPY  nsl-editor.war /usr/local/tomcat/webapps/"nsl#editor.war"
VOLUME /etc/nsl
EXPOSE 8080/tcp
CMD  ["catalina.sh", "run"]