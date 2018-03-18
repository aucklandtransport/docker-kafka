#!/bin/sh

# Optional ENV variables:
# * LISTENERS: list of name://host:port definitions which Kafka will listen on internally
# * ADVERTISED_LISTENERS: list of name://host:port definitions which Kafka will tell the outside world it is listening on
# * SSL_TRUSTSTORE_LOCATION
# * SSL_TRUSTSTORE_PASSWORD
# * SSL_KEYSTORE_LOCATION
# * SSL_KEYSTORE_PASSWORD
# * ZK_CHROOT: the zookeeper chroot that's used by Kafka (without / prefix), e.g. "kafka"
# * LOG_RETENTION_HOURS: the minimum age of a log file in hours to be eligible for deletion (default is 168, for 1 week)
# * LOG_RETENTION_BYTES: configure the size at which segments are pruned from the log, (default is 1073741824, for 1GB)
# * NUM_PARTITIONS: configure the default number of log partitions per topic

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

# Set the internal and external host and port
_set_config listeners "$LISTENERS"
_set_config advertised.listeners "$ADVERTISED_LISTENERS"

# Set SSL secret parameters
_set_config ssl.truststore.location "$SSL_TRUSTSTORE_LOCATION"
_set_config ssl.truststore.password "$SSL_TRUSTSTORE_PASSWORD"
_set_config ssl.keystore.location "$SSL_KEYSTORE_LOCATION"
_set_config ssl.keystore.password "$SSL_KEYSTORE_PASSWORD"

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
