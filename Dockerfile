## syntax=docker/dockerfile:1
ARG NGINX_VERSION=1.30.4
FROM nginx:${NGINX_VERSION} AS build
#FROM ghcr.io/nginx/nginx-unprivileged:${NGINX_VERSION} as build

USER root

RUN apt-get clean && \
    apt-get update && \
    apt-get install -y \
#        openssh-client \
        git \
        wget \
        libxml2 \
        libxslt1-dev \
#        libpcre3 \
#        libpcre3-dev \
        libpcre2-dev \
        zlib1g \
        zlib1g-dev \
        openssl \
        libssl-dev \
        libtool \
        automake \
        gcc \
        g++ \
        make \
# --- lua--- \
        liblua5.1-0-dev \
        luarocks \
# --- lua end--- \
# --- modsecurity --- \
        libmodsecurity3 \
        libmodsecurity-dev \
# --- modsecurity end --- \
        && \
    rm -rf /var/cache/apt

# Copy existing sources and add deb-src equivalents
WORKDIR /usr/src
RUN wget "http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz" && \
    tar -C /usr/src -xzvf nginx-${NGINX_VERSION}.tar.gz

COPY git-clone.sh /usr/local/bin/git-clone.sh
RUN chmod +x /usr/local/bin/git-clone.sh

WORKDIR /usr/src/nginx-module-vts
RUN git-clone.sh https://github.com/vozlt/nginx-module-vts.git --ref v0.2.7

WORKDIR /usr/src/nginx-module-headers-more
RUN git-clone.sh https://github.com/openresty/headers-more-nginx-module.git --ref v0.40

WORKDIR /usr/src/ngx_upstream_jdomain
RUN git-clone.sh https://github.com/nicholaschiasson/ngx_upstream_jdomain.git --ref 1.5.2

WORKDIR /usr/src/ngx_brotli
RUN git-clone.sh https://github.com/google/ngx_brotli.git --commit a71f9312c2deb28875acc7bacfdd5695a111aa53 # renovate: currentValue=main
RUN git submodule update --init --recursive

# for lua

WORKDIR /usr/src/luajit2
RUN git-clone.sh https://github.com/openresty/luajit2.git --ref v2.1-agentzh
RUN make -j"$(nproc)" && \
    make install PREFIX=/usr/src/luajit2/_output

ENV LUAJIT_LIB=/usr/src/luajit2/_output/lib
ENV LUAJIT_INC=/usr/src/luajit2/_output/include/luajit-2.1

#for lua
WORKDIR /usr/src/ngx_devel_kit
RUN git-clone.sh https://github.com/vision5/ngx_devel_kit.git --ref v0.3.4

#for lua
WORKDIR /usr/src/lua-nginx-module
RUN git-clone.sh https://github.com/openresty/lua-nginx-module.git --ref v0.10.32rc3



# Mod Security
WORKDIR /src/ModSecurity
#RUN git clone --recursive https://github.com/owasp-modsecurity/ModSecurity .
#RUN ./build.sh
#RUN ./configure --enable-examples=false
#RUN make
#RUN make install
RUN apt-get update && apt-get install -y libmodsecurity3  libmodsecurity-dev
WORKDIR /usr/src/ModSecurity-nginx
RUN git-clone.sh https://github.com/owasp-modsecurity/ModSecurity-nginx.git --ref v1.0.4

#modescurity rules - coreruleset
WORKDIR /etc/modsecurity/coreruleset
RUN git-clone.sh https://github.com/coreruleset/coreruleset.git --ref v4.28.0
RUN mv crs-setup.conf.example crs-setup.conf

WORKDIR /usr/src/nginx-${NGINX_VERSION}
RUN ls -ahl /usr/src
RUN ls -ahl
RUN NGINX_ARGS=$(nginx -V 2>&1 | sed -n -e 's/^.*arguments: //p') \
    ./configure --with-compat --with-http_ssl_module \
      --add-dynamic-module=/usr/src/nginx-module-vts \
      --add-dynamic-module=/usr/src/nginx-module-headers-more \
      --add-dynamic-module=/usr/src/ngx_upstream_jdomain \
      --add-dynamic-module=/usr/src/ngx_brotli/static \
#      --add-dynamic-module=/src/ngx_brotli/filter \
      --add-dynamic-module=/usr/src/ModSecurity-nginx \
      --add-dynamic-module=/usr/src/ngx_devel_kit  \
      --add-dynamic-module=/usr/src/lua-nginx-module \
      ${NGINX_ARGS} && \
    make modules



