FROM ubuntu:22.04 AS hadoop-base

RUN apt update -y && apt upgrade -y && \
    apt install -y openjdk-8-jdk cron ssh sudo curl wget

ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-arm64
ENV HADOOP_HOME=/usr/local/hadoop
ENV ZOOKEEPER_HOME=/usr/local/zookeeper
ENV PATH=$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$ZOOKEEPER_HOME/bin:$PATH

RUN addgroup hadoop && \
    adduser --disabled-password --ingroup hadoop hadoop && \
    echo "hadoop ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

ADD https://dlcdn.apache.org/hadoop/common/hadoop-3.3.6/hadoop-3.3.6.tar.gz /tmp/
RUN tar -xzf /tmp/hadoop-3.3.6.tar.gz -C /usr/local/ && \
    mv /usr/local/hadoop-3.3.6 $HADOOP_HOME && \
    chown -R hadoop:hadoop $HADOOP_HOME && \
    rm /tmp/hadoop-3.3.6.tar.gz

ADD https://dlcdn.apache.org/zookeeper/zookeeper-3.8.4/apache-zookeeper-3.8.4-bin.tar.gz /tmp/
RUN tar -xzf /tmp/apache-zookeeper-3.8.4-bin.tar.gz -C /usr/local && \
    mv /usr/local/apache-zookeeper-3.8.4-bin $ZOOKEEPER_HOME && \
    mkdir $ZOOKEEPER_HOME/data/ && \
    chown -R hadoop:hadoop $ZOOKEEPER_HOME && \
    rm /tmp/apache-zookeeper-3.8.4-bin.tar.gz

RUN mkdir -p /usr/local/hadoop/hdfs/namenode /usr/local/hadoop/hdfs/datanode /usr/local/hadoop/journal \
    && mkdir -p /home/hadoop/.ssh && \
    chown -R hadoop:hadoop /home/hadoop /usr/local/hadoop

USER hadoop
RUN ssh-keygen -t rsa -P "" -f ~/.ssh/id_rsa && \
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys && \
    chmod 600 ~/.ssh/authorized_keys

WORKDIR /home/hadoop
COPY --chown=hadoop:hadoop hadoop-config/ $HADOOP_HOME/etc/hadoop/
COPY --chown=hadoop:hadoop zoo.cfg $ZOOKEEPER_HOME/conf/
COPY --chown=hadoop:hadoop --chmod=777 start-hadoop.sh /home/hadoop/

ENTRYPOINT ["bash", "-c", "./start-hadoop.sh"]

FROM hadoop-base AS hbase

ENV HBASE_HOME=/usr/local/hbase
ENV PATH=$HBASE_HOME/bin:$PATH

USER root

ADD https://archive.apache.org/dist/hbase/2.4.9/hbase-2.4.9-bin.tar.gz /tmp/
RUN tar -xvzf /tmp/hbase-2.4.9-bin.tar.gz -C /usr/local && \
    mv /usr/local/hbase-2.4.9 $HBASE_HOME && \
    chown -R hadoop:hadoop $HBASE_HOME && \
    rm /tmp/hbase-2.4.9-bin.tar.gz

USER hadoop
WORKDIR /home/hadoop
COPY --chown=hadoop:hadoop hbase-config/hbase-site.xml $HBASE_HOME/conf/hbase-site.xml
COPY --chown=hadoop:hadoop --chmod=777 start-hbase.sh /home/hadoop/
RUN cp $HADOOP_HOME/share/hadoop/common/lib/* $HBASE_HOME/lib/

ENTRYPOINT ["bash", "-c", "./start-hbase.sh"]