### docker build --pull -t acme/aos-api-envs -t acme/aos-api-envs:v3.2 .
FROM registry.access.redhat.com/rhel7
MAINTAINER Red Hat Systems Engineering <refarch-feedback@redhat.com>

### Atomic/OpenShift Labels
### https://github.com/projectatomic/ContainerApplicationGenericLabels
LABEL Name="acme/aos-api-envs" \
      Vendor="Acme Corp" \
      Version="3.2" \
      Release="7" \
      build-date="2016-10-12T14:12:54.553894Z" \
      url="https://www.acme.io" \
      summary="Acme Corp's aos-api-envs App" \
      description="aos-api-envs App will do ....." \
      RUN='docker run -tdi --name ${NAME} ${IMAGE}' \
      STOP='docker stop ${NAME}' \
      io.k8s.description="aos-api-envs App will do ....." \
      io.k8s.display-name="aos-api-envs App" \
      io.openshift.expose-services="" \
      io.openshift.tags="Acme,aos-api-envs,aos-api-envsapp"

### Atomic Help File - Write in Markdown, it will be converted to man format at build time.
### https://github.com/projectatomic/container-best-practices/blob/master/creating/help.adoc
COPY help.md user_setup /tmp/

RUN yum clean all && \
    yum-config-manager --disable \* && \
### Add necessary Red Hat repos here
    yum-config-manager --enable rhel-7-server-rpms,rhel-7-server-optional-rpms && \
    yum -y update-minimal --security --sec-severity=Important --sec-severity=Critical --setopt=tsflags=nodocs && \
### help markdown to man conversion
### Add your package needs to this installation line
    yum -y install --setopt=tsflags=nodocs golang-github-cpuguy83-go-md2man iputils bind-utils && \
    go-md2man -in /tmp/help.md -out /help.1 && yum -y remove golang-github-cpuguy83-go-md2man && \
### EPEL needs
#    curl -o epel-release-latest-7.noarch.rpm -SL https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm \
#            --retry 9 --retry-max-time 0 -C - && \
#    rpm -ivh epel-release-latest-7.noarch.rpm && rm epel-release-latest-7.noarch.rpm && \
#    yum -y install --setopt=tsflags=nodocs jq && \
#    yum-config-manager --disable epel && \
    yum clean all

### Setup user for build execution and application runtime
ENV APP_ROOT=/opt/app-root \
    USER_NAME=default \
    USER_UID=10001
ENV APP_HOME=${APP_ROOT}/src  PATH=$PATH:${APP_ROOT}/bin
RUN mkdir -p ${APP_HOME}
COPY bin/ ${APP_ROOT}/bin/
RUN chmod -R ug+x ${APP_ROOT}/bin /tmp/user_setup && \
    /tmp/user_setup

####### Add app-specific needs below. #######
### if COPYing or using files that require permission mods, do so before leaving root USER
# RUN chown -R ${USER_UID}:0 /run/httpd /etc/httpd /var/log/httpd && chmod -R g+rw /run/httpd /etc/httpd /var/log

### Containers should NOT run as root as a best practice
EXPOSE 8081
USER ${USER_UID}
WORKDIR ${APP_ROOT}
CMD run