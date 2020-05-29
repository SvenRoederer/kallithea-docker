#!/bin/bash

CFG_FILE=/opt/kallithea/production.ini
[ -z ${DB_TYPE} ] && DB_TYPE=sqlite

if [ ! -f "${CFG_FILE}" ]
then
    kallithea-cli config-create ${CFG_FILE} host=0.0.0.0 database_engine=${DB_TYPE}
    case ${DB_TYPE} in
      sqlite)
        sed -i 's#^sqlalchemy\.url = .*#sqlalchemy.url = sqlite:///%(here)s/cfg/kallithea.db?timeout=60#g' ${CFG_FILE}
        ;;
      postgres)
        sed -i 's#^sqlalchemy\.url = .*#sqlalchemy.url = postgresql://${DB_USER}:${DB_PASS}@${DB_HOST}:${DB_PORT:-5432}/${DB_NAME}#g' ${CFG_FILE}
        ;;
      mysql)
        echo >&2 TODO: mysql database setup
        exit 1
        ;;
    esac
fi
if [ ! -f "/opt/kallithea/cfg/kallithea.db" ]
then
    kallithea-cli db-create \
      --user=admin --email=admin@admin.com --password=Administrator \
      --repos=/opt/kallithea/repos --force-yes \
      -c ${CFG_FILE}
    kallithea-cli front-end-build
fi
getent >/dev/null passwd kallithea || adduser \
    --system --uid 119 --disabled-password --disabled-login --ingroup www-data kallithea
chown kallithea:www-data /opt/kallithea/
chown kallithea:www-data /opt/kallithea/cfg/kallithea.db
chown -R kallithea:www-data /opt/kallithea/repos
chown -R kallithea:www-data /opt/kallithea/data
chown -R kallithea:www-data /opt/kallithea/cfg
chmod -R o-rx /opt/kallithea/cfg

# start web-server
gearbox serve -c ${CFG_FILE} --user=kallithea
