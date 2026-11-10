#!/bin/sh

BASE="/mnt/us/pw3-reading-time"
DATA="$BASE/reading-time.tsv"
REPORT="$BASE/report.txt"
STATE="$BASE/state.txt"
LOG="$BASE/service.log"
CC_DB="/var/local/cc.db"
INTERVAL=5
SLEEP_INTERVAL=30
SAVE_INTERVAL=30
CATALOG_DELAY=10
CATALOG_MAX_AGE=120
TAB="$(printf '\t')"

mkdir -p "$BASE"
umask 077
[ -f "$DATA" ] || printf 'date\tbook_id\tseconds\ttitle\n' > "$DATA"

prop() {
    lipc-get-prop "$1" "$2" 2>/dev/null
}

clean_field() {
    printf '%s' "$1" | tr '\t\r\n' '   '
}

decode_url() {
    printf '%s\n' "$1" | awk '
    function hex(c) { return index("0123456789ABCDEF", toupper(c)) - 1 }
    {
        out=""
        for (i=1; i<=length($0); i++) {
            c=substr($0,i,1)
            if (c=="%" && i+2<=length($0)) {
                h1=hex(substr($0,i+1,1)); h2=hex(substr($0,i+2,1))
                if (h1>=0 && h2>=0) { out=out sprintf("%c",h1*16+h2); i+=2 }
                else out=out c
            } else if (c=="+") out=out " "
            else out=out c
        }
        print out
    }'
}

