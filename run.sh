#!/bin/bash

set -e

RIAK=/usr/sbin/riak
RIAK_CONF=/etc/riak/riak.conf
RIAK_ADMIN=/usr/sbin/riak-admin
SCHEMAS_DIR=/etc/riak/schemas/
RIAK_CLUSTER_NAME=${RIAK_CLUSTER_NAME:-riak}
CURRENT_IP=`hostname -i | awk '{print $1}'`
TAIL_PID=

function configure {
    sed -i "s/nodename = .*/nodename = riak@$CURRENT_IP/" $RIAK_CONF
    sed -i "s/distributed_cookie = .*/distributed_cookie = $RIAK_CLUSTER_NAME/" $RIAK_CONF
    sed -i "s/storage_backend = .*/storage_backend = $RIAK_BACKEND/" $RIAK_CONF
    sed -i "s/(## )?strong_consistency = .*/strong_consistency = $RIAK_STRONG_CONSISTENCY/" $RIAK_CONF
}

function start {
    su - riak -c "$RIAK start"
    $RIAK_ADMIN wait-for-service riak_kv
}

function add_bucket_type {
    $RIAK_ADMIN bucket-type create $1 '{"props":{"datatype":"'$2'"}}'
    $RIAK_ADMIN bucket-type activate $1
}

function get_cluster_ips {
    if [ -z "$CLUSTER_ALL_IPS" ]; then
        CLUSTER_ALL_IPS=`nslookup tasks.$RIAK_SERVICE_NAME 2>/dev/null | awk '/^Address: [0-9]/ {print $2}'`
    fi

    if [ "$1" = "--all" ]; then
        echo "$CLUSTER_ALL_IPS"
    else
        echo "$CLUSTER_ALL_IPS" | sed "/$CURRENT_IP/d"
    fi
}

function get_cluster_members_count {
    $RIAK_ADMIN member-status | egrep "joining|valid" | wc -l
}

function cluster_commit {
    $RIAK_ADMIN cluster plan
    $RIAK_ADMIN cluster commit
}

function cluster_join {
    $RIAK_ADMIN cluster join "riak@$1"
}

function cluster_leave {
    $RIAK_ADMIN cluster leave
    cluster_commit
}

function stop {
    echo "Stopping Riak KV"
    su - riak -c "$RIAK stop"

    if [[ $TAIL_PID ]]; then
        echo "Killing sub-tail process"
        kill $TAIL_PID
    fi

    exit $1
}

function clean_up {
    if [ -n "$RIAK_SERVICE_NAME" ] && [ `get_cluster_members_count` -gt 1 ]; then
        cluster_leave
    fi

    stop
}

trap clean_up TERM INT STOP KILL

echo "Configuring environment options"
configure

echo "Starting Riak KV server"
start

# Create KV bucket types
echo "Looking for datatypes in $SCHEMAS_DIR..."
for f in `find $SCHEMAS_DIR -name *.dt -print`; do
    BUCKET_NAME=`basename -s .dt $f`
    BUCKET_SPEC=`cat $f`

    add_bucket_type $BUCKET_NAME $BUCKET_SPEC
done

if [ -n "$RIAK_SERVICE_NAME" ]; then
    echo "Automatic clustering configuration"

    if [ `get_cluster_ips --all | wc -l` = 1 ]; then
        echo "First node. Skipping..."
    else
        # get first IP in cluster IPs
        COORDINATOR=`get_cluster_ips | head -n 1 | head -c -1`

        # join cluster
        cluster_join $COORDINATOR

        # If we are the last node to join the cluster
        if [ `get_cluster_members_count` = `get_cluster_ips --all | wc -l` ]; then
            cluster_commit
        fi
    fi
fi

# Display past riak logs
cat /var/log/riak/*

# Display riak logs continuously
tail -f /var/log/riak/* & TAIL_PID=$!
wait $TAIL_PID
TAIL_PID=
