import json
import os
import platform
import time
from dataclasses import dataclass, asdict

import psutil
import cpuinfo


@dataclass(frozen=True)
class CpuUtilization:
    usage_percent: float
    top_process_name: str
    top_process_cmd: str
    top_process_cpu_percent: float


@dataclass(frozen=True)
class MemoryInfo:
    total: str
    available: str
    used: str
    percent: float
    top_process_name: str
    top_process_cmd: str
    top_process_mem: str


@dataclass(frozen=True)
class StorageInfo:
    total: str
    used: str
    free: str
    percent: float


@dataclass(frozen=True)
class SystemInfo:
    cpu_brand: str
    cpu_vendor: str
    cpu_mhz: str
    cpu_physical_cores: int
    architecture: str
    system: str
    release: str
    platform: str


@dataclass(frozen=True)
class SystemData:
    uptime: str
    system_info: SystemInfo
    cpu: CpuUtilization
    memory: MemoryInfo
    storage: StorageInfo
    hostname: str


def format_bytes(size_in_bytes) -> str:
    """Convert bytes to human-readable format (KB, MB, GB, etc.)"""
    units = ["B", "KB", "MB", "GB", "TB"]
    size = float(size_in_bytes)
    for unit in units:
        if size < 1024:
            return f"{size:.2f}{unit}"
        size /= 1024
    return f"{size:.2f}{units[-1]}"


# Credits: Garrett Hyde @stackoverlow https://stackoverflow.com/questions/4048651/function-to-convert-seconds-into-minutes-hours-and-days
def to_display_time(seconds, granularity=2) -> str:
    intervals = (
        ('weeks', 604800),
        ('days', 86400),
        ('hours', 3600),
        ('minutes', 60),
        ('seconds', 1),
    )
    result = []
    for name, count in intervals:
        value = seconds // count
        if value:
            seconds -= value * count
            if value == 1:
                name = name.rstrip('s')
            result.append(f"{int(value)} {name}")
    return ', '.join(result[:granularity])


def get_system_info():
    c = cpuinfo.get_cpu_info()
    return SystemInfo(
        cpu_physical_cores=psutil.cpu_count(logical=False),
        cpu_brand=c.get('brand_raw'),
        cpu_vendor=c.get('vendor_id_raw'),
        cpu_mhz=str(int(c['hz_advertised'][0] / 1e6)),
        architecture=platform.machine(),
        system=platform.system(),
        release=platform.release(),
        platform=platform.platform()
    )


def get_top_cpu_process():
    top_name = "N/A"
    top_cmd = "N/A"
    top_cpu = 0.0

    for p in psutil.process_iter(['name', 'cmdline']):
        try:
            p.cpu_percent()
        except (psutil.NoSuchProcess, psutil.AccessDenied):
            continue

    time.sleep(0.1)

    for p in psutil.process_iter(['name', 'cmdline']):
        try:
            cpu_pct = p.cpu_percent()
            if cpu_pct > top_cpu:
                top_cpu = cpu_pct
                top_name = p.info['name']
                top_cmd = ' '.join(p.info['cmdline']) if p.info['cmdline'] else top_name
        except (psutil.NoSuchProcess, psutil.AccessDenied):
            continue

    return top_name, top_cmd, top_cpu


def get_top_memory_process():
    top_name = "N/A"
    top_cmd = "N/A"
    top_mem = 0

    for p in psutil.process_iter(['name', 'cmdline', 'memory_info']):
        try:
            mem = p.info['memory_info'].rss
            if mem > top_mem:
                top_mem = mem
                top_name = p.info['name']
                top_cmd = ' '.join(p.info['cmdline']) if p.info['cmdline'] else top_name
        except (psutil.NoSuchProcess, psutil.AccessDenied):
            continue

    return top_name, top_cmd, format_bytes(top_mem)


def collect_data() -> SystemData:
    cpu_percent = psutil.cpu_percent(interval=0.5)
    cpu_name, cpu_cmd, cpu_pct = get_top_cpu_process()
    mem_name, mem_cmd, mem_usage = get_top_memory_process()
    mem = psutil.virtual_memory()
    disk = psutil.disk_usage('/')

    return SystemData(
        uptime=to_display_time(time.time() - psutil.boot_time()),
        system_info=get_system_info(),
        cpu=CpuUtilization(
            usage_percent=cpu_percent,
            top_process_name=cpu_name,
            top_process_cmd=cpu_cmd[:100],
            top_process_cpu_percent=cpu_pct,
        ),
        memory=MemoryInfo(
            total=format_bytes(mem.total),
            available=format_bytes(mem.available),
            used=format_bytes(mem.used),
            percent=mem.percent,
            top_process_name=mem_name,
            top_process_cmd=mem_cmd[:100],
            top_process_mem=mem_usage,
        ),
        storage=StorageInfo(
            total=format_bytes(disk.total),
            used=format_bytes(disk.used),
            free=format_bytes(disk.free),
            percent=disk.percent,
        ),
        hostname=os.uname().nodename,
    )


if __name__ == "__main__":
    print(json.dumps(asdict(collect_data())))
