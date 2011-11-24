class MemMySQL::Server
  # == Constants ============================================================
  
  COMMANDS = {
    :mysqld => %w[ mysqld mysqld5 ].freeze,
    :mysql_install_db => %w[ mysql_install_db mysql_install_db5 ].freeze
  }.freeze
  
  ADDITIONAL_PATHS = %w[ /opt/local/libexec ].freeze

  # == Class Methods ========================================================
  
  def self.command_path(command)
    list = COMMANDS[command]
    
    (ENV['PATH'].split(/:/) + ADDITIONAL_PATHS).each do |path|
      list.each do |command|
        command_path = File.expand_path(command, path)
        
        if (File.exist?(command_path))
          return command_path
        end
      end
    end
    
    nil
  end

  # == Instance Methods =====================================================

  def initialize(options)
    @options = options
    
    @ramdisk = MemMySQL::Ramdisk.new(options)
  end
  
  def path
    @ramdisk.path
  end
  
  def config_path
    @config_path ||= File.expand_path('my.cnf', self.path)
  end
  
  def socket_path
    @socket_path ||= File.expand_path('mysqld.sock', self.path)
  end

  def pid_path
    @pid_path ||= File.expand_path('mysqld.pid', self.path)
  end

  def error_log_path
    @error_log ||= File.expand_path('mysqld.err', self.path)
  end

  def start!
    @ramdisk.create!
    
    self.configure!

    system(
      self.class.command_path(:mysql_install_db),
      "--datadir=" + self.path,
      "--skip-name-resolve"
    )
    
    fork do
      exec(
        self.class.command_path(:mysqld),
        "--defaults-file=" + self.config_path,
        "--datadir=" + self.path,
        "--socket=" + self.socket_path,
        "--log-error=" + self.error_log_path,
        "--pid-file=" + self.pid_path,
        "--port=" + @options[:port].to_s,
        "--skip-grant-tables"
      )
    end
  end
  
  def stop!
    pid = File.read(self.pid_path).to_i
    
    puts "Killing process #{pid}"
    
    Process.kill('KILL', pid)
  end
  
  def status
  end
  
protected
  def configure!
    puts "Mounted on #{self.path}"

    File.open(self.config_path, 'w') do |f|
      f.puts <<END
[mysqld]
datadir=#{self.path}
socket=#{self.socket_path}
server-id=1
sync_binlog=1

max_allowed_packet=1G

character_set_server=utf8
collation_server=utf8_general_ci

innodb_flush_log_at_trx_commit=1
innodb_support_xa=1
innodb_buffer_pool_size=512M
innodb_log_buffer_size=16M
innodb_flush_log_at_trx_commit=2
innodb_additional_mem_pool_size=64M
innodb_file_per_table

default-storage-engine=InnoDB

[mysqld_safe]
port=#{@options[:port]}
log-error=#{self.error_log_path}
pid-file=#{self.pid_path}
END
    end
  end
end
