import 'package:flutter_test/flutter_test.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/services/proxmox_ve_converter/proxmox_ve_backup_converter.dart';

void main() {
  test('convertPage 用各种边界数据轰炸不抛异常', () {
    // 1. 全空
    ProxmoxVEBackupConverter.convertPage(pveStatus: {});

    // 2. pveStatus 带各种类型脏数据
    ProxmoxVEBackupConverter.convertPage(pveStatus: {
      'online': 'yes',
      'cpu_usage': 'abc',
      'mem_usage': null,
      'load_avg': null,
      'cpu_temp': '45.6',
      'mem_total': 'not-a-num',
      'swap_usage': 1.5,
      'nested': {'a': 1},
      'weird': [1, 2, 3],
    });

    // 3. 容器列表元素是各种形状
    ProxmoxVEBackupConverter.convertPage(
      pveStatus: {'online': true},
      containerStatusList: [
        {'vmid': 100},
        {'name': null, 'cpu': 'x', 'uptime': '1d'},
        <String, dynamic>{},
        {'vmid': '101', 'status': 'running', 'maxmem': 0},
      ],
    );

    // 4. 备份列表带 null / 字符串数值
    ProxmoxVEBackupConverter.convertPage(
      pveStatus: {'online': true},
      backups: [
        {'filename': null, 'size_mb': null, 'timestamp': null},
        {'filename': 'a.tar.gz', 'size_mb': '12.3', 'timestamp': 1700000000},
        {'time_str': '2026-01-01', 'timestamp': '1700000000'},
      ],
    );

    // 5. dashboard / monitor 全脏数据
    ProxmoxVEBackupConverter.convertPage(
      pveStatus: {'online': true},
      dashboard: {
        'backup_stats': null,
        'available_backups': 'x',
        'status': [],
      },
      monitor: {
        'error': '',
        'uptime': '999',
        'loadavg': null,
        'memory': 'bad',
        'rootfs': <String>[],
        'storages': [
          'not-a-map',
          {'storage': null, 'used': null, 'total': 0, 'used_fraction': 'x'},
        ],
        'tasks': [
          null,
          42,
          {'desc': null, 'endtime': null, 'starttime': 'abc'},
        ],
        'rrd': [
          'str',
          {'cpu': null, 'mem': 'x', 'maxmem': null},
          {'cpu': 0.5, 'mem': 100, 'maxmem': 200, 'netin': 1, 'netout': 2},
        ],
      },
      templates: [
        {'type': null, 'size_mb': null, 'date': null},
      ],
    );

    // 6. 全部数据齐备
    ProxmoxVEBackupConverter.convertPage(
      pveStatus: {'online': true, 'hostname': 'pve', 'cpu_usage': 12.5},
      containerStatusList: [
        {'vmid': '100', 'name': 'vm', 'status': 'running', 'type': 'qemu'},
      ],
      backups: [
        {'filename': 'vzdump.tar.zst', 'size_mb': 1024.0, 'source': '本地备份'},
      ],
      backupHistory: [
        {'success': true, 'timestamp': 1700000000, 'filename': 'x'},
      ],
      restoreHistory: [
        {'success': false, 'timestamp': 1700000001, 'message': '失败原因'},
      ],
      dashboard: {
        'backup_stats': {'successful': 3, 'failed': 1},
        'restore_stats': {'successful': 0, 'failed': 0},
        'available_backups': {'total': 4, 'local': 3, 'webdav': 1},
        'status': {
          'running': false,
          'backup_activity': '空闲',
          'restore_activity': '空闲',
        },
      },
      monitor: {
        'node': 'pve',
        'uptime': 100000,
        'loadavg': [0.5, 0.4, 0.3],
        'memory': {'used': 100, 'total': 200},
        'rootfs': {'used': 50, 'total': 100},
        'storages': [
          {'storage': 'local', 'content': 'images', 'used': 1, 'total': 2, 'used_fraction': 0.5},
        ],
        'tasks': [
          {'desc': 'vzdump', 'vmid': 100, 'status': 'running', 'starttime': 1700000000},
        ],
        'rrd': List.generate(10, (i) => {'cpu': i / 100, 'mem': i * 10, 'maxmem': 1000, 'netin': i, 'netout': i * 2}),
      },
      templates: [
        {'type': 'iso', 'filename': 'debian.iso', 'size_mb': 600, 'date': '2026-01-01'},
      ],
    );
  });
}
