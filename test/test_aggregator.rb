require "minitest_helper"
require "stringio"

class TestAggregator < Minitest::Test

  class EventAggregator < Aggregator
    attr_reader :process_counter, :finish_counter

    self.max_wait_time = 2
    self.max_batch_size = 25
    self.logger = Logger.new(StringIO.new)

    def reset_counters
      @process_counter = 0
      @finish_counter = 0
    end

    def process(collection, item)
      fail if item.nil?
      collection ||= []
      collection << item
      collection
    end

    def finish(collection)
      @process_counter ||= 0
      @process_counter += collection.count

      @finish_counter ||= 0
      @finish_counter += 1
    end
  end

  def setup
    EventAggregator.instance.reset_counters
    EventAggregator.instance.instance_variable_get(:@queue).clear
  end

  def test_it_processes_pushed_items
    100.times { EventAggregator.push({}) }
    EventAggregator.drain
    assert_equal 100, EventAggregator.instance.process_counter
  end

  def test_it_processes_in_batches
    100.times { EventAggregator.push({}) }
    EventAggregator.drain
    assert_equal 4, EventAggregator.instance.finish_counter
  end

  def test_it_can_drain_multiple_times
    100.times do
      EventAggregator.instance.reset_counters
      90.times { EventAggregator.push({}) }
      EventAggregator.drain
      assert_equal 90, EventAggregator.instance.process_counter
    end
  end

  def test_it_can_recover_from_a_thread_crash
    100.times do |i|
      item = (i == 35) ? nil : {}
      EventAggregator.push(item)
    end

    EventAggregator.drain
    EventAggregator.push({})
    EventAggregator.drain

    assert_equal 100, EventAggregator.instance.process_counter
  end

  def test_it_drains_the_queue_even_if_the_thread_was_not_running
    EventAggregator.instance.instance_variable_get(:@queue).push({})
    EventAggregator.drain
    assert_equal 1, EventAggregator.instance.process_counter
  end

end
