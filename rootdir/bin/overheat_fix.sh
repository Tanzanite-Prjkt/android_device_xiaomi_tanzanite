#!/system/bin/sh
# Performance and Thermal Fix for Tanzanite (Helio G99)
# Integrated from Magisk/KSU module - Native Service Version
# Author: aerichandesu x Gemini CLI

TAG="overheat_fix"

log_info() {
    log -t "$TAG" -p i "$1"
}

log_warn() {
    log -t "$TAG" -p w "$1"
}

write() {
    if [ -f "$2" ]; then
        echo "$1" > "$2" 2>/dev/null
    else
        log_warn "File not found: $2"
    fi
}

# 1. Maintenance and Cleanup (Pre-boot completion)
log_info "Starting boot-time maintenance..."

# Note: Maintenance of /data/data and /data/system is moved to system-level 
# or removed to comply with SEPolicy neverallows.
chmod 777 /data/local/tmp 2>/dev/null || true

# 2. Dynamic Thermal Management Loop
log_info "Waiting for boot completion..."
until [ "$(getprop sys.boot_completed)" = "1" ]; do
    sleep 5
done

log_info "Boot completed. Starting thermal monitoring loop."
# Initial settle time
sleep 15

while true; do
    # Thermal Zone mapping for MT6789 (Tanzanite)
    # TZ0: SoC/CPU, TZ25: Battery
    BAT_TEMP=$(cat /sys/class/thermal/thermal_zone25/temp 2>/dev/null)
    SOC_TEMP=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null)
    
    # Fallback to 0 if nodes are inaccessible
    [ -z "$BAT_TEMP" ] && BAT_TEMP=0
    [ -z "$SOC_TEMP" ] && SOC_TEMP=0

    # Logic: Dynamic Thermal Management
    # High heat (> 43°C Battery or > 65°C SoC) - Critical Throttling
    if [ "$BAT_TEMP" -ge 43000 ] || [ "$SOC_TEMP" -ge 65000 ]; then
        log_warn "Critical heat detected (Bat: $BAT_TEMP, SoC: $SOC_TEMP). Throttling..."
        write 16 /sys/class/power_supply/battery/charge_control_limit
        write 1 /sys/class/power_supply/battery/input_suspend
        write 1500000 /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq
        write 1500000 /sys/devices/system/cpu/cpufreq/policy6/scaling_max_freq
    
    # Moderate heat (40°C - 42.9°C Battery) - Light Throttling
    elif [ "$BAT_TEMP" -ge 40000 ]; then
        write 14 /sys/class/power_supply/battery/charge_control_limit
        write 0 /sys/class/power_supply/battery/input_suspend
        write 1900000 /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq
        write 1700000 /sys/devices/system/cpu/cpufreq/policy6/scaling_max_freq
    
    # Normal and Warm states - Hand over frequency control to PowerHAL
    else
        # Reset charging limits but don't touch CPU frequencies
        write 0 /sys/class/power_supply/battery/charge_control_limit
        write 0 /sys/class/power_supply/battery/input_suspend
        
        # Restore default maximums once to allow PowerHAL full range
        # policy0 max: 2.0GHz, policy6 max: 2.2GHz
        write 2000000 /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq
        write 2200000 /sys/devices/system/cpu/cpufreq/policy6/scaling_max_freq
    fi
    
    # Polling interval: 30 seconds
    sleep 30
done
