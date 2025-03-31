FROM   registry.access.redhat.com/ubi8/ubi:8.0

ENV	  JAVA_OPTIONS -Xmx512m

RUN   yum install -y --disableplugin=subscription-manager java-1.8.0-openjdk-headless && \
      yum clean all --disableplugin=subscription-manager -y && \
      useradd wildfly && \
      mkdir -p /opt/app-root/bin && \
      chgrp -R 0 /opt/app-root && \
      chmod -R g=u /opt/app-root

ADD   https://github.com/RedHatTraining/DO288-apps/releases/download/OCP-4.1-1/hello-java.jar /opt/app-root/bin/

COPY  run-app.sh /opt/app-root/bin/

EXPOSE 8080

USER  1001

CMD   /opt/app-root/bin/run-app.sh
