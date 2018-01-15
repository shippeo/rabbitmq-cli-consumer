RabbitMQ cli consumer
---------------------

This repository is forked from [rabbitmq-cli-consumer](https://github.com/ricbra/rabbitmq-cli-consumer) a work done
by [Richard van den Brand](https://github.com/ricbra), an official fork exist [here](https://github.com/corvus-ch/rabbitmq-cli-consumer).

If you are a fellow PHP developer just like me you're probably aware of the following fact:
PHP really SUCKS in long running tasks.

When using RabbitMQ with pure PHP consumers you have to deal with stability issues. Probably you are killing your
consumers regularly just like me. And try to solve the problem with supervisord. Which also means on every deploy you
have to restart your consumers. A little bit dramatic if you ask me.

This library aims at PHP developers solving the above described problem with RabbitMQ. Why don't let the polling over to
a language as Go which is much better suited to run long running tasks.

# Installation

You have the choice to either compile yourself or using docker.

## Binary

Binaries can be found at: not implemented yet !

## Compiling with docker

This section assume you have docker and docker-compose installed.

Build your docker image :

``` bash
$ docker-compose build
```

Compile :

```bash
$ docker-compose run consumer go build -tags netgo
```


## Compiling

This section assumes you're familiar with the Go language.

Use <code>go get</code> to get the source local:

```bash
$ go get github.com/shippeo/rabbitmq-cli-consumer
```

Change to the directory, e.g.:

```bash
$ cd $GOPATH/src/github.com/shippeo/rabbitmq-cli-consumer
```

Get the dependencies:

```bash
$ go get ./...
```

Then build and/or install:

```bash
$ go build
$ go install
```

# Usage

Run without arguments or with <code>--help</code> switch to show the helptext:

    $ rabbitmq-cli-consumer
    NAME:
       rabbitmq-cli-consumer - Consume RabbitMQ easily to any cli program

    USAGE:
       rabbitmq-cli-consumer [global options] command [command options] [arguments...]

    VERSION:
       0.0.1

    AUTHOR:
      Richard van den Brand - <richard@vandenbrand.org>

    COMMANDS:
       help, h	Shows a list of commands or help for one command

    GLOBAL OPTIONS:
       --executable, -e 	Location of executable
       --configuration, -c 	Location of configuration file
       --verbose, -V	Enable verbose mode (logs to stdout and stderr)
       --include, -i	Include metadata. Passes message as JSON data including headers, properties and message body.
       --help, -h		show help
       --version, -v	print the version

## Configuration

A configuration file is required. Example:

```ini
[rabbitmq]
host = localhost
username = username-of-rabbitmq-user
password = secret
vhost=/your-vhost
port=5672
queue=name-of-queue
compression=Off

[logs]
error = /location/to/error.log
info = /location/to/info.log
```

When you've created the configuration you can start the consumer like this:

    $ rabbitmq-cli-consumer -e "/path/to/your/app argument --flag" -c /path/to/your/configuration.conf -V

Run without <code>-V</code> to get rid of the output:

    $ rabbitmq-cli-consumer -e "/path/to/your/app argument --flag" -c /path/to/your/configuration.conf

### Prefetch count

It's possible to configure the prefetch count and if you want set it as global. Add the following section to your
configuration to confol these values:

```ini
[prefetch]
count=3
global=Off
```

### Configuring the exchange

It's also possible to configure the exchange and its options. When left out in the configuration file, the default
exchange will be used. To configure the exchange add the following to your configuration file:

```ini
[exchange]
name=mail
autodelete=Off
type=direct
durable=On
```

### How to configure an empty string value

In Go the zero value for a string is `""`. So, any values not configured in the config file will result in a
empty string. Now imagine you want to define an empty name for one of the configuration settings. Yes, we now
cannot determine whether this value was empty on purpose or just left out. If you want to configure an empty string
you have to be explicit by using the value `<empty>`.

## The executable

Your executable receives the message as the last argument. So consider the following:

   $ rabbitmq-cli-consumer -e "/home/vagrant/current/app/command.php" -c example.conf -V

The <code>command.php</code> file should look like this:

```php
#!/usr/bin/env php
<?php
// This contains first argument
$message = $argv[1];

// Decode to get original value
$original = base64_decode($message);

// Start processing
if (do_heavy_lifting($original)) {
    // All well, then return 0
    exit(0);
}

// Let rabbitmq-cli-consumer know someting went wrong, message will be requeued.
exit(1);

```

Or a Symfony2 example:

    $ rabbitmq-cli-consumer -e "/path/to/symfony/app/console event:processing -e=prod" -c example.conf -V

Command looks like this:

```php
<?php

namespace Vendor\EventBundle\Command;

use Symfony\Bundle\FrameworkBundle\Command\ContainerAwareCommand;
use Symfony\Component\Console\Input\InputArgument;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;

class TestCommand extends ContainerAwareCommand
{
    protected function configure()
    {
        $this
            ->addArgument('event', InputArgument::REQUIRED)
            ->setName('event:processing')
        ;

    }

    protected function execute(InputInterface $input, OutputInterface $output)
    {
        $message = base64_decode($input->getArgument('event'));

        $this->getContainer()->get('mailer')->send($message);

        exit(0);
    }
}
```

## Compression

Depending on what you're passing around on the queue, it may be wise to enable compression support. If you don't you may
encouter the infamous "Argument list too long" error.

When compression is enabled, the message gets compressed with zlib maximum compression before it's base64 encoded. We
have to pay a performance penalty for this. If you are serializing large php objects I suggest to turn it on. Better
safe then sorry.

In your config:

```ini
[rabbitmq]
host = localhost
username = username-of-rabbitmq-user
password = secret
vhost=/your-vhost
port=5672
queue=name-of-queue
compression=On

[logs]
error = /location/to/error.log
info = /location/to/info.log
```

And in your php app:

```php
#!/usr/bin/env php
<?php
// This contains first argument
$message = $argv[1];

// Decode to get compressed value
$original = base64_decode($message);

// Uncompresss
if (! $original = gzuncompress($original)) {
    // Probably wanna throw some exception here
    exit(1);
}

// Start processing
if (do_heavy_lifting($original)) {
    // All well, then return 0
    exit(0);
}

// Let rabbitmq-cli-consumer know someting went wrong, message will be requeued.
exit(1);

```

## Including properties and message headers


If you need to access message headers or properties, call the command with the
`--include, -i` option set.

    $ rabbitmq-cli-consumer -e "/home/vagrant/current/app/command.php" -c example.conf -i

The script then will receive a json encoded data structure which looks like
the following.

```json
{
  "properties": {
    "application_headers": {
      "name": "value"
    },
    "content_type": "",
    "content_encoding": "",
    "delivery_mode": 1,
    "priority": 0,
    "correlation_id": "",
    "reply_to": "",
    "expiration": "",
    "message_id": "",
    "timestamp": "0001-01-01T00:00:00Z",
    "type": "",
    "user_id": "",
    "app_id": ""
  },
  "delivery_info": {
    "message_count": 0,
    "consumer_tag": "ctag-./rabbitmq-cli-consumer-1",
    "delivery_tag": 2,
    "redelivered": true,
    "exchange": "example",
    "routing_key": ""
  },
  "body": ""
}

```

Change your script acording to the following example.

```php
#!/usr/bin/env php
<?php
// This contains first argument
$input = $argv[1];

// Decode to get original value also decrompress acording to your configuration.
$data = json_decode(base64_decode($input));

// Start processing
if (do_heavy_lifting($data->body, $data->properties)) {
    // All well, then return 0
    exit(0);
}

// Let rabbitmq-cli-consumer know someting went wrong, message will be requeued.
exit(1);
```

If you are using symfonies RabbitMQ bundle (`oldsound/rabbitmq-bundle`) you can
wrap the consumer with the following symfony command.

```php
<?php

namespace Vendor\EventBundle\Command;

use PhpAmqpLib\Message\AMQPMessage;
use Symfony\Bundle\FrameworkBundle\Command\ContainerAwareCommand;
use Symfony\Component\Console\Input\InputArgument;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;

class TestCommand extends ContainerAwareCommand
{
    protected function configure()
    {
        $this
            ->addArgument('event', InputArgument::REQUIRED)
            ->setName('event:processing')
        ;

    }

    protected function execute(InputInterface $input, OutputInterface $output)
    {
        $data = json_decode(base64_decode($input->getArgument('event')), true);
        $message = new AMQPMessage($data['body'], $data['properties']);

        /** @var \PhpAmqpLib\Message\AMQPMessage\ConsumerInterface $consumer */
        $consumer = $this->getContainer()->get('consumer');

        if (false == $consumer->execute($message)) {
            exit(1);
        }
    }
}
```

# Strict exit code processing

By default, any non-zero exit code will make consumer send a negative acknowledgement and re-queue message back to the queue, in some cases it may cause your consumer to fall into an infinite loop as re-queued message will be getting back to consumer and it probably will fail again.

It's possible to get better control over message acknowledgement by setting up strict exit code processing. In this mode consumer will acknowledge messages only if executable process return an allowed exit code.

**Allowed exit codes**

| Exit Code | Action                                |
|:---------:|---------------------------------------|
| 0         | Acknowledgement                       |
| 3         | Reject                                |
| 4         | Reject and re-queue                   |
| 5         | Negative acknowledgement              |
| 6         | Negative acknowledgement and re-queue |

All other exit codes will cause consumer to fail.

Run consumer with `--strict-exit-code` option to enable strict exit code processing:

    $ rabbitmq-cli-consumer -e "/path/to/your/app argument --flag" -c /path/to/your/configuration.conf --strict-exit-code

Make sure your executable returns correct exit code

```php
#!/usr/bin/env php
<?php
// ...
try {
    if (do_heavy_lifting($data)) {
        // All well, then return 0
        exit(0);
    }
} catch(InvalidMessageBody $e) {
    exit(3); // Message is invalid, just reject and don't try to process again
} catch(TimeoutException $e) {
    exit(4); // Reject and try again
} catch(Exception $e) {
    exit(1); // Unexpected exception will cause consumer to stop consuming
}
```

# Developing

Missing anything? Found a bug? I love to see your PR.
