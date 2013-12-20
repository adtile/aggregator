# Aggregator

[![Build Status](https://travis-ci.org/adtile/aggregator.png?branch=master)](https://travis-ci.org/adtile/aggregator)
[![Code Climate](https://codeclimate.com/github/adtile/aggregator.png)](https://codeclimate.com/github/adtile/aggregator)

Aggregator is a Ruby gem that allows you to easily run aggregation work on a separate thread so that you can save yourself from doing too many expensive operations when you can do a batch operation less frequently.

## Installation

    $ gem install aggregator

Or add it to your Gemfile.

## Usage

Let's create a sample aggregator for a Rails application to keep track of pageviews:

``` ruby
class PageviewAggregator < Aggregator
  def process(collection, item)
    collection ||= {}
    collection[item] = collection.fetch(item, 0) + 1
    collection
	end

  def finish(collection)
    # Update the database based on your aggregated data:
    # { "/" => 471, "/about" => 127, ... }
  end
end
```

Then, in a Rails controller action you could push the current page path:

``` ruby
PageviewAggregator.push(request.path)
```

That's it! Let's go through what happens in more detail.

Every time a new item is pushed, the `#perform` method is called. For each new batch, `collection` will be `nil` and it is your responsibility to manage it. This way it can be any object you want (Hash, Array, etc.). You must also always return the collection object from this method. Since this method is called for each pushed item, you'll want to keep it fast.

Whenever a batch is ready, `#finish` is called and the final collection is passed. In here you can do whatever you want with it. Most likely you'll be doing something like saving it to a database.

A batch is considered ready whenever the one of two things happens:

- A configured number of items has been processed.
- A configured amount of time has passed since the batch started.

See the configuration options below to see how to set these values.

### Configuration options

Configuration options are defined for each `Aggregator` subclass and are class methods that must be explicitly called on `self`:

class MyAggregator < Aggregator
  self.option_name = <value>
end

The available options are:

- `.max_batch_size=`: maximum number of items to process before a batch is considered ready and `#finish` is called. Defaults to 1000.

- `.max_wait_time=`: maximum number of seconds given to the batch to process before it's considered ready. Defaults to 1.

- `.logger=`: logger to use. In a Rails application you probably want to set it to `Rails.logger`. Defaults to `Logger.new(STDOUT)`.

### Testing

When you're writing tests for your application, you might need to wait until the aggregations run before you can assert something. In that case, you can just call `.drain` on your Aggregator subclass, which will block until all items have been processed and finished:

``` ruby
it "saves all aggregations to the database" do
	5.times { get "/page" }
  PageviewAggregator.drain
	pageviews = Pageview.find("/page").total
	expect(pageviews).to eq(5)
end
```

## Guarantees and gotchas

All background threads are handled for you and can recover from crashes. However, if a thread crashes due to an exception raised in the `#perform` method, that item may be lost forever. Similarly, if there is an uncaught exception in `#finish` the entire collection will be lost. It is up to you to rescue and retry based on your needs.

One and only one background thread is started for each Aggregator subclass.

When the process exits gracefully (e.g. web server shutdown), running aggregators will finish processing all items.

## License

MIT License.

## Contributing

1. Fork it ( http://github.com/<my-github-username>/aggregator/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
