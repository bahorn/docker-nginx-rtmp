ARG OPENRESTY_VERSION=1.15.8.3
ARG NGINX_RTMP_VERSION=1.2.1
ARG NGINX_REDIS_VERSION=0.3.9
ARG NGINX_DEVEL_KIT_VERSION=0.3.1
ARG NGINX_FORM_INPUT_VERSION=0.12

##############################
# Build the NGINX-build image.
FROM alpine:3.11 as build-nginx
ARG OPENRESTY_VERSION
ARG NGINX_RTMP_VERSION
ARG NGINX_REDIS_VERSION
ARG NGINX_DEVEL_KIT_VERSION
ARG NGINX_FORM_INPUT_VERSION

# Build dependencies.
RUN apk add --update \
  build-base \
  ca-certificates \
  curl \
  gcc \
  libc-dev \
  libgcc \
  linux-headers \
  make \
  musl-dev \
  openssl \
  openssl-dev \
  pcre \
  pcre-dev \
  pkgconf \
  pkgconfig \
  zlib-dev \
  perl

# Get nginx source.
RUN cd /tmp && \
  wget https://openresty.org/download/openresty-${OPENRESTY_VERSION}.tar.gz && \
  tar zxf openresty-${OPENRESTY_VERSION}.tar.gz && \
  rm openresty-${OPENRESTY_VERSION}.tar.gz

# Get nginx-rtmp module.
RUN cd /tmp && \
  wget https://github.com/arut/nginx-rtmp-module/archive/v${NGINX_RTMP_VERSION}.tar.gz && \
  tar zxf v${NGINX_RTMP_VERSION}.tar.gz && rm v${NGINX_RTMP_VERSION}.tar.gz

# Compile nginx with nginx-rtmp module.
RUN cd /tmp/openresty-${OPENRESTY_VERSION} && \
  ./configure \
  --prefix=/usr/local/nginx \
  --add-module=/tmp/nginx-rtmp-module-${NGINX_RTMP_VERSION} \
  --conf-path=/etc/nginx/nginx.conf \
  --with-threads \
  --with-file-aio \
  --with-http_ssl_module \
  --with-debug \
  --with-pcre-jit \
  --with-ipv6 \
  --with-cc-opt="-Wimplicit-fallthrough=0" && \
  cd /tmp/openresty-${OPENRESTY_VERSION} && make -j `nproc` && make install


##########################
# Build the release image.
FROM alpine:3.11
LABEL MAINTAINER Alfred Gutierrez <alf.g.jr@gmail.com>

# Set default ports.
ENV HTTP_PORT 80
ENV HTTPS_PORT 443
ENV RTMP_PORT 1935

RUN apk add --update \
  ca-certificates \
  gettext \
  openssl \
  pcre \
  lame \
  libogg \
  curl \
  libass \
  libvpx \
  libvorbis \
  libwebp \
  libtheora \
  opus \
  rtmpdump \
  x264-dev \
  x265-dev

COPY --from=build-nginx /usr/local/nginx /usr/local/nginx
COPY --from=build-nginx /etc/nginx /etc/nginx

# Add NGINX path, config and static files.
ENV PATH "${PATH}:/usr/local/nginx/nginx/sbin"
ADD nginx.conf /etc/nginx/nginx.conf.template
RUN mkdir -p /opt/data && mkdir /www
ADD static /www/static

EXPOSE 1935
EXPOSE 80

CMD envsubst "$(env | sed -e 's/=.*//' -e 's/^/\$/g')" < \
  /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf && \
  nginx
