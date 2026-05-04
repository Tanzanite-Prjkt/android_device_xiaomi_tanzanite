#!/system/bin/sh
# Performance and Thermal Fix for Tanzanite (Helio G99)
# Integrated from Magisk/KSU module
# Author: aerichandesu x Gemini CLI

write() {
    if [ -f "$2" ]; then
        chmod 666 "$2" 2>/dev/null
        echo "$1" > "$2" 2>/dev/null
    fi
}

# Cleanup and Crash Prevention (from post-fs-data)
rm -rf /data/data/com.google.android.gms/app_phenotype
rm -rf /data/system/users/0/com.google.android.gms.phenotype
rm -rf /data/system/dropbox/*
rm -rf /data/tombstones/*
chmod 777 /data/local/tmp

# Wait for boot completion for the loop
until [ "$(getprop sys.boot_completed)" = "1" ]; do
    sleep 5
done

# Wait extra time for system to settle
sleep 15

# Background loop for thermal management
while true; do
    BAT_TEMP=$(cat /sys/class/thermal/thermal_zone25/temp 2>/dev/null)
    SOC_TEMP=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null)
    [ -z "$BAT_TEMP" ] && BAT_TEMP=0
    [ -z "$SOC_TEMP" ] && SOC_TEMP=0

    # High heat (> 43°C Battery or > 65°C SOC) - Critical Throttling
    if [ "$BAT_TEMP" -ge 43000 ] || [ "$SOC_TEMP" -ge 65000 ]; then
        write 16 /sys/class/power_supply/battery/charge_control_limit
        write 1 /sys/class/power_supply/battery/input_suspend
        write 1500000 /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq
        write 1500000 /sys/devices/system/cpu/cpufreq/policy6/scaling_max_freq
    # Moderate heat (40°C - 42°C Battery) - Light Throttling
    elif [ "$BAT_TEMP" -ge 40000 ]; then
        write 14 /sys/class/power_supply/battery/charge_control_limit
        write 0 /sys/class/power_supply/battery/input_suspend
        write 1900000 /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq
        write 1700000 /sys/devices/system/cpu/cpufreq/policy6/scaling_max_freq
    # Warm (38°C - 39°C Battery) - Pre-emptive Limit
    elif [ "$BAT_TEMP" -ge 38000 ]; then
        write 12 /sys/class/power_supply/battery/charge_control_limit
        write 0 /sys/class/power_supply/battery/input_suspend
        write 2000000 /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq
        write 2200000 /sys/devices/system/cpu/cpufreq/policy6/scaling_max_freq
    # Cool (< 38°C Battery) - Normal Performance
    elif [ "$BAT_TEMP" -le 37000 ]; then
        write 8 /sys/class/power_supply/battery/charge_control_limit
        write 0 /sys/class/power_supply/battery/input_suspend
        write 2000000 /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq
        write 2200000 /sys/devices/system/cpu/cpufreq/policy6/scaling_max_freq
    fi
    
    sleep 30
done
