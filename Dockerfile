FROM tomcat:8.5.46

RUN echo "Australia/ACT" > /etc/timezone \
    && cp /usr/share/zoneinfo/Australia/ACT /etc/localtime \
    && sed -i 's/\<Connector /& URIEncoding="UTF-8" /' /usr/local/tomcat/conf/server.xml \
    && apt-get update && apt-get --assume-yes install node.js \
    && apt-get clean
RUN  addgroup --gid 5000 nsl_user; adduser --system --quiet --disabled-login --disabled-password --uid 5000 --no-create-home nsl_user --ingroup nsl_user
COPY  nsl-editor.war /usr/local/tomcat/webapps/"nsl#editor.war"
VOLUME /etc/nsl
EXPOSE 8080/tcp
USER nsl_user
#CMD /bin/bash
CMD  ["catalina.sh", "run"]