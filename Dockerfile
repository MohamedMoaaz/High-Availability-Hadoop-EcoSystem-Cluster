# ==================== BASE IMAGE ====================
FROM ubuntu:22.04 AS hadoop-base

# Install essential tools including OpenJDK 8 (required by Hadoop/HBase), SSH, and utilities
RUN apt update -y && apt upgrade -y && \
    apt install -y openjdk-8-jdk cron ssh sudo curl wget

# Set environment variables for Java, Hadoop, and Zookeeper paths
ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-arm64
ENV HADOOP_HOME=/usr/local/hadoop
ENV ZOOKEEPER_HOME=/usr/local/zookeeper
ENV PATH=$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$ZOOKEEPER_HOME/bin:$PATH

# Create a user/group for Hadoop with passwordless sudo access
RUN addgroup hadoop && \
    adduser --disabled-password --ingroup hadoop hadoop && \
    echo "hadoop ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Download and install Hadoop
ADD https://dlcdn.apache.org/hadoop/common/hadoop-3.3.6/hadoop-3.3.6.tar.gz /tmp/
RUN tar -xzf /tmp/hadoop-3.3.6.tar.gz -C /usr/local/ && \
    mv /usr/local/hadoop-3.3.6 $HADOOP_HOME && \
    chown -R hadoop:hadoop $HADOOP_HOME && \
    rm /tmp/hadoop-3.3.6.tar.gz

# Download and install Zookeeper
ADD https://dlcdn.apache.org/zookeeper/zookeeper-3.8.4/apache-zookeeper-3.8.4-bin.tar.gz /tmp/
RUN tar -xzf /tmp/apache-zookeeper-3.8.4-bin.tar.gz -C /usr/local && \
    mv /usr/local/apache-zookeeper-3.8.4-bin $ZOOKEEPER_HOME && \
    mkdir $ZOOKEEPER_HOME/data/ && \
    chown -R hadoop:hadoop $ZOOKEEPER_HOME && \
    rm /tmp/apache-zookeeper-3.8.4-bin.tar.gz

# Create directories for HDFS NameNode, DataNode, and JournalNode
RUN mkdir -p /usr/local/hadoop/hdfs/namenode /usr/local/hadoop/hdfs/datanode /usr/local/hadoop/journal \
    && mkdir -p /home/hadoop/.ssh && \
    chown -R hadoop:hadoop /home/hadoop /usr/local/hadoop

# Switch to the hadoop user and generate SSH keys for internal communication
USER hadoop
RUN ssh-keygen -t rsa -P "" -f ~/.ssh/id_rsa && \
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys && \
    chmod 600 ~/.ssh/authorized_keys

# Set working directory and copy configuration files and startup script
WORKDIR /home/hadoop
COPY --chown=hadoop:hadoop hadoop-config/ $HADOOP_HOME/etc/hadoop/
COPY --chown=hadoop:hadoop zoo.cfg $ZOOKEEPER_HOME/conf/
COPY --chown=hadoop:hadoop --chmod=777 start-hadoop.sh /home/hadoop/

# Start Hadoop and Zookeeper
ENTRYPOINT ["bash", "-c", "./start-hadoop.sh"]

# ==================== HIVE IMAGE ====================
FROM hadoop-base AS hive

