#!/bin/ash
# lokasi: /usr/bin/... (chmod 0755)
# Script: autoip.sh
# Deskripsi: Monitoring koneksi, trigger airplane mode via ADB jika gagal ping berkali-kali.
# Auto Airplane Mode - Stabil & Tahan Banting 🚀

# === Konfigurasi ===
HOSTS="HOST_SAYA"
PING_FAIL_LIMIT=7
WAIT_TIME=5
SLEEP_INTERVAL=3 #waktu tunggu koneksi lagi
ADB_DEVICE_ID=""  # Kosongkan jika hanya 1 device. Bisa diisi "device_serial"

# === Variabel internal ===
failed_count=0

log() {
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $*"
}

check_adb_device() {
    if [ -n "$ADB_DEVICE_ID" ]; then
        adb -s "$ADB_DEVICE_ID" get-state | grep -q "device"
    else
        adb get-state | grep -q "device"
    fi
}

run_adb_cmd() {
    local CMD="$1"
    if [ -n "$ADB_DEVICE_ID" ]; then
        adb -s "$ADB_DEVICE_ID" $CMD
    else
        adb $CMD
    fi
}

enable_airplane_mode() {
    log "🛫 Mengaktifkan mode pesawat..."
    run_adb_cmd "shell settings put global airplane_mode_on 1"
    run_adb_cmd "shell am broadcast -a android.intent.action.AIRPLANE_MODE --ez state true"
}

disable_airplane_mode() {
    log "🛬 Menonaktifkan mode pesawat..."
    run_adb_cmd "shell settings put global airplane_mode_on 0"
    run_adb_cmd "shell am broadcast -a android.intent.action.AIRPLANE_MODE --ez state false"
}

check_connectivity() {
    for HOST in $HOSTS; do
        if ping -c 1 -W 1 "$HOST" >/dev/null 2>&1; then
            log "✅  $HOST"
            return 0
        fi
    done
    return 1
}

while true; do
    if ! check_adb_device; then
        log "❌  Perangkat ADB. Mencoba ulang dalam 10 detik..."
        sleep 10
        continue
    fi

    if check_connectivity; then
        failed_count=0
    else
        log "❌  Semua host gagal dijangkau."
        failed_count=$((failed_count + 1))
        if [ "$failed_count" -ge "$PING_FAIL_LIMIT" ]; then
            log "💣 Gagal ping $PING_FAIL_LIMIT kali. Trigger airplane mode!"
            enable_airplane_mode
            sleep "$WAIT_TIME"
            disable_airplane_mode
            failed_count=0
        fi
    fi

    sleep "$SLEEP_INTERVAL"
done
