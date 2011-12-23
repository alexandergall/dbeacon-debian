#! /bin/sh

### BEGIN INIT INFO
# Provides:          dbeacon
# Required-Start:    $network $remote_fs
# Required-Stop:     $network $remote_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Multicast Beacon
# Description:       Multicast Beacon supporting both IPv4 and IPv6 multicast, collecting information using
#                    both Any Source Multicast (ASM) and Source-Specific Multicast (SSM).
### END INIT INFO

PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
DAEMON=/usr/bin/dbeacon
NAME=dbeacon
DESC="Multicast Beacon"
CONFIG_DIR=/etc/dbeacon

test -x $DAEMON || exit 0
test -d $CONFIG_DIR || exit 0

DAEMON_OPTS="-syslog"

. /lib/lsb/init-functions

case "$1" in
  start)
    log_daemon_msg "Starting $DESC"
    for CONFIG in `cd $CONFIG_DIR; ls *.conf 2> /dev/null`; do
        NAME=${CONFIG%%.conf}
        log_progress_msg "$NAME"
        STATUS=0

        start-stop-daemon --start --quiet \
            --pidfile /var/run/dbeacon.${NAME}.pid \
            --exec $DAEMON -- $DAEMON_OPTS \
            -D \
            -c ${CONFIG_DIR}/${NAME}.conf \
            -p /var/run/dbeacon.${NAME}.pid || STATUS=1
    done
    log_end_msg ${STATUS:-0}
    ;;
  stop)
        log_daemon_msg "Stopping $DESC"
    for PIDFILE in `ls /var/run/dbeacon.*.pid 2> /dev/null`; do
        NAME=`echo $PIDFILE | cut -c18-`
        NAME=${NAME%%.pid}
        kill `cat $PIDFILE` || true
        start-stop-daemon --stop --oknodo --quiet \
            --exec $DAEMON --pidfile $PIDFILE
        log_progress_msg "$NAME"
    done
    log_end_msg 0
    ;;
  status)
    GLOBAL_STATUS=0
    for CONFIG in `cd $CONFIG_DIR; ls *.conf 2> /dev/null`; do
        NAME=${CONFIG%%.conf}
        status_of_proc -p /var/run/dbeacon.${NAME}.pid dbeacon "dbeacon '${NAME}'" || GLOBAL_STATUS=1
    done
    exit $GLOBAL_STATUS
    ;;
  force-reload|restart)
    $0 stop
    sleep 1
    $0 start
    ;;
  *)
    N=/etc/init.d/$NAME
    echo "Usage: $N {start|stop|status|restart|force-reload}" >&2
    exit 1
    ;;
esac

exit 0
