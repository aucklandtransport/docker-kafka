#!/bin/sh
set -e

# Optional env variables:
# * ZK_DATA_LOG_DIR: a directory on a separate device to increase Zookeeper data log performance
# Variables required for clustering:
# * SERVER_ID: the unique integer ID of this Kafka broker and Zookeeper instance in their respective clusters
# * ZK_CLUSTER: a comma-separated list of the host:followport:electionport of all Zookeeper servers in the cluster

# Update the config file from an environment variable, idempotently
_set_config () {
    local CONF_NAME=$1
    local CONF_VALUE=$2
    if [ ! -z "$CONF_VALUE" ]; then
        echo "setting $CONF_NAME=$CONF_VALUE"
        if grep -q "^$CONF_NAME" /etc/zookeeper/conf/zoo.cfg; then
            sed -r -i "s/#($CONF_NAME)=(.*)/\1=$CONF_VALUE/g" /etc/zookeeper/conf/zoo.cfg
        else
            echo "$CONF_NAME=$CONF_VALUE" >> /etc/zookeeper/conf/zoo.cfg
        fi
    fi
}

# Set the data log directory
_set_config dataLogDir "$ZK_DATA_LOG_DIR"

# Delete the old cluster definition
sed -i '/^server.[0-9]*=.*/d' /etc/zookeeper/conf/zoo.cfg

# Create a new cluster definition
if [ ! -z "$ZK_CLUSTER" ]; then
    IFS=","
    I=0
    for SERVER in $ZK_CLUSTER; do
        echo "setting server.$I=$SERVER"
        echo "server.$I=$SERVER" >> /etc/zookeeper/conf/zoo.cfg
        I=$((I+1))
    done
fi

# Set the server ID
if [ ! -z "$SERVER_ID" ]; then
    echo $SERVER_ID > /var/lib/zookeeper/myid
fi

# Run Zookeeper
/usr/share/zookeeper/bin/zkServer.sh start-foreground