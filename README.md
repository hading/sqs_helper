[![Build Status](https://travis-ci.org/medusa-project/sqs_helper.svg?branch=master)](https://travis-ci.org/medusa-project/sqs_helper)

# SqsHelper

This gem is designed to ease some of the common things that we may do with AWS SQS.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'sqs_helper'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install sqs_helper

## Usage

The two classes of interest are ```SqsHelper::Connector``` and ```SqsHelper::Poller```. 

### ```SqsHelper::Connector```

This is used to do fairly low level operations. It represents a connection to a specific AWS endpoint. It handles
making the AWS SQS client and keeps tracks of queues that are used. Create with a call like the following:

```ruby
  CfsHelper::Connection.new(endpoint: 'https://sqs_endpoint_url', region: 'aws-region', aws_key_id: 'aws_key_id',
                            aws_secret_key: 'aws_secret_key')
```

All the arguments above are used to create the AWS client. In the future we may provide other ways to do this.

If you try to access a queue that doesn't exist it will be created. The connector keeps track of a map of queue names 
to queue URLs, available as ```queue_urls``. 

You can clear a queue with the ```clear_queue``` method, a number of queues with ```clear_queue(q1, q2, ...)```
or all known queues (that is, that the connector has seen) with ```clear_all_queues```. These clear the queues by taking
the messages off one by one, not purging, and are intended primarily for testing. We may provide a way to purge
in the future.

To write to a queue simply do connector.send_message(queue_name, message). If message is a Hash it will be converted to
JSON. If it is not (presumably it is a string in this case) it is passed as is.

To read from a queue we provide ```with_message(queue_name)``` and ```with_parsed_message(queue_name)```. Both 
of these take a block. They yield a message if one is available and nil if not. If a message is received it is
automatically deleted. The former yields the body of the message, the latter parses the message as JSON and
yields the parsed object.

### ```SqsHelper::Poller```

This class is used to wrap the underlying AWS SQS functionality allowing listening on a queue. To create it, you'll
need to make a connector first. Then the poller is created by:

```ruby
  SqsHelper::Poller.new(connector, queue_name, args = {})
```

The following arguments are available:

* wait_time_seconds - the number of seconds that each requests waits for an incoming message before timing out. This
  is simply the same argument as from standard SQS. It should be an integer <= 20, is set to 20 as a default,
  and is reduced to 20 if a greater number is passed.
* additional_sleep_time - we have use cases where polling every 20 seconds is excessive. This parameter is 
  a number of extra seconds that the poller sleeps after a request times out with no messages. 
* unparsed_messages - By default the message bodies will be parsed as JSON. To avoid that set this to true. 
* visibility_timeout - this is an AWS option that determines how long SQS will wait before putting the message
  back in the queue. By default it is 60 seconds. If the operation triggered by the message is potentially long
  lasting you may want to increase it. 
* logger - a ```Logger``` object may be given, in which case some logging is done. In a Rails environment
  ```Rails.logger``` will be used by default
* log_all_messages - if set true then all the incoming messages will be logged to the logger.

There are accessors for ```connector, aws_poller (the underlying Aws::SQS::QueuePoller), queue_name, received_message_count```,
as well as most or all of the above options.

The ```stop_polling``` method sets a flag that uses the underlying AWS SDK facilities to end polling when
the next request is started.

The main method to be used is ```start_polling(action_callback)```. ```action_callback``` should be a Proc or lambda
that takes the message body (parsed from JSON or raw as specified) and does whatever to it. On calling this method
the queue will start to be polled and the callback used. It is blocking, so you may want to put the call in a thread.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/hading/sqs_helper.
