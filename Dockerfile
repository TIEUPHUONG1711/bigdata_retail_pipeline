# 1️⃣ Base image
FROM ubuntu:22.04

# 2️⃣ Set environment
ENV DEBIAN_FRONTEND=noninteractive
ENV HADOOP_HOME=/opt/hadoop
ENV SPARK_HOME=/opt/spark
ENV PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$SPARK_HOME/bin:$SPARK_HOME/sbin

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
    vim \
    nano \
    unzip \
    locales \
    net-tools \
    && locale-gen en_US.UTF-8

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# 4️⃣ Cài Hadoop
RUN wget https://downloads.apache.org/hadoop/common/hadoop-3.3.6/hadoop-3.3.6.tar.gz -O /tmp/hadoop.tar.gz \
    && tar -xzf /tmp/hadoop.tar.gz -C /opt/ \
    && mv /opt/hadoop-3.3.6 $HADOOP_HOME

# 5️⃣ Cài Spark
RUN wget https://downloads.apache.org/spark/spark-3.5.1/spark-3.5.1-bin-hadoop3.tgz -O /tmp/spark.tgz \
    && tar -xzf /tmp/spark.tgz -C /opt/ \
    && mv /opt/spark-3.5.1-bin-hadoop3 $SPARK_HOME

# 6️⃣ Cài PySpark & thư viện Python
RUN pip3 install --no-cache-dir pyspark findspark pandas numpy matplotlib

# 7️⃣ Copy project vào container
COPY . /opt/bigdata_retail_pipeline
WORKDIR /opt/bigdata_retail_pipeline

# 8️⃣ Expose cổng cần thiết
EXPOSE 10000 8080 4040 7077 50070

# 9️⃣ Khởi động bash khi container chạy
CMD ["/bin/bash"]

