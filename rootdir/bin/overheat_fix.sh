#!/system/bin/sh
# Performance Fix v2.7.0 (Helio G99 - Loop Optimized)
# Author: aerichandesu

MODDIR=${0%/*}

write() {
    if [ -f "$2" ]; then
        [ "$(cat "$2" 2>/dev/null)" = "$1" ] && return
        chmod 666 "$2" 2>/dev/null
        echo "$1" > "$2" 2>/dev/null
    fi
}

# Fix audit/SELinux rate limit spam
auditctl -e 0 2>/dev/null
auditctl -r 0 2>/dev/null

# [SCHED] Adaptive Energy Scaling
write 5 /dev/cpuctl/top-app/cpu.uclamp.min
write 1 /dev/cpuctl/top-app/cpu.uclamp.latency_sensitive
write 0 /dev/cpuctl/foreground/cpu.uclamp.min
write 100 /dev/cpuctl/foreground/cpu.uclamp.max

# [GED] Adaptive MediaTek Graphics
write 1 /sys/module/ged/parameters/gpu_dvfs_enable
write 1 /sys/module/ged/parameters/ged_smart_boost
write 0 /sys/module/ged/parameters/ged_boost_enable
write 10 /sys/module/ged/parameters/gx_fb_dvfs_margin
write 0 /sys/module/ged/parameters/ged_log_trace_enable
write 0 /sys/module/ged/parameters/ged_log_perf_trace_enable

# [IO] Storage (UFS 2.2 Efficiency)
for disk in /sys/block/sd* /sys/block/mmcblk*; do
    [ -d "$disk" ] || continue
    write 256 $disk/queue/nr_requests
    write 256 $disk/queue/read_ahead_kb
    write 0 $disk/queue/add_random
    write 1 $disk/queue/nomerges
    write 0 $disk/queue/iostats
    if grep -q "none" $disk/queue/scheduler; then
        echo "none" > $disk/queue/scheduler 2>/dev/null
    else
        echo "mq-deadline" > $disk/queue/scheduler 2>/dev/null
    fi
done

# Background loop for thermal control
(
    # Get max frequencies dynamically
    MAX_FREQ_LITTLE=$(cat /sys/devices/system/cpu/cpufreq/policy0/cpuinfo_max_freq 2>/dev/null)
    MAX_FREQ_BIG=$(cat /sys/devices/system/cpu/cpufreq/policy6/cpuinfo_max_freq 2>/dev/null)
    
    while true; do
        BAT_TEMP=$(cat /sys/class/thermal/thermal_zone25/temp 2>/dev/null)
        SOC_TEMP=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null)
        [ -z "$BAT_TEMP" ] && BAT_TEMP=0
        [ -z "$SOC_TEMP" ] && SOC_TEMP=0

        # Critical Overheat (> 45°C Battery or > 75°C SOC)
        if [ "$BAT_TEMP" -ge 45000 ] || [ "$SOC_TEMP" -ge 75000 ]; then
            write 16 /sys/class/power_supply/battery/charge_control_limit
            write 1 /sys/class/power_supply/battery/input_suspend
            write 1400000 /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq
            write 1400000 /sys/devices/system/cpu/cpufreq/policy6/scaling_max_freq
        # Moderate Heat (42°C - 44°C Battery)
        elif [ "$BAT_TEMP" -ge 42000 ]; then
            write 12 /sys/class/power_supply/battery/charge_control_limit
            write 0 /sys/class/power_supply/battery/input_suspend
            write 1800000 /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq
            write 1800000 /sys/devices/system/cpu/cpufreq/policy6/scaling_max_freq
        # Normal / Cool (< 40°C Battery)
        else
            write 0 /sys/class/power_supply/battery/charge_control_limit
            write 0 /sys/class/power_supply/battery/input_suspend
            [ -n "$MAX_FREQ_LITTLE" ] && write "$MAX_FREQ_LITTLE" /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq
            [ -n "$MAX_FREQ_BIG" ] && write "$MAX_FREQ_BIG" /sys/devices/system/cpu/cpufreq/policy6/scaling_max_freq
        fi
        
        if [ "$BAT_TEMP" -ge 40000 ]; then
            sleep 10
        else
            sleep 30
        fi
    done
) &

exit 0
