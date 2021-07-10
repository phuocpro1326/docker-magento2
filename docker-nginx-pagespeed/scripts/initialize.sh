#!/bin/bash

# use GeoIP MaxMind databases & expose fastcgi variables for PHP GeoIP
# WARNING: since MaxMind does not offer automatic downloads
#          you have to upload GeoLite2-Country & GeoLite2-City yourself into container /usr/share/GeoIP2/
if [ -z ${NGINX_GEOIP+x} ]; then
    echo "env: NGINX_GEOIP not specified, default: [ off ]"
    rm  /etc/nginx/conf.d/geoip2.conf
    cat /etc/nginx/fastcgi_params.orig        >  /etc/nginx/fastcgi_params
else
    echo "env: NGINX_GEOIP: [ ${NGINX_GEOIP} ]"
    if [ "$NGINX_GEOIP" == "on" ]; then
        cat /etc/nginx/fastcgi_params.orig    >  /etc/nginx/fastcgi_params
        cat /etc/nginx/include/fastcgi_params >> /etc/nginx/fastcgi_params
    fi
fi


# setup pagespeed
if [ -z ${NGINX_PAGESPEED+x} ]; then
    echo "env: NGINX_PAGESPEED not specified, default: [ off ]"
else
    echo "env: NGINX_PAGESPEED: [ ${NGINX_PAGESPEED} ]"
    if [ "$NGINX_PAGESPEED" == "on" ]; then
        sed -i "/pagespeed off;/cpagespeed on;" /etc/nginx/conf.d/pagespeed.conf
        sed -i "/pagespeed off;/cpagespeed on;" /etc/nginx/include/pagespeed.conf
    else
        sed -i "/pagespeed on;/cpagespeed off;" /etc/nginx/conf.d/pagespeed.conf
        sed -i "/pagespeed on;/cpagespeed off;" /etc/nginx/include/pagespeed.conf
    fi
fi


# setup pagespeed image processing
if [ -z ${NGINX_PAGESPEED_IMG+x} ]; then
    export NGINX_PAGESPEED_IMG=off
fi

echo "env: NGINX_PAGESPEED_IMG image optimization: [ ${NGINX_PAGESPEED_IMG} ]"
if [ "$NGINX_PAGESPEED_IMG" == "on" ]; then
    sed -i "s/DisableFilters/EnableFilters/" /etc/nginx/conf.d/pagespeed-image.conf
else
    sed -i "s/EnableFilters/DisableFilters/" /etc/nginx/conf.d/pagespeed-image.conf
fi


# setup pagespeed javascript processing
if [ -z ${NGINX_PAGESPEED_JS+x} ]; then
    export NGINX_PAGESPEED_JS=off
fi

echo "env: NGINX_PAGESPEED_JS javascript optimization: [ ${NGINX_PAGESPEED_JS} ]"
if [ "$NGINX_PAGESPEED_JS" == "on" ]; then
    sed -i "s/DisableFilters/EnableFilters/" /etc/nginx/conf.d/pagespeed-js.conf
else
    sed -i "s/EnableFilters/DisableFilters/" /etc/nginx/conf.d/pagespeed-js.conf
fi


# setup pagespeed javascript processing
if [ -z ${NGINX_PAGESPEED_CSS+x} ]; then
    export NGINX_PAGESPEED_CSS=off
fi

echo "env: NGINX_PAGESPEED_CSS stylesheets optimization: [ ${NGINX_PAGESPEED_CSS} ]"
if [ "$NGINX_PAGESPEED_CSS" == "on" ]; then
    sed -i "s/DisableFilters/EnableFilters/" /etc/nginx/conf.d/pagespeed-css.conf
else
    sed -i "s/EnableFilters/DisableFilters/" /etc/nginx/conf.d/pagespeed-css.conf
fi


# setup pagespeed cache backend
if [ -z ${NGINX_PAGESPEED_STORAGE+x} ]; then
    echo "env: NGINX_PAGESPEED_STORAGE not specified, default: [ FILES ]"
else
    echo "env: NGINX_PAGESPEED_STORAGE: [ ${NGINX_PAGESPEED_STORAGE} ]"
    if [ "$NGINX_PAGESPEED_STORAGE" == "redis" ]; then
        if [ -z ${NGINX_PAGESPEED_REDIS+x} ]; then
            echo "env: NGINX_PAGESPEED_STORAGE: [ ${NGINX_PAGESPEED_STORAGE} ], but NGINX_PAGESPEED_REDIS not set"
            rm -f /etc/nginx/conf.d/pagespeed-redis.conf
        else
            echo "env: NGINX_PAGESPEED_REDIS: [ ${NGINX_PAGESPEED_REDIS} ]"
            printf "# redis storage backend\n" 								>  /etc/nginx/conf.d/pagespeed-redis.conf
            printf "pagespeed RedisServer \"${NGINX_PAGESPEED_REDIS}\";\n" 	>> /etc/nginx/conf.d/pagespeed-redis.conf
            printf "pagespeed RedisTimeoutUs 1000;\n" 						>> /etc/nginx/conf.d/pagespeed-redis.conf
        fi
    fi
    
    if [ "$NGINX_PAGESPEED_STORAGE" == "memcached" ]; then
        if [ -z ${NGINX_PAGESPEED_MEMCACHED+x} ]; then
            echo "env: NGINX_PAGESPEED_STORAGE: [ ${NGINX_PAGESPEED_STORAGE} ], but NGINX_PAGESPEED_MEMCACHED not set"
            rm -f /etc/nginx/conf.d/pagespeed-memcached.conf
        else
            echo "env: NGINX_PAGESPEED_MEMCACHED: [ ${NGINX_PAGESPEED_MEMCACHED} ]"
            printf "# memcached storage backend\n" 									>  /etc/nginx/conf.d/pagespeed-memcached.conf
            printf "pagespeed MemcachedThreads 1;\n" 								>> /etc/nginx/conf.d/pagespeed-memcached.conf
            printf "pagespeed MemcachedServers \"${NGINX_PAGESPEED_MEMCACHED}\";\n" >> /etc/nginx/conf.d/pagespeed-memcached.conf
        fi
    fi
fi


# remove default server configuration if requested
if [ "$NGINX_DEFAULT_SERVER" == "off" ]; then
    echo "env: NGINX_DEFAULT_SERVER: [ ${NGINX_DEFAULT_SERVER} ] - removing default server configuration"
    rm -f /etc/nginx/conf.d/default.conf
fi


# add custom nginx config include path
if [ -z ${NGINX_INCLUDE_PATH+x} ] || [ "$NGINX_INCLUDE_PATH" == "" ]; then
    echo "env: NGINX_INCLUDE_PATH not specified: [ SKIP ]"
else
    echo "env: NGINX_INCLUDE_PATH: [ ${NGINX_INCLUDE_PATH} ]"
    sed -i "/custom configurations/cinclude ${NGINX_INCLUDE_PATH}; # include custom configurations" /etc/nginx/nginx.conf
    
    for f in ${NGINX_INCLUDE_PATH}; do
        echo "conf: $f";
    done
fi
