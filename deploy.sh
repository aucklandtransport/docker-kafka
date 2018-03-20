#!/bin/sh
set -e

# Deploy a single node of a Kafka/Zookeeper cluster using Docker
# Variables which must be set:
# * SERVER_ID: the unique integer ID of this Kafka broker and Zookeeper instance in their respective clusters
# * LISTENERS: list of name://host:port definitions which Kafka will listen on internally
# * ADVERTISED_LISTENERS: list of name://host:port definitions which Kafka will tell the outside world it is listening on
# * ZK_CONNECT: a comma-separated list of the host:clientport of all Zookeeper servers in the cluster
# * ZK_CLUSTER: a comma-separated list of the host:followport:electionport of all Zookeeper servers in the cluster

# Assumptions:
# * Kafka talks over ports 9092 (plaintext) and 9093 (SSL/TLS)
# * Zookeeper talks over ports 2181 (clients), 2888 (peers) and 3888 (leader election)
# * These ports are all available to be mapped to the Docker host

# TODO
# * SSL config
# * Separate data volumes for ZK and Kafka

for VAR in SERVER_ID LISTENERS ADVERTISED_LISTENERS ZK_CONNECT ZK_CLUSTER; do
    if [ "$" = "$( eval echo \$$VAR )" ]; then
        echo "Variable $VAR must be set"
        exit 1
    fi
done

# TODO everything
docker run \
    -e SERVER_ID=$SERVER_ID \
    -e LISTENERS=$LISTENERS -e ADVERTISED_LISTENERS=$ADVERTISED_LISTENERS \
    -e ZK_CONNECT=$ZK_CONNECT -e ZK_CLUSTER=$ZK_CLUSTER \
    hello-world