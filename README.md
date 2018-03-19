Kafka in Docker
===

This repository provides everything you need to run Kafka in Docker.


Why?
---
The main hurdle of running Kafka in Docker is that it depends on Zookeeper.
Compared to other Kafka docker images, this one runs both Zookeeper and Kafka
in the same container. This means:

* No dependency on an external Zookeeper host, or linking to another container
* Zookeeper and Kafka are configured to work together out of the box

Run
---

```bash
docker run -p 2181:2181 -p 9092:9092 --env ADVERTISED_LISTENERS=PLAINTEXT:`docker-machine ip \`docker-machine active\``:9092 aucklandtransport/kafka
```

```bash
export KAFKA=`docker-machine ip \`docker-machine active\``:9092
kafka-console-producer.sh --broker-list $KAFKA --topic test
```

```bash
export ZOOKEEPER=`docker-machine ip \`docker-machine active\``:2181
kafka-console-consumer.sh --zookeeper $ZOOKEEPER --topic test
```

Configuration
---

Optional ENV variables:
* LISTENERS: list of name://host:port definitions which Kafka will listen on internally
* ADVERTISED_LISTENERS: list of name://host:port definitions which Kafka will tell the outside world it is listening on
* LOG_RETENTION_HOURS: the minimum age of a log file in hours to be eligible for deletion (default is 168, for 1 week)
* LOG_RETENTION_BYTES: configure the size at which segments are pruned from the log, (default is 1073741824, for 1GB)
* NUM_PARTITIONS: configure the default number of log partitions per topic
* ZK_DATA_LOG_DIR: a directory on a separate device to increase Zookeeper data log performance

Variables required for SSL:
* SSL_TRUSTSTORE_LOCATION
* SSL_TRUSTSTORE_PASSWORD
* SSL_KEYSTORE_LOCATION
* SSL_KEYSTORE_PASSWORD

Variables required for clustering:
* SERVER_ID: the unique integer ID of this Kafka broker and Zookeeper instance in their respective clusters
* ZK_CONNECT: a comma-separated list of the host:clientport of all Zookeeper servers in the cluster
* ZK_CLUSTER: a comma-separated list of the host:followport:electionport of all Zookeeper servers in the cluster

In the box
---
* **aucklandtransport/kafka**

  The docker image with both Kafka and Zookeeper. Built from the `kafka`
  directory.


Build from Source
---

    docker build -t aucklandtransport/kafka kafka/
    docker build -t aucklandtransport/kafkaproxy kafkaproxy/

Todo
---

* Not particularily optimzed for startup time.
* Better docs


Credits
---

Based on https://github.com/spotify/docker-kafka