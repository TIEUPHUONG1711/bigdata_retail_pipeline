# Chọn base Ubuntu
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV HADOOP_HOME=/opt/hadoop
ENV HIVE_HOME=/opt/hive
ENV PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$HIVE_HOME/bin

# Cài đặt các dependency cơ bản
RUN apt-get update && apt-get install -y \
    wget curl git python3 python3-pip openjdk-11-jdk \
    mysql-client default-mysql-server \
    ssh rsync vim net-tools lsof sudo \
    && rm -rf /var/lib/apt/lists/*

# Cài Python packages cần thiết
RUN pip3 install pyspark pandas numpy findspark mysql-connector-python

# Cài Hadoop
RUN wget https://downloads.apache.org/hadoop/common/hadoop-3.3.6/hadoop-3.3.6.tar.gz && \
    tar -xzvf hadoop-3.3.6.tar.gz -C /opt/ && \
    mv /opt/hadoop-3.3.6 /opt/hadoop && rm hadoop-3.3.6.tar.gz

# Cài Hive
RUN wget https://downloads.apache.org/hive/hive-3.1.3/apache-hive-3.1.3-bin.tar.gz && \
    tar -xzvf apache-hive-3.1.3-bin.tar.gz -C /opt/ && \
    mv /opt/apache-hive-3.1.3-bin /opt/hive && rm apache-hive-3.1.3-bin.tar.gz

# Cài Sqoop
RUN wget https://downloads.apache.org/sqoop/1.4.7/sqoop-1.4.7.bin__hadoop-2.6.0.tar.gz && \
    tar -xzvf sqoop-1.4.7.bin__hadoop-2.6.0.tar.gz -C /opt/ && \
    mv /opt/sqoop-1.4.7.bin__hadoop-2.6.0 /opt/sqoop && rm sqoop-1.4.7.bin__hadoop-2.6.0.tar.gz
ENV PATH=$PATH:/opt/sqoop/bin

# Copy toàn bộ project vào container
WORKDIR /home/hadoop/bigdata_retail_pipeline
COPY . /home/hadoop/bigdata_retail_pipeline

# Cấp quyền chạy script
RUN chmod +x run/run_pipeline.sh

# Expose cổng MySQL và HiveServer2
EXPOSE 3306 10000

# Khi container start, chạy script pipeline
CMD ["/home/hadoop/bigdata_retail_pipeline/run/run_pipeline.sh"]

