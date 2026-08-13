# nginx-advanced

A custom nginx Docker image with additional dynamic modules pre-compiled and ready to use.

## Modules

| Module | Description |
|---|---|
| [nginx-module-vts](https://github.com/vozlt/nginx-module-vts) | Virtual host traffic status — exposes per-server/location request and bandwidth metrics |
| [headers-more-nginx-module](https://github.com/openresty/headers-more-nginx-module) | Add, set, and clear request/response headers beyond what the core `headers` module allows |
| [ngx_http_brotli_module](https://github.com/HanadaLee/ngx_http_brotli_module) | Brotli compression support for responses |
| [lua-nginx-module](https://github.com/openresty/lua-nginx-module) | Embeds LuaJIT into nginx request processing via non-blocking cosockets |
| [ngx_devel_kit](https://github.com/vision5/ngx_devel_kit) | Required dependency for lua-nginx-module; provides module development utilities |
| [ModSecurity-nginx](https://github.com/owasp-modsecurity/ModSecurity-nginx) | Connector that integrates the ModSecurity WAF engine into nginx |
| [coreruleset](https://github.com/coreruleset/coreruleset) | OWASP Core Rule Set — generic attack detection rules for ModSecurity |
| [cs-nginx-bouncer](https://github.com/crowdsecurity/cs-nginx-bouncer) | CrowdSec bouncer that blocks IPs based on the CrowdSec decision API |

## Lua Libraries

| Library | Description |
|---|---|
| [LuaJIT2](https://github.com/openresty/luajit2) | OpenResty's fork of LuaJIT — the runtime used by lua-nginx-module |
| [lua-resty-core](https://github.com/openresty/lua-resty-core) | Required core API reimplementation for lua-nginx-module using the FFI |
| [lua-resty-lrucache](https://github.com/openresty/lua-resty-lrucache) | LRU cache used internally by lua-resty-core |
| [lua-resty-string](https://github.com/openresty/lua-resty-string) | String utilities (hex, base64, SHA, AES) for use in Lua scripts |
| [lua-cs-bouncer](https://github.com/crowdsecurity/lua-cs-bouncer) | Lua logic for the CrowdSec bouncer — queries the decision API and enforces blocks |
| [lua-cjson](https://github.com/openresty/lua-cjson) | Fast JSON encoder/decoder; required by lua-cs-bouncer for API responses |
| [lua-resty-http](https://github.com/ledgetech/lua-resty-http) | Non-blocking HTTP client; required by lua-cs-bouncer to call the CrowdSec API |
| [lua-resty-openssl](https://github.com/fffonion/lua-resty-openssl) | OpenSSL bindings for Lua; required by lua-resty-http for TLS support |

## Usage

### nginx.conf

Modules are pre-configured in `/etc/nginx/modules.conf`. Include it at the top of your `nginx.conf`:

```nginx
include /etc/nginx/modules.conf;

events {}

http {
    lua_package_path "/usr/local/share/lua/5.1/?.lua;;";

    server {
        listen 80;
        ...
    }
}
```

### CrowdSec

The CrowdSec nginx bouncer config is available at `/etc/nginx/crowdsec/crowdsec_nginx.conf`. Include it in your `http` block:

```nginx
http {
    include /etc/nginx/crowdsec/crowdsec_nginx.conf;
    ...
}
```

## Image

Published to GitHub Container Registry on every push to `main` and on version tags:

```bash
docker pull ghcr.io/<owner>/<repo>:latest
docker pull ghcr.io/<owner>/<repo>:1.2.3
```

## Local Testing

Requires [Docker](https://docs.docker.com/get-docker/) and [Hurl](https://hurl.dev).

```bash
# install hurl (Windows)
winget install --id=Orange-OpenSource.Hurl -e

# run tests
bash test/run-tests.sh
```

The test suite starts the container using `test/compose.yml` with `test/nginx.conf` mounted, runs the Hurl suite, and stops the container on finish or failure.

## Dependency Updates

Dependencies are managed by [Renovate](https://docs.renovatebot.com). It tracks:
- The `nginx` base image version via `ARG NGINX_VERSION`
- All pinned git module tags via `--ref <tag>` (includes lua-resty-string)
- The `ngx_brotli` commit SHA via `--commit <sha>`
