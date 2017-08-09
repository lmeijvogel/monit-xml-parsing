module StatisticKey

  KEYS = {
      0 => 'load average',
      1 => 'CPU usage percent user',
      2 => 'CPU usage percent system',
      3 => 'CPU usage percent wait',
      4 => 'memory usage percent',
      5 => 'memory usage kilobyte',
      6 => 'swap usage percent',
      7 => 'swap usage kilobyte',
      8 => 'process CPU usage percent',
      9 => 'process CPU usage percent total',
      10 => 'process memory usage percent',
      11 => 'process memory usage percent total',
      12 => 'process memory usage kilobyte',
      13 => 'process memory usage kilobyte total',
      14 => 'children',
      15 => 'port response time',
      16 => 'unix socket response time',
      17 => 'ping response time',
      18 => 'space usage percent',
      19 => 'space usage megabyte',
      20 => 'space total',
      21 => 'inode usage percent',
      22 => 'inode usage count',
      23 => 'inode total',
      24 => 'program status',
      25 => 'flags',
      26 => 'mode',
      27 => 'UID',
      28 => 'GID',
      29 => 'size',
      30 => 'PID',
      31 => 'parent PID',
      32 => 'checksum',
      33 => 'timestamp',
      34 => 'uptime'
  }

  def self.name(id)
    if KEYS.include?(id)
      KEYS[id]
    else
      "Unknown"
    end
  end


end