read_book() {
    context="$1"
    metadata="$2"

    book_id="$(printf '%s' "$metadata" | sed -n 's/.*"cdeKey":"\([^"]*\)".*/\1/p')"
    encoded="$(printf '%s' "$context" | sed -n 's|.*file://\([^?]*\).*|\1|p')"
    decoded="$(decode_url "$encoded")"
    leaf="${decoded##*/}"

    # PW3 activeContext commonly exposes AZW instead of the newer _HEX.kfx form.
    if [ -z "$book_id" ]; then
        book_id="$(printf '%s' "$leaf" | sed -n 's/.*_\([A-Za-z0-9][A-Za-z0-9]*\)\.\(azw\|azw3\|mobi\|kfx\)$/\1/p')"
    fi
    [ -n "$book_id" ] || book_id="unknown"

    title="$(printf '%s' "$leaf" | sed 's/\.[Aa][Zz][Ww]3*$//;s/\.[Mm][Oo][Bb][Ii]$//;s/\.[Kk][Ff][Xx]$//')"
    if [ "$book_id" != "unknown" ]; then
        title="$(printf '%s' "$title" | sed "s/_${book_id}$//")"
    fi
    [ -n "$title" ] || title="$book_id"
    book_id="$(clean_field "$book_id")"
    title="$(clean_field "$title")"
    if [ "$book_id" != "unknown" ]; then
        book_source="lipc"
    else
        book_source=""
    fi
}

read_catalog_book() {
    [ -r "$CC_DB" ] || return 1
    command -v sqlite3 >/dev/null 2>&1 || return 1

    row="$(sqlite3 -readonly -separator "$TAB" "$CC_DB" "SELECT replace(replace(replace(COALESCE(p_cdeKey,''),char(9),' '),char(10),' '),char(13),' '), replace(replace(replace(COALESCE(p_titles_0_nominal,''),char(9),' '),char(10),' '),char(13),' '), COALESCE(p_lastAccess,'') FROM Entries WHERE p_percentFinished IS NOT NULL AND COALESCE(p_mimeType,'') LIKE '%ebook%' ORDER BY p_lastAccess DESC LIMIT 1;" 2>/dev/null)"
    [ -n "$row" ] || return 1

    catalog_id="$(printf '%s\n' "$row" | cut -f1)"
    catalog_title="$(printf '%s\n' "$row" | cut -f2)"
    catalog_access="$(printf '%s\n' "$row" | cut -f3)"
    case "$catalog_access" in
        ''|*[!0-9]*) return 1 ;;
    esac

    catalog_now="$(date +%s)"
    catalog_age=$((catalog_now-catalog_access))
    if [ "$catalog_age" -lt 0 ] || [ "$catalog_age" -gt "$CATALOG_MAX_AGE" ]; then
        return 1
    fi
    [ -n "$catalog_id" ] || return 1
    [ -n "$catalog_title" ] || catalog_title="$catalog_id"

    book_id="$(clean_field "$catalog_id")"
    title="$(clean_field "$catalog_title")"
    book_source="catalog"
    return 0
}

format_time() {
    total="$1"
    hours=$((total/3600))
    mins=$(((total%3600)/60))
    secs=$((total%60))
    printf '%dh %dm %ds' "$hours" "$mins" "$secs"
}

write_report() {
    total="$(awk -F '\t' 'NR>1{s+=$3}END{print s+0}' "$DATA")"
    today="$(date +%Y-%m-%d)"
    today_total="$(awk -F '\t' -v d="$today" 'NR>1&&$1==d{s+=$3}END{print s+0}' "$DATA")"
    {
        echo "PW3 native reading-time guarded test"
        echo "updated: $(date)"
        echo "service_state: $service_state"
        echo "active_app: $app"
        echo "power_state: $power"
        echo "current_book_id: $current_id"
        echo "current_title: $current_title"
        echo "current_book_source: $current_source"
        echo "today: $(format_time "$today_total")"
        echo "total: $(format_time "$total")"
        echo
        echo "Recorded sessions:"
        awk -F '\t' 'NR>1{print $1 " | " $3 "s | " $4 " | " $2}' "$DATA"
    } > "$REPORT.tmp" && mv "$REPORT.tmp" "$REPORT"
}

bucket=0
bucket_date=""
bucket_id=""
bucket_title=""
flush() {
    if [ "$bucket" -gt 0 ] && [ -n "$bucket_id" ]; then
        printf '%s\t%s\t%s\t%s\n' "$bucket_date" "$bucket_id" "$bucket" "$bucket_title" >> "$DATA"
    fi
    bucket=0
    bucket_date=""
    bucket_id=""
    bucket_title=""
    write_report
}

cleanup() {
    service_state="stopped"
    flush
}
trap 'cleanup; trap - INT TERM HUP EXIT; exit 0' INT TERM HUP
trap cleanup EXIT

previous="$(date +%s)"
was_reader=0
current_id=""
current_title=""
current_source=""
catalog_wait=0
pending_seconds=0
service_state="waiting"
app=""
power=""
echo "$(date): service started, pid=$$, compat=catalog-fallback-v1" >> "$LOG"
write_report

while :; do
    now="$(date +%s)"
    delta=$((now-previous))
    today="$(date +%Y-%m-%d)"
    app="$(prop com.lab126.appmgrd activeApp)"
    power="$(prop com.lab126.powerd state)"
    reader=0
    wait_seconds="$INTERVAL"

    if [ "$app" = "com.lab126.booklet.reader" ] && [ "$power" = "active" ]; then
        reader=1
        context="$(prop com.lab126.appmgrd activeContext)"
        metadata="$(prop com.lab126.yjr.annotations getCurrentBookMetadata)"
        read_book "$context" "$metadata"

        if [ "$book_id" = "unknown" ]; then
            if [ "$was_reader" -eq 1 ] && [ "$current_source" = "catalog" ] && [ -n "$current_id" ] && [ "$current_id" != "unknown" ]; then
                book_id="$current_id"
                title="$current_title"
                book_source="catalog"
            else
                if [ "$was_reader" -eq 1 ] && [ "$delta" -gt 0 ] && [ "$delta" -le 15 ]; then
                    catalog_wait=$((catalog_wait+delta))
                fi
                if [ "$catalog_wait" -ge "$CATALOG_DELAY" ]; then
                    read_catalog_book || true
                fi
            fi
        else
            catalog_wait=0
        fi

        if [ "$was_reader" -eq 1 ] && [ -n "$current_id" ] && [ "$current_id" != "$book_id" ]; then
            flush
        fi
        current_id="$book_id"
        current_title="$title"
        current_source="$book_source"
        service_state="reading"
    elif [ "$power" != "active" ]; then
        service_state="sleeping"
        wait_seconds="$SLEEP_INTERVAL"
    else
        service_state="waiting"
    fi

    if [ "$was_reader" -eq 1 ] && [ "$reader" -eq 1 ] && [ "$delta" -gt 0 ] && [ "$delta" -le 15 ]; then
        if [ -z "$current_id" ] || [ "$current_id" = "unknown" ]; then
            pending_seconds=$((pending_seconds+delta))
        else
            if [ -n "$bucket_date" ] && [ "$bucket_date" != "$today" ]; then
                flush
            fi
            bucket_date="$today"
            bucket_id="$current_id"
            bucket_title="$current_title"
            bucket=$((bucket+delta+pending_seconds))
            pending_seconds=0
            [ "$bucket" -ge "$SAVE_INTERVAL" ] && flush
        fi
    elif [ "$was_reader" -eq 1 ] && [ "$reader" -eq 0 ]; then
        flush
        pending_seconds=0
        catalog_wait=0
        current_source=""
    fi

    printf 'state=%s\npid=%s\napp=%s\npower=%s\nbook_id=%s\ntitle=%s\nbook_source=%s\nupdated=%s\n' \
        "$service_state" "$$" "$app" "$power" "$current_id" "$current_title" "$current_source" "$now" \
        > "$STATE.tmp" && mv "$STATE.tmp" "$STATE"

    previous="$now"
    was_reader="$reader"
    sleep "$wait_seconds"
done