# Set environment for Hive and Tez
ENV HIVE_HOME=/usr/local/hive
ENV TEZ_HOME=/usr/local/tez
ENV PATH=$HIVE_HOME/bin:$TEZ_HOME/bin:$PATH
ENV HADOOP_CLASSPATH=$HADOOP_HOME/etc/hadoop:$TEZ_HOME/lib/*:$TEZ_HOME/conf:$TEZ_HOME/*
ENV HIVE_AUX_JARS_PATH=/usr/local/hadoop/share/hadoop/common/hadoop-common-3.3.6-tests.jar:/usr/local/hadoop/share/hadoop/common/hadoop-common-3.3.6.jar:/usr/local/hadoop/share/hadoop/common/hadoop-kms-3.3.6.jar:/usr/local/hadoop/share/hadoop/common/hadoop-nfs-3.3.6.jar:/usr/local/hadoop/share/hadoop/common/hadoop-registry-3.3.6.jar:/usr/local/hadoop/share/hadoop/hdfs/hadoop-hdfs-3.3.6-tests.jar:/usr/local/hadoop/share/hadoop/hdfs/hadoop-hdfs-3.3.6.jar:/usr/local/hadoop/share/hadoop/hdfs/hadoop-hdfs-client-3.3.6-tests.jar:/usr/local/hadoop/share/hadoop/hdfs/hadoop-hdfs-client-3.3.6.jar:/usr/local/hadoop/share/hadoop/hdfs/hadoop-hdfs-httpfs-3.3.6.jar:/usr/local/hadoop/share/hadoop/hdfs/hadoop-hdfs-native-client-3.3.6-tests.jar:/usr/local/hadoop/share/hadoop/hdfs/hadoop-hdfs-native-client-3.3.6.jar:/usr/local/hadoop/share/hadoop/hdfs/hadoop-hdfs-nfs-3.3.6.jar:/usr/local/hadoop/share/hadoop/hdfs/hadoop-hdfs-rbf-3.3.6-tests.jar:/usr/local/hadoop/share/hadoop/hdfs/hadoop-hdfs-rbf-3.3.6.jar

# Switch to root to install Hive and dependencies
USER root

# Download and install Hive
ADD https://dlcdn.apache.org/hive/hive-4.0.1/apache-hive-4.0.1-bin.tar.gz /tmp/
RUN tar -xzf /tmp/apache-hive-4.0.1-bin.tar.gz -C /usr/local && \
    mv /usr/local/apache-hive-4.0.1-bin $HIVE_HOME && \
    chown -R hadoop:hadoop $HIVE_HOME

# Download and install Tez
ADD https://archive.apache.org/dist/tez/0.10.4/apache-tez-0.10.4-bin.tar.gz /tmp/
RUN tar -xzf /tmp/apache-tez-0.10.4-bin.tar.gz -C /usr/local && \
    mv /usr/local/apache-tez-0.10.4-bin $TEZ_HOME && \
    chown -R hadoop:hadoop $TEZ_HOME

# Add PostgreSQL JDBC driver to Hive's lib folder
ADD https://jdbc.postgresql.org/download/postgresql-42.6.0.jar /tmp/
RUN mv /tmp/postgresql-42.6.0.jar $HIVE_HOME/lib/ && \
    chown hadoop:hadoop $HIVE_HOME/lib/postgresql-42.6.0.jar

# Switch back to hadoop user
USER hadoop

# Copy Hive and Tez configurations and start script
WORKDIR /home/hadoop
COPY --chown=hadoop:hadoop hive-config/hive-site.xml $HIVE_HOME/conf/
COPY --chown=hadoop:hadoop hive-config/tez-site.xml $TEZ_HOME/conf/
COPY --chown=hadoop:hadoop --chmod=777 start-hive.sh /home/hadoop/
ENTRYPOINT ["bash", "-c", "./start-hive.sh"]

# ==================== HBASE IMAGE ====================
FROM hadoop-base AS hbase

# Set environment for HBase
ENV HBASE_HOME=/usr/local/hbase
ENV PATH=$HBASE_HOME/bin:$PATH

# Switch to root to install HBase
USER root

# Download and install HBase
ADD https://archive.apache.org/dist/hbase/2.4.9/hbase-2.4.9-bin.tar.gz /tmp/
RUN tar -xvzf /tmp/hbase-2.4.9-bin.tar.gz -C /usr/local && \
    mv /usr/local/hbase-2.4.9 $HBASE_HOME && \
    chown -R hadoop:hadoop $HBASE_HOME && \
    rm /tmp/hbase-2.4.9-bin.tar.gz

# Switch back to hadoop user
USER hadoop

# Set working directory and copy HBase configuration
WORKDIR /home/hadoop
COPY --chown=hadoop:hadoop hbase-config/hbase-site.xml $HBASE_HOME/conf/hbase-site.xml
COPY --chown=hadoop:hadoop --chmod=777 start-hbase.sh /home/hadoop/

# Copy Hadoop common JARs to HBase lib for compatibility
RUN cp $HADOOP_HOME/share/hadoop/common/lib/* $HBASE_HOME/lib/

# Start HBase
ENTRYPOINT ["bash", "-c", "./start-hbase.sh"]