#!/bin/sh

# PW3 reading-time adaptation installer.
# Verified target: Kindle Paperwhite 3, firmware 5.16.2.1.1, LanguageBreak.

BASE="/mnt/us/pw3-reading-time"
LEGACY_BASE="/mnt/us/pw3-reading-time-test"
BIN="$BASE/bin"
DASH="$BASE/dashboard"
APP_ID="com.theo.pw3readingtime.dashboard"
JOB="pw3-reading-time"
LEGACY_JOB="pw3-reading-time-test"
CONF="/etc/upstart/$JOB.conf"
LEGACY_CONF="/etc/upstart/$LEGACY_JOB.conf"
PAYLOAD_CONF="$BASE/upstart/$JOB.conf"
APPREG=""
LOG="$BASE/install.log"
LAUNCHER="/mnt/us/documents/PW3阅读时间.sh"

toast() {
    lipc-set-prop com.lab126.system toasterMessage "$1" >/dev/null 2>&1 || true
}

fail() {
    echo "$(date): ERROR: $1" >> "$LOG"
    toast "PW3 reading-time install failed"
    exit 1
}

root_rw=0
root_ro() {
    if [ "$root_rw" -eq 1 ]; then
        mntroot ro >/dev/null 2>&1 || /usr/sbin/mntroot ro >/dev/null 2>&1 || /sbin/mntroot ro >/dev/null 2>&1 || true
        root_rw=0
    fi
}

mkdir -p "$BASE" "$BASE/backups" || exit 1
echo "$(date): installer started, uid=$(id -u)" >> "$LOG"

[ "$(id -u)" -eq 0 ] || fail "not root; launch with ;log runme"
[ -x /usr/bin/mesquite ] || fail "Mesquite unavailable"
[ -x /sbin/initctl ] || fail "Upstart unavailable"
command -v sqlite3 >/dev/null 2>&1 || fail "sqlite3 unavailable"
command -v lipc-get-prop >/dev/null 2>&1 || fail "LIPC unavailable"

for required in \
    "$BIN/pw3-reading-time-daemon.sh" \
    "$BIN/build-dashboard-data.sh" \
    "$DASH/config.xml" \
    "$DASH/index.html" \
    "$DASH/style-v1021.css" \
    "$DASH/pw3-layout-v3.css" \
    "$DASH/pw3-dynamic-v11.css" \
    "$DASH/pw3-dynamic-v1.js" \
    "$PAYLOAD_CONF" \
    "$LAUNCHER"; do
    [ -f "$required" ] || fail "missing payload: $required"
done

for candidate in /var/local/appreg.db /opt/var/local/appreg.db; do
    [ -f "$candidate" ] && { APPREG="$candidate"; break; }
done
[ -n "$APPREG" ] || fail "appreg.db not found"

/sbin/initctl stop "$JOB" >/dev/null 2>&1 || true
/sbin/initctl stop "$LEGACY_JOB" >/dev/null 2>&1 || true

stamp="$(date +%Y%m%d-%H%M%S)"
if [ ! -f "$BASE/reading-time.tsv" ] && [ -f "$LEGACY_BASE/reading-time.tsv" ]; then
    cp "$LEGACY_BASE/reading-time.tsv" "$BASE/reading-time.tsv" || fail "cannot migrate legacy reading data"
    echo "$(date): migrated reading data from $LEGACY_BASE" >> "$LOG"
fi
if [ -f "$BASE/reading-time.tsv" ]; then
    cp "$BASE/reading-time.tsv" "$BASE/backups/reading-time-before-$stamp.tsv" || fail "cannot back up reading data"
else
    printf 'date\tbook_id\tseconds\ttitle\n' > "$BASE/reading-time.tsv" || fail "cannot create reading data"
fi
cp "$APPREG" "$BASE/backups/appreg-before-$stamp.db" 2>/dev/null || true
[ -f "$CONF" ] && cp "$CONF" "$BASE/backups/$JOB-$stamp.conf" 2>/dev/null || true
[ -f "$LEGACY_CONF" ] && cp "$LEGACY_CONF" "$BASE/backups/$LEGACY_JOB-$stamp.conf" 2>/dev/null || true

chmod 755 "$BIN/pw3-reading-time-daemon.sh" "$BIN/build-dashboard-data.sh" "$LAUNCHER" || fail "cannot set executable permissions"
find "$DASH" -type f -exec chmod 644 {} \; 2>/dev/null || true

lipc-set-prop com.lab126.appmgrd stop "app://$APP_ID" >/dev/null 2>&1 || true

trap root_ro EXIT INT TERM HUP
if mntroot rw >/dev/null 2>&1 || /usr/sbin/mntroot rw >/dev/null 2>&1 || /sbin/mntroot rw >/dev/null 2>&1; then
    root_rw=1
else
    fail "cannot remount rootfs read-write"
fi
cp "$PAYLOAD_CONF" "$CONF.new" || fail "cannot stage Upstart job"
chmod 644 "$CONF.new"
mv "$CONF.new" "$CONF" || fail "cannot install Upstart job"
rm -f "$LEGACY_CONF"
/sbin/initctl reload-configuration >/dev/null 2>&1 || true
root_ro
trap - EXIT INT TERM HUP

sqlite3 "$APPREG" <<EOF
BEGIN IMMEDIATE;
INSERT OR IGNORE INTO interfaces(interface) VALUES('application');
INSERT OR IGNORE INTO handlerIds(handlerId) VALUES('$APP_ID');
INSERT OR REPLACE INTO properties(handlerId,name,value) VALUES('$APP_ID','lipcId','$APP_ID');
INSERT OR REPLACE INTO properties(handlerId,name,value) VALUES('$APP_ID','command','/usr/bin/mesquite -l $APP_ID -c file://$DASH/');
INSERT OR REPLACE INTO properties(handlerId,name,value) VALUES('$APP_ID','supportedOrientation','U');
INSERT OR REPLACE INTO properties(handlerId,name,value) VALUES('$APP_ID','unloadPolicy','unloadOnPause');
INSERT OR REPLACE INTO properties(handlerId,name,value) VALUES('$APP_ID','extend-start','Y');
INSERT OR REPLACE INTO properties(handlerId,name,value) VALUES('$APP_ID','maxLoadTime','60');
INSERT OR REPLACE INTO properties(handlerId,name,value) VALUES('$APP_ID','maxGoTime','60');
INSERT OR REPLACE INTO properties(handlerId,name,value) VALUES('$APP_ID','maxPauseTime','10');
INSERT OR REPLACE INTO properties(handlerId,name,value) VALUES('$APP_ID','maxUnloadTime','10');
COMMIT;
EOF
[ "$?" -eq 0 ] || fail "cannot register WebView application"

"$BIN/build-dashboard-data.sh" >> "$LOG" 2>&1 || fail "cannot build initial dashboard data"
/sbin/initctl start "$JOB" >> "$LOG" 2>&1 || /sbin/initctl restart "$JOB" >> "$LOG" 2>&1 || fail "cannot start timer service"

lipc-set-prop com.lab126.scanner doFullScan 1 >/dev/null 2>&1 || lipc-set-prop com.lab126.scanner triggerUpdate 1 >/dev/null 2>&1 || true
echo "$(date): installation complete" >> "$LOG"
toast "PW3 reading-time installed"
sync
exit 0
