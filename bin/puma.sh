#! /bin/sh

BUNDLE_BIN=/usr/local/rbenv/shims/bundle
PUMA_CONFIG_FILE=$APP_ROOT/current/config/puma.rb
PUMA_PID_FILE=$APP_ROOT/shared/tmp/pids/puma.pid
PUMA_SOCKET=$APP_ROOT/shared/tmp/sockets/puma.sock

# check if puma process is running
puma_is_running() {
  if [ -S $PUMA_SOCKET ] ; then
    if [ -e $PUMA_PID_FILE ] ; then
      if cat $PUMA_PID_FILE | xargs pgrep -P > /dev/null ; then
        return 0
      else
        echo "No puma process found"
      fi
    else
      echo "No puma pid file found"
    fi
  else
    echo "No puma socket found"
  fi

  return 1
}

puma_start() {
  rm -f $PUMA_SOCKET
  if [ -e $PUMA_CONFIG_FILE ] ; then
    $BUNDLE_BIN exec puma -C $PUMA_CONFIG_FILE
  else
    $BUNDLE_BIN exec puma
  fi
}

puma_stop() {
  cat $PUMA_PID_FILE | xargs kill -31
  rm -f $PUMA_PID_FILE
  rm -f $PUMA_SOCKET
}

case "$1" in
  start)
    echo "Starting puma..."
    puma_start
    echo "done"
    ;;

  stop)
    echo "Stopping puma..."
    puma_stop
    echo "done"
    ;;

  restart)
    if puma_is_running ; then
      echo "Hot-restarting puma..."
      puma_stop
      puma_start

      echo "Doublechecking the process restart..."
      sleep 5
      if puma_is_running ; then
        echo "done"
        exit 0
      else
        echo "Puma restart failed :/"
      fi
    fi

    echo "Trying cold reboot"
    bin/puma.sh start
    ;;

  *)
    echo "Usage: script/puma.sh {start|stop|restart}" >&2
    ;;
esac
