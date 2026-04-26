#!/system/bin/sh
# Performance Fix v2.5.1 (Helio G99 - Direct Fix)
# Author: aerichandesu

MODDIR=${0%/*}

write() {
    if [ -f "$2" ]; then
        chmod 666 "$2" 2>/dev/null
        echo "$1" > "$2" 2>/dev/null
    fi
}

# [LOG] Silence log output and fix AIDL/Millet/WLAN spam
write "0 0 0 0" /proc/sys/kernel/printk
write 0 /proc/sys/kernel/printk_ratelimit
write 0 /sys/module/printk/parameters/console_suspend
# Fix audit/SELinux rate limit spam
auditctl -e 0 2>/dev/null
auditctl -r 0 2>/dev/null

# Restore Millet userspace to fix kernel "src_port 2 invalid" IPC errors
# Millet is left default to prevent IPC mismatch
# setprop calls removed to avoid SEPolicy neverallow violations

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

# [VM] Virtual Memory Balance
write 2000 /proc/sys/vm/dirty_expire_centisecs
write 1000 /proc/sys/vm/dirty_writeback_centisecs
write 15 /proc/sys/vm/dirty_ratio
write 5 /proc/sys/vm/dirty_background_ratio
write 100 /proc/sys/vm/vfs_cache_pressure
write 100 /proc/sys/vm/swappiness
write 0 /proc/sys/vm/page-cluster
write 150 /proc/sys/vm/watermark_scale_factor

# [NET] Network
write 1 /proc/sys/net/ipv4/tcp_low_latency
write 1 /proc/sys/net/ipv4/tcp_slow_start_after_idle
write 1 /proc/sys/net/ipv4/tcp_tw_reuse
write 0 /proc/sys/net/ipv4/tcp_timestamps
write 0 /proc/sys/net/ipv4/tcp_ecn

# [IO] Storage (UFS 2.2 Efficiency)
for disk in /sys/block/sd* /sys/block/mmcblk*; do
    write 256 $disk/queue/nr_requests
    write 256 $disk/queue/read_ahead_kb
    write 0 $disk/queue/add_random
    write 1 $disk/queue/nomerges
    write 0 $disk/queue/iostats
    echo "none" > $disk/queue/scheduler 2>/dev/null
done

# [SCHED] Kernel Scheduler Balance
write 2000000 /proc/sys/kernel/sched_latency_ns
write 400000 /proc/sys/kernel/sched_min_granularity_ns
write 500000 /proc/sys/kernel/sched_wakeup_granularity_ns
write 500000 /proc/sys/kernel/sched_migration_cost_ns
write 1 /proc/sys/kernel/sched_util_clamp_min_rt_default
write 0 /proc/sys/kernel/sched_autogroup_enabled

# Background loop for thermal and performance tasks
(
    sleep 30
    while true; do
        # 1. Thermal control
        BAT_TEMP=$(cat /sys/class/thermal/thermal_zone25/temp 2>/dev/null)
        SOC_TEMP=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null)
        [ -z "$BAT_TEMP" ] && BAT_TEMP=0
        [ -z "$SOC_TEMP" ] && SOC_TEMP=0

        # High heat (> 45°C Battery or > 70°C SOC)
        if [ "$BAT_TEMP" -ge 45000 ] || [ "$SOC_TEMP" -ge 70000 ]; then
            write 16 /sys/class/power_supply/battery/charge_control_limit
            write 1 /sys/class/power_supply/battery/input_suspend
            write 1500000 /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq
            write 1500000 /sys/devices/system/cpu/cpufreq/policy6/scaling_max_freq
        # Moderate heat (43°C - 44°C Battery)
        elif [ "$BAT_TEMP" -ge 43000 ]; then
            write 14 /sys/class/power_supply/battery/charge_control_limit
            write 1 /sys/class/power_supply/battery/input_suspend
            write 1900000 /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq
            write 1700000 /sys/devices/system/cpu/cpufreq/policy6/scaling_max_freq
        # Warm (40°C - 42°C Battery)
        elif [ "$BAT_TEMP" -ge 40000 ]; then
            write 12 /sys/class/power_supply/battery/charge_control_limit
            write 0 /sys/class/power_supply/battery/input_suspend
            write 2000000 /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq
            write 2200000 /sys/devices/system/cpu/cpufreq/policy6/scaling_max_freq
        # Cool (< 38°C Battery)
        elif [ "$BAT_TEMP" -le 38000 ]; then
            write 0 /sys/class/power_supply/battery/charge_control_limit
            write 0 /sys/class/power_supply/battery/input_suspend
            write 2000000 /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq
            write 2200000 /sys/devices/system/cpu/cpufreq/policy6/scaling_max_freq
        fi
        
        # 2. Refresh rate control
        # Left disabled to fix MTK Display CRTC "mtk_dsc_sw_rst not attach CRTC yet" log loop
        # setprop persist.vendor.display.mode.vrr.enabled 0 2>/dev/null
        # setprop persist.vendor.display.mode.fps.switch 0 2>/dev/null
        
        sleep 30
    done
) &

exit 0
