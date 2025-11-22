# 1️⃣ Base image
FROM ubuntu:22.04

# 2️⃣ Set environment
ENV DEBIAN_FRONTEND=noninteractive
ENV HADOOP_HOME=/opt/hadoop
ENV SPARK_HOME=/opt/spark
ENV HIVE_HOME=/opt/hive
ENV PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$SPARK_HOME/bin:$SPARK_HOME/sbin:$HIVE_HOME/bin

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# 3️⃣ Cập nhật và cài đặt gói cần thiết
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
    && locale-gen en_US.UTF-8

# 4️⃣ Cài Hadoop
RUN wget https://downloads.apache.org/hadoop/common/hadoop-3.3.6/hadoop-3.3.6.tar.gz -O /tmp/hadoop.tar.gz \
    && tar -xzf /tmp/hadoop.tar.gz -C /opt/ \
    && mv /opt/hadoop-3.3.6 $HADOOP_HOME

# 5️⃣ Cài Spark
RUN wget https://downloads.apache.org/spark/spark-3.5.1/spark-3.5.1-bin-hadoop3.tgz -O /tmp/spark.tgz \
    && tar -xzf /tmp/spark.tgz -C /opt/ \
    && mv /opt/spark-3.5.1-bin-hadoop3 $SPARK_HOME

# 6️⃣ Cài Hive
RUN wget https://downloads.apache.org/hive/hive-3.1.3/apache-hive-3.1.3-bin.tar.gz -O /tmp/hive.tar.gz \
    && tar -xzf /tmp/hive.tar.gz -C /opt/ \
    && mv /opt/apache-hive-3.1.3-bin $HIVE_HOME

# 7️⃣ Cài Sqoop
RUN wget https://downloads.apache.org/sqoop/1.4.7/sqoop-1.4.7.bin__hadoop-2.6.0.tar.gz -O /tmp/sqoop.tar.gz \
    && tar -xzf /tmp/sqoop.tar.gz -C /opt/ \
    && mv /opt/sqoop-1.4.7.bin__hadoop-2.6.0 /opt/sqoop

ENV PATH=$PATH:/opt/sqoop/bin

# 8️⃣ Cài PySpark & thư viện Python
RUN pip3 install --no-cache-dir pyspark findspark pandas numpy matplotlib mysql-connector-python
# Cài MySQL server
RUN apt-get update && apt-get install -y default-mysql-server mysql-client

# 9️⃣ Copy project vào container
COPY . /opt/bigdata_retail_pipeline
WORKDIR /opt/bigdata_retail_pipeline

# 10️⃣ Cấp quyền chạy script
RUN chmod +x run/run_pipeline.sh

# 11️⃣ Expose cổng
EXPOSE 3306 10000 8080 4040 7077 50070

# 12️⃣ CMD: chạy pipeline tự động khi container start
CMD ["/home/hadoop/bigdata_retail_pipeline/run/run_pipeline.sh"]

