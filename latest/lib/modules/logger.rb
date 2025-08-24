require 'time'
require 'fileutils'

module LibraryLogger
  LOG_FILE = 'logs/library.log'.freeze

  def self.log(level, message, context = {})
    ensure_log_directory
    
    timestamp = Time.now.strftime('%Y-%m-%d %H:%M:%S')
    log_entry = format_log_entry(timestamp, level, message, context)
    
    File.open(LOG_FILE, 'a') do |file|
      file.puts(log_entry)
    end
  rescue => e
    Kernel.warn "Failed to write to log file: #{e.message}"
  end

  def self.info(message, context = {})
    log('INFO', message, context)
  end

  def self.warn(message, context = {})
    log('WARN', message, context)
  end

  def self.error(message, context = {})
    log('ERROR', message, context)
  end

  def self.debug(message, context = {})
    log('DEBUG', message, context)
  end

  private

  def self.ensure_log_directory
    log_dir = File.dirname(LOG_FILE)
    FileUtils.mkdir_p(log_dir) unless Dir.exist?(log_dir)
  end

  def self.format_log_entry(timestamp, level, message, context)
    base_entry = "[#{timestamp}] #{level}: #{message}"
    
    if context.any?
      context_string = context.map { |k, v| "#{k}=#{v}" }.join(' ')
      "#{base_entry} | #{context_string}"
    else
      base_entry
    end
  end
end