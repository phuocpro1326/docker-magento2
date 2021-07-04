#!/bin/bash

echo "source /etc/profile.d/bash_completion.sh" >> ~/.bashrc
grep -wq '^source /etc/profile.d/bash_completion.sh' ~/.bashrc || echo 'source /etc/profile.d/bash_completion.sh'>>~/.bashrc
source /etc/profile.d/bash_completion.sh

[ "$DEBUG" = "true" ] && set -x

# If asked, we'll ensure that the www-data is set to the same uid/gid as the
# mounted volume.  This works around permission issues with virtualbox shared
# folders.
if [[ "$UPDATE_UID_GID" = "true" ]]; then
    echo "Updating www-data uid and gid"

    DOCKER_UID=`stat -c "%u" $MAGENTO_ROOT`
    DOCKER_GID=`stat -c "%g" $MAGENTO_ROOT`

    INCUMBENT_USER=`getent passwd $DOCKER_UID | grep -v www-data | cut -d: -f1`
    INCUMBENT_GROUP=`getent group $DOCKER_GID | grep -v www-data | cut -d: -f1`

    echo "Docker: uid = $DOCKER_UID, gid = $DOCKER_GID"
    echo "Incumbent: user = $INCUMBENT_USER, group = $INCUMBENT_GROUP"

    # Once we've established the ids and incumbent ids then we need to free them
    # up (if necessary) and then make the change to www-data.

    [ ! -z "${INCUMBENT_USER}" ] && usermod -u 99$DOCKER_UID $INCUMBENT_USER
    usermod -u $DOCKER_UID www-data

    [ ! -z "${INCUMBENT_GROUP}" ] && groupmod -g 99$DOCKER_GID $INCUMBENT_GROUP
    groupmod -g $DOCKER_GID www-data
fi

# Ensure our Magento directory exists
mkdir -p $MAGENTO_ROOT
chown www-data:www-data $MAGENTO_ROOT
chmod 777 $MAGENTO_ROOT
cd $MAGENTO_ROOT


# Configure Sendmail if required
if [ "$ENABLE_SENDMAIL" == "true" ]; then
    /etc/init.d/sendmail start
fi

# Substitute in php.ini values
[ ! -z "${PHP_MEMORY_LIMIT}" ] && sed -i "s/!PHP_MEMORY_LIMIT!/${PHP_MEMORY_LIMIT}/" /usr/local/etc/php/conf.d/zz-magento.ini
[ ! -z "${UPLOAD_MAX_FILESIZE}" ] && sed -i "s/!UPLOAD_MAX_FILESIZE!/${UPLOAD_MAX_FILESIZE}/" /usr/local/etc/php/conf.d/zz-magento.ini

FLAG=0
if [ "${PHP_ENABLE_XDEBUG_PROFILER}" == "true" ]; then
    FLAG=1
fi
sed -i "s/!PHP_ENABLE_XDEBUG_PROFILER!/${FLAG}/" /usr/local/etc/php/conf.d/zz-xdebug-settings.ini

FLAG=0
if [ "${PHP_ENABLE_XDEBUG_PROFILER_TRIGGER}" == "true" ]; then
    FLAG=1
fi
sed -i "s/!PHP_ENABLE_XDEBUG_PROFILER_TRIGGER!/${FLAG}/" /usr/local/etc/php/conf.d/zz-xdebug-settings.ini

#mkdir -p "${MAGENTO_ROOT}/var/profiler"

[ "$PHP_ENABLE_XDEBUG" = "true" ] && \
    docker-php-ext-enable xdebug && \
    echo "Xdebug is enabled"

[ "$PHP_ENABLE_BLACKFIRE" = "true" ] && \
    docker-php-ext-enable blackfire && \
    echo "Black Fire is enabled"

# Configure PHP-FPM
[ ! -z "${MAGENTO_RUN_MODE}" ] && sed -i "s/!MAGENTO_RUN_MODE!/${MAGENTO_RUN_MODE}/" /usr/local/etc/php-fpm.conf
[ ! -z "${FPM_PM_MAX_REQUESTS}" ] && sed -i "s/!FPM_PM_MAX_REQUESTS!/${FPM_PM_MAX_REQUESTS}/" /usr/local/etc/php-fpm.conf

exec "$@"
