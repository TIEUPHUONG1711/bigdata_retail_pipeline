# Base image
FROM ubuntu:22.04

# Set environment
ENV DEBIAN_FRONTEND=noninteractive
ENV HADOOP_HOME=/opt/hadoop
ENV SPARK_HOME=/opt/spark
ENV HIVE_HOME=/opt/hive
ENV PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$SPARK_HOME/bin:$SPARK_HOME/sbin:$HIVE_HOME/bin:/opt/sqoop/bin
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# 1️⃣ Cài các dependency cơ bản
RUN apt-get update && apt-get install -y \
    openjdk-11-jdk \
    python3 \
    python3-pip \
    wget \
    curl \
    ssh \
    git \
    mysql-client \
    default-mysql-server \
    vim \
    nano \
    unzip \
    locales \
    net-tools \
    rsync \
    && locale-gen en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

# 2️⃣ Cài Python packages
RUN pip3 install --no-cache-dir pyspark findspark pandas numpy matplotlib mysql-connector-python

# 3️⃣ Cài Hadoop
RUN wget https://downloads.apache.org/hadoop/common/hadoop-3.3.6/hadoop-3.3.6.tar.gz -O /tmp/hadoop.tar.gz \
    && tar -xzf /tmp/hadoop.tar.gz -C /opt/ \
    && mv /opt/hadoop-3.3.6 $HADOOP_HOME \
    && rm /tmp/hadoop.tar.gz

# 4️⃣ Cài Spark
RUN wget https://downloads.apache.org/spark/spark-3.5.1/spark-3.5.1-bin-hadoop3.tgz -O /tmp/spark.tgz \
    && tar -xzf /tmp/spark.tgz -C /opt/ \
    && mv /opt/spark-3.5.1-bin-hadoop3 $SPARK_HOME \
    && rm /tmp/spark.tgz

# 5️⃣ Cài Hive
RUN wget https://downloads.apache.org/hive/hive-3.1.3/apache-hive-3.1.3-bin.tar.gz -O /tmp/hive.tar.gz \
    && tar -xzf /tmp/hive.tar.gz -C /opt/ \
    && mv /opt/apache-hive-3.1.3-bin $HIVE_HOME \
    && rm /tmp/hive.tar.gz

# 6️⃣ Cài Sqoop
RUN wget https://downloads.apache.org/sqoop/1.4.7/sqoop-1.4.7.bin__hadoop-2.6.0.tar.gz -O /tmp/sqoop.tar.gz \
    && tar -xzf /tmp/sqoop.tar.gz -C /opt/ \
    && mv /opt/sqoop-1.4.7.bin__hadoop-2.6.0 /opt/sqoop \
    && rm /tmp/sqoop.tar.gz

# 7️⃣ Copy project
WORKDIR /home/hadoop/bigdata_retail_pipeline
COPY . /home/hadoop/bigdata_retail_pipeline

# 8️⃣ Cấp quyền chạy script
RUN chmod +x run/run_pipeline.sh

# 9️⃣ Expose cổng cần thiết
EXPOSE 3306 10000 8080 4040 7077 50070

# 10️⃣ CMD: chạy pipeline tự động
CMD ["/home/hadoop/bigdata_retail_pipeline/run/run_pipeline.sh"]
