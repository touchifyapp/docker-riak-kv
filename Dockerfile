FROM debian:wheezy

MAINTAINER Touchify <dev@touchify.co> (@touchify)

ENV DEBIAN_FRONTEND=noninteractive \
    RIAK_VERSION=2.1.4-1 \
    RIAK_BACKEND=bitcask \
    RIAK_STRONG_CONSISTENCY=off \
    RIAK_CLUSTER_NAME=riak

# Install pre-requistes
RUN apt-get update \
 && apt-get -y upgrade \
 && apt-get install -y curl apt-transport-https dnsutils \

 # Install riak
 && curl https://packagecloud.io/install/repositories/basho/riak/script.deb.sh | bash \
 && apt-get install -y riak=${RIAK_VERSION} \

 # Clean apt
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \

 # Tune riak configuration settings for the container
 && sed -i 's/listener.http.internal = 127.0.0.1/listener.http.internal = 0.0.0.0/' /etc/riak/riak.conf \
 && sed -i 's/listener.protobuf.internal = 127.0.0.1/listener.protobuf.internal = 0.0.0.0/' /etc/riak/riak.conf \
 && echo "anti_entropy.concurrency_limit = 1" >> /etc/riak/riak.conf \
 && echo "javascript.map_pool_size = 0" >> /etc/riak/riak.conf \
 && echo "javascript.reduce_pool_size = 0" >> /etc/riak/riak.conf \
 && echo "javascript.hook_pool_size = 0" >> /etc/riak/riak.conf \
 
 # Prepare riak directories
 && chown riak:riak /var/lib/riak /var/log/riak \
 && chmod 755 /var/lib/riak /var/log/riak \
 && mkdir -p /etc/riak/schemas

# Make Riak's data and log directories volumes
VOLUME /etc/riak/schemas \
       /var/lib/riak \
       /var/log/riak

# Run riak ping to check node availability
HEALTHCHECK \
    --interval=30s --timeout=10s \
    CMD riak ping

# 8087: Protocol Buffer port.
# 8098: HTTP port.
EXPOSE 8087 8098

COPY run.sh /run.sh
CMD ["/run.sh"]
