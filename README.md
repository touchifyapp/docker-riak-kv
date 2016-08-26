# Supported tags and respective Dockerfile links

*  [`2.1.4`, `2.1`, `2`, `latest` (Dockerfile)](https://github.com/touchifyapp/docker-riak-kv/blob/master/Dockerfile)

This image is updated via [pull requests to the `touchifyapp/docker-riak-kv` GitHub repo](https://github.com/touchifyapp/docker-riak-kv/pulls).

# [Riak® KV](http://fr.basho.com/products/riak-kv/): A distributed NoSQL key/value database.

<img src="http://basho.com/wp-content/uploads/2015/06/riak-kv.png" width="200" alt="Riak Logo" title="Riak Logo" />

`Riak® KV` is a distributed NoSQL key/value database with advanced local and multi-cluster replication that guarantees reads and writes even in the event of hardware failures or network partitions..

## How to use

### As a simple container

```
# Run a Riak KV server
# Each server exposes multiple ports
# 8087 is for Protocol Buffer clients.
# 8098 is for HTTP clients.
# use -p or -P as needed.

$ docker run -d -P --name riak-kv touchify/riak-kv
```

### As a Docker 1.12 service cluster

```
# Create a network overlay
$ docker network create -d overlay databases

# Start a Riak KV cluster.
# Use RIAK_SERVICE_NAME variable to configure the cluster service name.
# WARNING: can't start multiple replicas

$ docker service create \
$     --name riak-kv-cluster \
$     --network databases \
$     --env RIAK_SERVICE_NAME=riak-kv-cluster \
$     touchify/riak-kv

# Scale a Riak KV cluster.
# WARNING: only scale one by one.
# WARNING: Can't scale down.

$ docker service scale riak-kv-cluster=2
```

### Add bucket types

All `.dt` files in `/etc/riak/schemas/` are parsed during startup and added to Riak KV.
 * The filename will be the bucket type name.
 * The file content will be the bucket type definition _(in JSON format)_.

## Environments variables

```
Cluster Options:
    RIAK_SERVICE_NAME                For use in Docker 1.12 in Swarm mode.
                                     Should equal to Docker service name in Swarm.
                                     Used to configure the Riak KV cluster.
    RIAK_CLUSTER_NAME                Set the Riak KV cluster name.

Configurations:
    RIAK_BACKEND                     Set the Riak backend technology (`bitcask` or `leveldb`)
    RIAK_STRONG_CONSISTENCY          Enable or disable Riak strong consistency (`on` or `off`).
```

## License

View [license information](https://github.com/touchifyapp/docker-riak-kv/blob/master/LICENSE) for the software contained in this image.

## Supported Docker versions

This image is officially supported on Docker version 1.12+.

Please see [the Docker installation documentation](https://docs.docker.com/installation/) for details on how to upgrade your Docker daemon.

## User Feedback

### Documentation

Documentation for this image is stored in [the `touchifyapp/docker-riak-kv` GitHub repo](https://github.com/touchifyapp/docker-riak-kv).
Be sure to familiarize yourself with the repository's README.md file before attempting a pull request.

### Issues

If you have any problems with or questions about this image, please contact us through a [GitHub issue](https://github.com/touchifyapp/docker-riak-kv/issues).

### Contributing

You are invited to contribute new features, fixes, or updates, large or small; we are always thrilled to receive pull requests, and do our best to process them as fast as we can.

Before you start to code, we recommend discussing your plans through a [GitHub issue](https://github.com/touchifyapp/docker-riak-kv/issues), especially for more ambitious contributions. This gives other contributors a chance to point you in the right direction, give you feedback on your design, and help you find out if someone else is working on the same thing.
