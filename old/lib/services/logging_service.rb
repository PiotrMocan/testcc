require 'logger'
require 'fileutils'

class LoggingService
  LOGS_DIR = 'logs'
  LOG_FILE = File.join(LOGS_DIR, 'library_system.log')

  def initialize
    ensure_logs_directory_exists
    @logger = Logger.new(LOG_FILE, 'daily')
    @logger.level = Logger::INFO
    @logger.formatter = proc do |severity, datetime, progname, msg|
      "[#{datetime.strftime('%Y-%m-%d %H:%M:%S')}] #{severity}: #{msg}\n"
    end
  end

  def info(message)
    @logger.info(message)
  end

  def warn(message)
    @logger.warn(message)
  end

  def error(message)
    @logger.error(message)
  end

  def debug(message)
    @logger.debug(message)
  end

  def log_operation(operation, details = {})
    message = "#{operation}"
    unless details.empty?
      details_str = details.map { |k, v| "#{k}: #{v}" }.join(', ')
      message += " - #{details_str}"
    end
    info(message)
  end

  def log_error(operation, error)
    error_message = "#{operation} failed - Error: #{error.message}"
    error(error_message)
  end

  private

  def ensure_logs_directory_exists
    FileUtils.mkdir_p(LOGS_DIR) unless Dir.exist?(LOGS_DIR)
  end
end