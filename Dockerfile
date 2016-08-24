FROM sameersbn/ubuntu:14.04.20160817
MAINTAINER juha.kovanen@gmail.com

ENV GITLAB_CI_MULTI_RUNNER_VERSION=1.1.4 \
    GITLAB_CI_MULTI_RUNNER_USER=gitlab_ci_multi_runner \
    GITLAB_CI_MULTI_RUNNER_HOME_DIR="/home/gitlab_ci_multi_runner"
ENV GITLAB_CI_MULTI_RUNNER_DATA_DIR="${GITLAB_CI_MULTI_RUNNER_HOME_DIR}/data"

RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv E1DD270288B4E6030699E45FA1715D88E1DF1F24 \
 && echo "deb http://ppa.launchpad.net/git-core/ppa/ubuntu trusty main" >> /etc/apt/sources.list \
 && apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y \
      git-core openssh-client curl libapparmor1 \
 && wget -O /usr/local/bin/gitlab-ci-multi-runner \
      https://gitlab-ci-multi-runner-downloads.s3.amazonaws.com/v${GITLAB_CI_MULTI_RUNNER_VERSION}/binaries/gitlab-ci-multi-runner-linux-amd64 \
 && chmod 0755 /usr/local/bin/gitlab-ci-multi-runner \
 && adduser --disabled-login --gecos 'GitLab CI Runner' ${GITLAB_CI_MULTI_RUNNER_USER} \
 && sudo -HEu ${GITLAB_CI_MULTI_RUNNER_USER} ln -sf ${GITLAB_CI_MULTI_RUNNER_DATA_DIR}/.ssh ${GITLAB_CI_MULTI_RUNNER_HOME_DIR}/.ssh \
 && rm -rf /var/lib/apt/lists/*

ENV MAVEN_HOME=/usr/share/maven
RUN cd /tmp \
   && wget https://archive.apache.org/dist/maven/maven-3/3.3.9/binaries/apache-maven-3.3.9-bin.tar.gz \
   && wget https://archive.apache.org/dist/maven/maven-3/3.3.9/binaries/apache-maven-3.3.9-bin.tar.gz.sha1 \
   && echo -e "$(cat apache-maven-3.3.9-bin.tar.gz.sha1)  apache-maven-3.3.9-bin.tar.gz" | sha1sum -c - \
   && tar zxf apache-maven-3.3.9-bin.tar.gz \
   && rm -rf apache-maven-3.3.9-bin.tar.gz \
   && rm -rf *.sha1 \
   && mv ./apache-maven-3.3.9 /usr/share/maven \
   && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn

RUN apt-get install -y git wget nano

# remove download archive files
RUN apt-get clean

# set shell variables for java installation
ENV java_version 1.8.0_77
ENV filename jdk-8u77-linux-x64.tar.gz
ENV downloadlink http://download.oracle.com/otn-pub/java/jdk/8u77-b03/$filename

# download java, accepting the license agreement
RUN wget --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" -O /tmp/$filename $downloadlink

# unpack java
RUN mkdir /opt/java-oracle && tar -zxf /tmp/$filename -C /opt/java-oracle/
ENV JAVA_HOME /opt/java-oracle/jdk$java_version
ENV PATH $JAVA_HOME/bin:$PATH

# configure symbolic links for the java and javac executables
RUN update-alternatives --install /usr/bin/java java $JAVA_HOME/bin/java 20000 && update-alternatives --install /usr/bin/javac javac $JAVA_HOME/bin/javac 20000

COPY entrypoint.sh /sbin/entrypoint.sh
RUN chmod 755 /sbin/entrypoint.sh

VOLUME ["${GITLAB_CI_MULTI_RUNNER_DATA_DIR}"]
WORKDIR "${GITLAB_CI_MULTI_RUNNER_HOME_DIR}"
ENTRYPOINT ["/sbin/entrypoint.sh"]