# lua modules
WORKDIR /usr/src/lua-resty-core
RUN git-clone.sh https://github.com/openresty/lua-resty-core.git --ref v0.1.35rc1
RUN make install LUA_LIB_DIR=/usr/src/lua/share/lua/5.1

WORKDIR /usr/src/lua-resty-lrucache
RUN git-clone.sh https://github.com/openresty/lua-resty-lrucache.git --ref v0.15
RUN make install LUA_LIB_DIR=/usr/src/lua/share/lua/5.1

WORKDIR /usr/src/lua-resty-string
RUN git-clone.sh https://github.com/openresty/lua-resty-string.git --ref v0.19
RUN make install LUA_LIB_DIR=/usr/src/lua/share/lua/5.1

WORKDIR /usr/src/lua-cs-bouncer
RUN git-clone.sh https://github.com/crowdsecurity/lua-cs-bouncer.git --ref v1.0.16
RUN cp -r lib/* /usr/src/lua/share/lua/5.1/

WORKDIR /usr/src
RUN luarocks --lua-version=5.1 --lua-dir=/usr/src/luajit2/_output --tree=/usr/src/lua install lua-cjson 2.1.0.10
RUN luarocks --lua-version=5.1 --lua-dir=/usr/src/luajit2/_output --tree=/usr/src/lua install lua-resty-http 0.18.0
RUN luarocks --lua-version=5.1 --lua-dir=/usr/src/luajit2/_output --tree=/usr/src/lua install lua-resty-openssl 1.8.0

WORKDIR /usr/src/cs-nginx-bouncer
RUN git-clone.sh https://github.com/crowdsecurity/cs-nginx-bouncer.git --ref v1.2.1

# final assembly

FROM nginx:${NGINX_VERSION}
#FROM ghcr.io/nginx/nginx-unprivileged:${NGINX_VERSION}

USER root

COPY --from=build /usr/src/nginx-${NGINX_VERSION}/objs/ngx_http_vhost_traffic_status_module.so /usr/lib/nginx/modules/
COPY --from=build /usr/src/nginx-${NGINX_VERSION}/objs/ngx_http_headers_more_filter_module.so /usr/lib/nginx/modules/
COPY --from=build /usr/src/nginx-${NGINX_VERSION}/objs/ngx_http_upstream_jdomain_module.so /usr/lib/nginx/modules/
COPY --from=build /usr/src/nginx-${NGINX_VERSION}/objs/ngx_http_brotli_*.so /usr/lib/nginx/modules/
COPY --from=build /usr/src/nginx-${NGINX_VERSION}/objs/ngx_http_modsecurity_module.so /usr/lib/nginx/modules/
COPY --from=build /usr/src/nginx-${NGINX_VERSION}/objs/ndk_http_module.so /usr/lib/nginx/modules/
COPY --from=build /usr/src/nginx-${NGINX_VERSION}/objs/ngx_http_lua_module.so /usr/lib/nginx/modules/

# required dependency for modsecurity
RUN apt-get update && apt-get install -y libmodsecurity3
COPY --from=build /etc/modsecurity /etc/modsecurity

# lua
# LuaJIT runtime library
COPY --from=build /usr/src/luajit2/_output/lib/libluajit-5.1.so.2 /usr/local/lib/

# Lua libraries
COPY --from=build /usr/src/lua/share/lua/5.1 /usr/local/share/lua/5.1

# Native Lua modules: lua-cjson
COPY --from=build /usr/src/lua/lib/lua/5.1 /usr/local/lib/lua/5.1

RUN ldconfig

COPY --from=build /usr/src/cs-nginx-bouncer/nginx/crowdsec_nginx.conf \
    /etc/nginx/crowdsec/crowdsec_nginx.conf

RUN printf '%s\n' \
    'load_module /usr/lib/nginx/modules/ngx_http_vhost_traffic_status_module.so;' \
    'load_module /usr/lib/nginx/modules/ngx_http_headers_more_filter_module.so;' \
    'load_module /usr/lib/nginx/modules/ngx_http_upstream_jdomain_module.so;' \
    'load_module /usr/lib/nginx/modules/ngx_http_brotli_static_module.so;' \
    'load_module /usr/lib/nginx/modules/ndk_http_module.so;' \
    'load_module /usr/lib/nginx/modules/ngx_http_lua_module.so;' \
    'load_module /usr/lib/nginx/modules/ngx_http_modsecurity_module.so;' \
    > /etc/nginx/modules.conf

USER $UID