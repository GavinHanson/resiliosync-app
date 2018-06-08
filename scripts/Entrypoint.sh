#!/bin/bash
#
# set secret key for rslsync
#
# (c) 2016 nimmis <kjell.havneskold@gmail.com>
#

# make config directory

mkdir -p /home/appbox
mkdir -p /home/appbox/log
mkdir -p /home/appbox/rsldata

chown -R appbox:appbox /home/appbox

if [ ! -f /etc/rsl_installed ]; then

# Install the app.
cd /home/appbox && \
curl https://download-cdn.resilio.com/stable/linux-x64/resilio-sync_x64.tar.gz | tar xfz - && \
mv rslsync /usr/local/bin && \
rm -rf /var/cache/apk/*

# check device name

if [ -z $RSLSYNC_NAME ]; then
  RSLSYNC_NAME=`hostname`
fi

# check sync path

if [ -z $RSLSYNC_PATH ]; then
  RSLSYNC_PATH="/data"
fi

# create base configuration

cat <<EOT > /home/appbox/rslsync.conf
{
  "storage_path" : "/home/appbox/rsldata",
  "listening_port" : 33333,
  "use_upnp" : false,
  "vendor" : "docker",
  "max_file_size_for_versioning" : $RSLSYNC_SIZE,
  "sync_trash_ttl" : $RSLSYNC_TRASH_TIME,
  "device_name" : "$RSLSYNC_NAME",
  "pid_file" : "/home/appbox/rslsync.pid",
EOT
# check to see if webui should be activated

if [ -z $RSLSYNC_USER ] ; then
  # non webui version

  echo "non-WEBUI mode activated, $RSLSYNC_PATH is synced"

  # handle secret key
  if [ -z $RSLSYNC_SECRET ]; then
    RSLSYNC_SECRET=`/usr/local/bin/rslsync --generate-secret`
    echo "add -e RSLSYNC_SECRET=$RSLSYNC_SECRET to your other nodes to sync"
  fi


  cat <<EOT >> /home/appbox/rslsync.conf
  "shared_folders" :
  [
    {
      "secret" : "$RSLSYNC_SECRET", // required field - use --generate-secret in command line to create new secret
      "dir" : "$RSLSYNC_PATH", // * required field
      "use_relay_server" : true, //  use relay server when direct connection fails
      "use_tracker" : true,
      "search_lan" : true,
      "use_sync_trash" : $RSLSYNC_TRASH, // enable SyncArchive to store files deleted on remote devices
      "overwrite_changes" : false, // restore modified files to original version, ONLY for Read-Only folders
      "known_hosts" : // specify hosts to attempt connection without additional search
      [
      ]
    }
  ]
}
EOT

else

  echo "WEBUI mode activated"
  if [ -z $RSLSYNC_PASS ]; then
     RSLSYNC_PASS=`date +%s | sha256sum | base64 | head -c 10 ; echo`
     echo "RSLSYNC_PASS not set, password generated, use "$RSLSYNC_PASS" as password"
  fi
  cat <<EOT >> /home/appbox/rslsync.conf
  "webui" :
  {
    "listen" : "0.0.0.0:80",
    "login" : "$RSLSYNC_USER",
    "password" : "$RSLSYNC_PASS"
  }
}
EOT
fi

setcap cap_net_bind_service=+ep /usr/local/bin/rslsync

# Tell Apex we've installed the app.
curl -i -H "Accept: application/json" -H "Content-Type:application/json" -X POST "https://api.cylo.io/v1/apps/installed/$INSTANCE_ID"
touch /etc/rsl_installed

fi

exec su -c "/usr/local/bin/rslsync --config /home/appbox/rslsync.conf --log /home/appbox/log/rslsync.log --nodaemon" -s /bin/sh appbox