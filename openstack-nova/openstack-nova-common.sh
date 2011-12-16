. /etc/rc.d/init.d/functions

user="nova"
flagfile="/etc/nova/$name.conf"
pidfile="/var/run/nova/$name.pid"
lockfile="/var/lock/subsys/openstack-$name"
migrate_repo="/usr/lib/python2.6/site-packages/nova/db/sqlalchemy/migrate_repo/versions"

[ -f "/etc/sysconfig/openstack-nova-common" ] && . "/etc/sysconfig/openstack-nova-common"
[ -f "/etc/sysconfig/openstack-$name" ] && . "/etc/sysconfig/openstack-$name"

OPTIONS="--flagfile=$flagfile $NOVA_COMMON_OPTIONS $OPTIONS"

DEFAULT_FORMAT="${name} %(levelname)s %(message)s"
CONTEXT_FORMAT="${name} %(levelname)s %(module)s %(funcName)s %(message)s"

start() {
    expected_version=$(ls "$migrate_repo" | grep -v __init__.py |
                       cut -d_ -f 1 | uniq | tail -1 | sed 's,^0,,')

    export PYTHON_EGG_CACHE=/tmp/$(whoami)/PYTHON_EGG_CACHE
    db_version=$(/usr/local/bin/nova-manage db version)
    if [[ "$db_version" != "$expected_version" ]]
    then
      echo "Refusing to start; database not completely initialized." >&2
      echo "$db_version != $expected_version." >&2
      exit 1
    fi
    export PYTHON_EGG_CACHE=/tmp/$user/PYTHON_EGG_CACHE
    echo -n "Starting $name: "
    daemonize -p "$pidfile" -u "$user" -l "$lockfile" \
              -a -e "/var/log/nova/$name-stderr.log" "/usr/bin/$name" \
                --logging_default_format_string="$DEFAULT_FORMAT" \
                --logging_context_format_string="$CONTEXT_FORMAT" \
                $OPTIONS
    retval=$?
    [ $retval -eq 0 ] && touch "$lockfile"
    [ $retval -eq 0 ] && success || failure
    echo
    return $retval
}

stop() {
    echo -n "Stopping $name: "
    killproc -p "$pidfile" "/usr/bin/$name"
    retval=$?
    rm -f "$lockfile"
    echo
    return $retval
}

restart() {
    stop
    start
}

rh_status() {
    status -p "$pidfile" "/usr/bin/$name"
}

rh_status_q() {
    rh_status &> /dev/null
}

case "$1" in
    start)
        rh_status_q && exit 0
        $1
        ;;
    stop)
        rh_status_q || exit 0
        $1
        ;;
    restart)
        $1
        ;;
    reload)
        ;;
    status)
        rh_status
        ;;
    condrestart|try-restart)
        rh_status_q || exit 0
        restart
        ;;
    *)
        echo $"Usage: $0 {start|stop|status|restart|condrestart|try-restart}"
        exit 2
esac
exit $?
