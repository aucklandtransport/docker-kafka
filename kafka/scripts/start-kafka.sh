#!/bin/sh

# Optional ENV variables:
# * ADVERTISED_HOST: the external ip for the container, e.g. `docker-machine ip \`docker-machine active\``
# * ADVERTISED_PORT: the external port for Kafka, e.g. 9092
# * ZK_CHROOT: the zookeeper chroot that's used by Kafka (without / prefix), e.g. "kafka"
# * LOG_RETENTION_HOURS: the minimum age of a log file in hours to be eligible for deletion (default is 168, for 1 week)
# * LOG_RETENTION_BYTES: configure the size at which segments are pruned from the log, (default is 1073741824, for 1GB)
# * NUM_PARTITIONS: configure the default number of log partitions per topic

# Configure advertised host/port if we run in helios
if [ ! -z "$HELIOS_PORT_kafka" ]; then
    ADVERTISED_HOST=`echo $HELIOS_PORT_kafka | cut -d':' -f 1 | xargs -n 1 dig +short | tail -n 1`
    ADVERTISED_PORT=`echo $HELIOS_PORT_kafka | cut -d':' -f 2`
fi

_set_config () {
    local CONF_NAME=$1
    local CONF_VALUE=$2
    if [ ! -z "$CONF_VALUE" ]; then
        echo "setting $CONF_NAME=$CONF_VALUE"
        if grep -q "^$CONF_NAME" $KAFKA_HOME/config/server.properties; then
            sed -r -i "s/#($CONF_NAME)=(.*)/\1=$CONF_VALUE/g" $KAFKA_HOME/config/server.properties
        else
            echo "$CONF_NAME=$CONF_VALUE" >> $KAFKA_HOME/config/server.properties
        fi
    fi
}

# Set the external host and port
_set_config advertised.host.name "$ADVERTISED_HOST"
_set_config advertised.port "$ADVERTISED_PORT"

# Set the zookeeper chroot
if [ ! -z "$ZK_CHROOT" ]; then
    # wait for zookeeper to start up
    until /usr/share/zookeeper/bin/zkServer.sh status; do
      sleep 0.1
    done

    # create the chroot node
    echo "create /$ZK_CHROOT \"\"" | /usr/share/zookeeper/bin/zkCli.sh || {
        echo "can't create chroot in zookeeper, exit"
        exit 1
    }

    # configure kafka
    _set_config zookeeper.connect "localhost:2181"
fi

# Allow specification of log retention policies
_set_config log.retention.hours "$LOG_RETENTION_HOURS"
_set_config log.retention.bytes "$LOG_RETENTION_BYTES"

# Configure the default number of log partitions per topic
_set_config num.partitions "$NUM_PARTITIONS"

# Enable/disable auto creation of topics
_set_config auto.create.topics.enable "$AUTO_CREATE_TOPICS"

# Run Kafka
$KAFKA_HOME/bin/kafka-server-start.sh $KAFKA_HOME/config/server.properties
