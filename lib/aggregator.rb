require "thread"
require "singleton"
require "logger"

class Aggregator
  include Singleton

  attr_accessor :max_batch_size, :max_wait_time, :logger

  def self.push(data)
    self.instance.push(data)
  end

  def self.max_batch_size=(value)
    self.instance.max_batch_size = value
  end

  def self.max_wait_time=(value)
    self.instance.max_wait_time = value
  end

  def self.logger=(logger)
    self.instance.logger = logger
  end

  def self.drain
    self.instance.drain
  end

  def initialize
    @queue = Queue.new
    @mutex = Mutex.new
    @thread = nil

    at_exit { stop }
  end

  def push(data)
    @queue.push(data)
    start unless running?
  end

  def drain
    if running?
      if ! @queue.empty?
        log :info, "joining thread #{@thread.inspect} (queue length = #{@queue.length})"
        @drain = true
        @thread.join if running?
      end

      log :info, "stopping thread #{@thread.inspect} (queue length = #{@queue.length})"
      @thread = nil
    elsif ! @queue.empty?
      start and drain
    end

    true
  end

  private

  def max_batch_size
    @max_batch_size || 1000
  end

  def max_wait_time
    @max_wait_time || 1
  end

  def process(collection, item)
    raise NoMethodError,
      "#{self.class.name}#process(collection, item) must be implemented"
  end

  def finish(collection)
    raise NoMethodError,
      "#{self.class.name}#finish(collection) must be implemented"
  end

  def running?
    @thread && @thread.alive?
  end

  def logger
    @logger ||= Logger.new(STDOUT)
  end

  def log(level, message)
    logger.send(level, "[#{self.class.name}] #{message}")
  end

  def process_queue
    raise StopIteration if @queue.empty? && @drain

    processed_items = 0
    start_time = Time.now

    while processed_items < max_batch_size && (Time.now - start_time) < max_wait_time
      raise StopIteration if @queue.empty? && @drain
      if @queue.empty?
        sleep 0.1
      else
        collection = process(collection, @queue.pop(true))
        processed_items += 1
      end
    end
  ensure
    finish(collection) if collection
  end

  def start
    @mutex.synchronize do
      return false if running?

      @drain = false

      @thread = Thread.new do
        begin
          log :info, "starting thread #{Thread.current}"

          loop do
            process_queue
          end
        rescue Exception => e
          log :warn, "thread crashed with exception: #{e.inspect}"
        end
      end

      @thread.priority = 2

      @thread
    end
  end

  def stop
    if running?
      drain
    else
      log :info, "thread not running - nothing to stop"
      return false
    end
  end

end
