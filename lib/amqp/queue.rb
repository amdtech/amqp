# encoding: utf-8

require "amq/client/queue"

module AMQP
  # h2. What are AMQP queues?
  #
  # Queues store and forward messages to consumers. They are similar to mailboxes in SMTP.
  # Messages flow from producing applications to {Exchange exchanges} that route them
  # to queues and finally queues deliver them to consumer applications (or consumer
  # applications fetch messages as needed).
  #
  # Note that unlike some other messaging protocols/systems, messages are not delivered directly
  # to queues. They are delivered to exchanges that route messages to queues using rules
  # knows as *bindings*.
  #
  #
  # h2. Concept of bindings
  #
  # Binding is an association between a queue and an exchange.
  # Queues must be bound to at least one exchange in order to receive messages from publishers.
  # Learn more about bindings in {Exchange Exchange class documentation}.
  #
  #
  # h2. Key methods
  #
  # Key methods of Queue class are
  #
  # * {Queue#bind}
  # * {Queue#subscribe}
  # * {Queue#pop}
  # * {Queue#delete}
  # * {Queue#purge}
  # * {Queue#unbind}
  #
  #
  # h2. Queue names. Server-named queues. Predefined queues.
  #
  # Every queue has a name that identifies it. Queue names often contain several segments separated by a dot (.), similarly to how URI
  # path segments are separated by a slash (/), although it may be almost any string, with some limitations (see below).
  # Applications may pick queue names or ask broker to generate a name for them. To do so, pass *empty string* as queue name argument.
  #
  # Here is an example:
  #
  # <script src="https://gist.github.com/939596.js?file=gistfile1.rb"></script>
  #
  # If you want to declare a queue with a particular name, for example, "images.resize", pass it to Queue class constructor:
  #
  # <script src="https://gist.github.com/939600.js?file=gistfile1.rb"></script>
  #
  # Queue names starting with 'amq.' are reserved for internal use by the broker. Attempts to declare queue with a name that violates this
  # rule will result in AMQP::IncompatibleOptionsError to be thrown (when
  # queue is re-declared on the same channel object) or channel-level exception (when originally queue
  # was declared on one channel and re-declaration with different attributes happens on another channel).
  # Learn more in {file:docs/Queues.textile Queues guide} and {file:docs/ErrorHandling.textile Error Handling guide}.
  #
  #
  #
  # h2. Queue life-cycles. When use of server-named queues is optimal and when it isn't.
  #
  # To quote AMQP 0.9.1 spec, there are two common message queue life-cycles:
  #
  #  * Durable message queues that are shared by many consumers and have an independent existence: i.e. they
  #    will continue to exist and collect messages whether or not there are consumers to receive them.
  #  * Temporary message queues that are private to one consumer and are tied to that consumer. When the
  #    consumer disconnects, the message queue is deleted.
  #
  # There are some variations on these, such as shared message queues that are deleted when the last of
  # many consumers disconnects.
  #
  # One example of durable message queues is well-known services like event collectors (event loggers).
  # They are usually up whether there are services to log anything or not. Other applications know what
  # queues they use and can rely on those queues being around all the time, survive broker restarts and
  # in general be available should an application in the network need to use them. In this case,
  # explicitly named durable queues are optimal and coupling it creates between applications is not
  # an issue. Another scenario of a well-known long-lived service is distributed metadata/directory/locking server
  # like Apache Zookeeper, Google's Chubby or DNS. Services like this benefit from using well-known, not generated
  # queue names, and so do other applications that use them.
  #
  # Different scenario is in "a cloud settings" when some kind of workers/instances may come online and
  # go down basically any time and other applications cannot rely on them being available. Using well-known
  # queue names in this case is possible but server-generated, short-lived queues that are bound to
  # topic or fanout exchanges to receive relevant messages is a better idea.
  #
  # Imagine a service that processes an endless stream of events (Twitter is one example). When traffic goes
  # up, development operations may spin up additional applications instances in the cloud to handle the load.
  # Those new instances want to subscribe to receive messages to process but the rest of the system doesn't
  # know anything about them, rely on them being online or try to address them directly: they process events
  # from a shared stream and are not different from their peers. In a case like this, there is no reason for
  # message consumers to not use queue names generated by the broker.
  #
  # In general, use of explicitly named or server-named queues depends on messaging pattern your application needs.
  # {http://www.eaipatterns.com/ Enterprise Integration Patters} discusses many messaging patterns in depth.
  # RabbitMQ FAQ also has a section on {http://www.rabbitmq.com/faq.html#scenarios use cases}.
  #
  #
  # h2. Queue durability and persistence of messages.
  #
  # Learn more in our {file:docs/Durability.textile Durability guide}.
  #
  #
  # h2. Message ordering
  #
  # RabbitMQ FAQ explains {http://www.rabbitmq.com/faq.html#message-ordering ordering of messages in AMQP queues}
  #
  #
  # h2. Error handling
  #
  # When channel-level error occurs, queues associated with that channel are reset: internal state and callbacks
  # are cleared. Recommended strategy is to open a new channel and re-declare all the entities you need.
  # Learn more in {file:docs/ErrorHandling.textile Error Handling guide}.
  #
  #
  # @note Please make sure you read {file:docs/Durability.textile Durability guide} that covers exchanges durability vs. messages
  #       persistence.
  #
  #
  # @see http://bit.ly/hw2ELX AMQP 0.9.1 specification (Section 2.1.1)
  # @see AMQP::Exchange
  class Queue < AMQ::Client::Queue

    #
    # API
    #

    # Name of this queue
    attr_reader :name
    # Options this queue object was instantiated with
    attr_accessor :opts



    # @option opts [Boolean] :passive (false)  If set, the server will not create the queue if it does not
    #                                           already exist. The client can use this to check whether the queue
    #                                           exists without modifying  the server state.
    #
    # @option opts [Boolean] :durable (false)  If set when creating a new queue, the queue will be marked as
    #                                           durable.  Durable queues remain active when a server restarts.
    #                                           Non-durable queues (transient queues) are purged if/when a
    #                                           server restarts.  Note that durable queues do not necessarily
    #                                           hold persistent messages, although it does not make sense to
    #                                           send persistent messages to a transient queue (though it is
    #                                           allowed).
    #
    # @option opts [Boolean] :exclusive (false)  Exclusive queues may only be consumed from by the current connection.
    #                                             Setting the 'exclusive' flag always implies 'auto-delete'. Only a
    #                                             single consumer is allowed to remove messages from this queue.
    #                                             The default is a shared queue. Multiple clients may consume messages
    #                                             from this queue.
    #
    # @option opts [Boolean] :auto_delete (false)   If set, the queue is deleted when all consumers have finished
    #                                               using it. Last consumer can be cancelled either explicitly or because
    #                                               its channel is closed. If there was no consumer ever on the queue, it
    #                                               won't be deleted.
    #
    # @option opts [Boolean] :nowait (true)  If set, the server will not respond to the method. The client should
    #                                        not wait for a reply method.  If the server could not complete the
    #                                        method it will raise a channel or connection exception.
    #
    #
    # @option opts [Hash] :arguments (nil)  A hash of optional arguments with the declaration. Some brokers implement
    #                                          AMQP extensions using x-prefixed declaration arguments. For example, RabbitMQ
    #                                          recognizes x-message-ttl declaration arguments that defines TTL of messages in
    #                                          the queue.
    #
    #
    # @yield [queue, declare_ok] Yields successfully declared queue instance and AMQP method (queue.declare-ok) instance. The latter is optional.
    # @yieldparam [Queue] queue Queue that is successfully declared and is ready to be used.
    # @yieldparam [AMQP::Protocol::Queue::DeclareOk] declare_ok AMQP queue.declare-ok) instance.
    #
    # @api public
    def initialize(channel, name = AMQ::Protocol::EMPTY_STRING, opts = {}, &block)
      raise ArgumentError.new("queue name must not be nil; if you want broker to generate queue name for you, pass an empty string") if name.nil?

      @channel  = channel
      name      = AMQ::Protocol::EMPTY_STRING if name.nil?
      @name     = name unless name.empty?
      @server_named = name.empty?
      @opts         = self.class.add_default_options(name, opts, block)

      raise ArgumentError.new("server-named queues (name = '') declaration with :nowait => true makes no sense. If you are not sure what that means, simply drop :nowait => true from opts.") if @server_named && @opts[:nowait]

      @bindings     = Hash.new

      # a deferrable that we use to delay operations until this queue is actually declared.
      # one reason for this is to support a case when a server-named queue is immediately bound.
      # it's crazy, but 0.7.x supports it, so... MK.
      @declaration_deferrable = AMQ::Client::EventMachineClient::Deferrable.new

      if @opts[:nowait]
        @status = :opened
        block.call(self) if block
      else
        @status = :opening
      end

      super(channel.connection, channel, name)

      shim = Proc.new do |q, declare_ok|
        @declaration_deferrable.succeed

        case block.arity
        when 1 then block.call(q)
        else
          block.call(q, declare_ok)
        end
      end

      @channel.once_open do
        if block
          self.declare(@opts[:passive], @opts[:durable], @opts[:exclusive], @opts[:auto_delete], @opts[:nowait], @opts[:arguments], &shim)
        else
          injected_callback = Proc.new { @declaration_deferrable.succeed }
          # we cannot pass :nowait as true here, AMQ::Client::Queue will (rightfully) raise an exception because
          # it has no idea about crazy edge cases we are trying to support for sake of backwards compatibility. MK.
          self.declare(@opts[:passive], @opts[:durable], @opts[:exclusive], @opts[:auto_delete], false, @opts[:arguments], &injected_callback)
        end
      end
    end

    # @return [Boolean] true if this queue is server-named
    def server_named?
      @server_named
    end # server_named?


    # This method binds a queue to an exchange. Until a queue is
    # bound it will not receive any messages. In a classic messaging
    # model, store-and-forward queues are bound to a dest exchange
    # and subscription queues are bound to a dest_wild exchange.
    #
    # A valid exchange name (or reference) must be passed as the first
    # parameter.
    # @example Binding a queue to exchange using AMQP::Exchange instance
    #
    #  ch       = AMQP::Channel.new(connection)
    #  exchange = ch.direct('backlog.events')
    #  queue    = ch.queue('', :exclusive => true)
    #  queue.bind(exchange)
    #
    #
    # @example Binding a queue to exchange using exchange name
    #
    #  ch       = AMQP::Channel.new(connection)
    #  queue    = ch.queue('', :exclusive => true)
    #  queue.bind('backlog.events')
    #
    #
    # Note that if your producer application knows consumer queue name and wants to deliver
    # a message there, direct exchange may be sufficient (in other words, if your code declares an exchange with
    # the same name as a queue and binds it to that queue, consider using the default exchange and routing key on publishing).
    #
    # @param [Exchange] Exchange to bind to. May also be a string or any object that responds to #name.
    #
    # @option opts [String] :routing_key   Specifies the routing key for the binding. The routing key is
    #                                      used for routing messages depending on the exchange configuration.
    #                                      Not all exchanges use a routing key! Refer to the specific
    #                                      exchange documentation.  If the routing key is empty and the queue
    #                                      name is empty, the routing key will be the current queue for the
    #                                      channel, which is the last declared queue.
    #
    # @option opts [Boolean] :nowait (true)  If set, the server will not respond to the method. The client should
    #                                       not wait for a reply method.  If the server could not complete the
    #                                       method it will raise a channel or connection exception.
    # @return [Queue] Self
    #
    #
    # @yield [] Since queue.bind-ok carries no attributes, no parameters are yielded to the block.
    #
    # @api public
    # @see Queue#unbind
    def bind(exchange, opts = {}, &block)
      @status             = :unbound
      # amq-client's Queue already does exchange.respond_to?(:name) ? exchange.name : exchange
      # for us
      exchange            = exchange
      @bindings[exchange] = opts

      if self.server_named?
        @channel.once_open do
          @declaration_deferrable.callback do
            super(exchange, (opts[:key] || opts[:routing_key] || AMQ::Protocol::EMPTY_STRING), (opts[:nowait] || block.nil?), opts[:arguments], &block)
          end
        end
      else
        @channel.once_open do
          super(exchange, (opts[:key] || opts[:routing_key] || AMQ::Protocol::EMPTY_STRING), (opts[:nowait] || block.nil?), opts[:arguments], &block)
        end
      end

      self
    end


    # Remove the binding between the queue and exchange. The queue will
    # not receive any more messages until it is bound to another
    # exchange.
    #
    # Due to the asynchronous nature of the protocol, it is possible for
    # "in flight" messages to be received after this call completes.
    # Those messages will be serviced by the last block used in a
    # {Queue#subscribe} or {Queue#pop} call.
    #
    # @param [Exchange] Exchange to unbind from.
    #
    # @option opts [Boolean] :nowait (true)  If set, the server will not respond to the method. The client should
    #                                       not wait for a reply method.  If the server could not complete the
    #                                       method it will raise a channel or connection exception.
    #
    #
    # @yield [] Since queue.unbind-ok carries no attributes, no parameters are yielded to the block.
    #
    # @api public
    # @see Queue#bind
    def unbind(exchange, opts = {}, &block)
      @channel.once_open do
        super(exchange, (opts[:key] || opts[:routing_key] || AMQ::Protocol::EMPTY_STRING), opts[:arguments], &block)
      end
    end


    # This method deletes a queue.  When a queue is deleted any pending
    # messages are sent to a dead-letter queue if this is defined in the
    # server configuration, and all consumers on the queue are cancelled.
    #
    # @return [NilClass] nil (for v0.7 compatibility)
    #
    # @option opts [Boolean] :if_unused (false)   If set, the server will only delete the queue if it has no
    #                                             consumers. If the queue has consumers the server does does not
    #                                             delete it but raises a channel exception instead.
    #
    # @option opts [Boolean] :if_empty (false)    If set, the server will only delete the queue if it has no
    #                                             messages. If the queue is not empty the server raises a channel
    #                                             exception.
    #
    # @option opts [Boolean] :nowait (false)  If set, the server will not respond to the method. The client should
    #                                       not wait for a reply method.  If the server could not complete the
    #                                       method it will raise a channel or connection exception.
    #
    #
    # @return [NilClass] nil (for v0.7 compatibility)
    #
    # @yield [delete_ok] Yields AMQP method (queue.delete-ok) instance.
    # @yieldparam [AMQP::Protocol::Queue::DeleteOk] delete_ok AMQP queue.delete-ok) instance. Carries number of messages that were in the queue.
    #
    # @api public
    # @see Queue#purge
    # @see Queue#unbind
    def delete(opts = {}, &block)
      @channel.once_open do
        super(opts.fetch(:if_unused, false), opts.fetch(:if_empty, false), opts.fetch(:nowait, false), &block)
      end

      # backwards compatibility
      nil
    end


    # This method removes all messages from a queue which are not awaiting acknowledgment.
    #
    # @option opts [Boolean] :nowait (false)  If set, the server will not respond to the method. The client should
    #                                        not wait for a reply method.  If the server could not complete the
    #                                        method it will raise a channel or connection exception.
    #
    # @return [NilClass] nil (for v0.7 compatibility)
    #
    #
    # @yield [purge_ok] Yields AMQP method (queue.purge-ok) instance.
    # @yieldparam [AMQP::Protocol::Queue::PurgeOk] purge_ok AMQP queue.purge-ok) instance. Carries number of messages that were purged.
    #
    # @api public
    # @see Queue#delete
    # @see Queue#unbind
    def purge(opts = {}, &block)
      @channel.once_open do
        super(opts.fetch(:nowait, false), &block)
      end

      # backwards compatibility
      nil
    end


    # This method provides a direct access to the messages in a queue
    # using a synchronous dialogue that is designed for specific types of
    # application where synchronous functionality is more important than
    # performance.
    #
    # If provided block takes one argument, it is passed message payload every time {Queue#pop} is called.
    #
    # @example Use of callback with a single argument
    #
    #  EM.run do
    #    exchange = AMQP::Channel.direct("foo queue")
    #    EM.add_periodic_timer(1) do
    #      exchange.publish("random number #{rand(1000)}")
    #    end
    #
    #    # note that #bind is never called; it is implicit because
    #    # the exchange and queue names match
    #    queue = AMQP::Channel.queue('foo queue')
    #    queue.pop { |body| puts "received payload [#{body}]" }
    #
    #    EM.add_periodic_timer(1) { queue.pop }
    #  end
    #
    # If the block takes 2 parameters, both the header and the body will
    # be passed in for processing. The header object is defined by
    # AMQP::Protocol::Header.
    #
    # @example Use of callback with two arguments
    #
    #  EM.run do
    #    exchange = AMQP::Channel.direct("foo queue")
    #    EM.add_periodic_timer(1) do
    #      exchange.publish("random number #{rand(1000)}")
    #    end
    #
    #    queue = AMQP::Channel.queue('foo queue')
    #    queue.pop do |header, body|
    #      p header
    #      puts "received payload [#{body}]"
    #    end
    #
    #    EM.add_periodic_timer(1) { queue.pop }
    #  end
    #
    # @option opts [Boolean] :ack (false)  If this field is set to false the server does not expect acknowledgments
    #                                      for messages.  That is, when a message is delivered to the client
    #                                      the server automatically and silently acknowledges it on behalf
    #                                      of the client.  This functionality increases performance but at
    #                                      the cost of reliability.  Messages can get lost if a client dies
    #                                      before it can deliver them to the application.
    #
    #
    # @return [Qeueue] Self
    #
    #
    # @yield [headers, payload] When block only takes one argument, yields payload to it. In case of two arguments, yields headers and payload.
    # @yieldparam [AMQP::Header] headers Headers (metadata) associated with this message (for example, routing key).
    # @yieldparam [String] payload Message body (content). On Ruby 1.9, you may want to check or enforce content encoding.
    #
    # @api public
    def pop(opts = {}, &block)
      if block
        # We have to maintain this multiple arities jazz
        # because older versions this gem are used in examples in at least 3
        # books published by O'Reilly :(. MK.
        shim = Proc.new { |method, headers, payload|
          case block.arity
          when 1 then
            block.call(payload)
          when 2 then
            h = Header.new(@channel, method, headers ? headers.decode_payload : nil)
            block.call(h, payload)
          else
            h = Header.new(@channel, method, headers ? headers.decode_payload : nil)
            block.call(h, payload, method.delivery_tag, method.redelivered, method.exchange, method.routing_key)
          end
        }

        @channel.once_open do
          # see AMQ::Client::Queue#get in amq-client
          self.get(!opts.fetch(:ack, false), &shim)
        end
      else
        @channel.once_open { self.get(!opts.fetch(:ack, false)) }
      end
    end


    # Subscribes to asynchronous message delivery.
    #
    # The provided block is passed a single message each time the
    # exchange matches a message to this queue.
    #
    #
    # @example Use of callback with a single argument
    #
    #  EventMachine.run do
    #    exchange = AMQP::Channel.direct("foo queue")
    #    EM.add_periodic_timer(1) do
    #      exchange.publish("random number #{rand(1000)}")
    #    end
    #
    #    queue = AMQP::Channel.queue('foo queue')
    #    queue.subscribe { |body| puts "received payload [#{body}]" }
    #  end
    #
    # If the block takes 2 parameters, both the header and the body will
    # be passed in for processing. The header object is defined by
    # AMQP::Protocol::Header.
    #
    # @example Use of callback with two arguments
    #
    #  EventMachine.run do
    #    connection = AMQP.connect(:host => '127.0.0.1')
    #    puts "Connected to AMQP broker. Running #{AMQP::VERSION} version of the gem..."
    #
    #    channel  = AMQP::Channel.new(connection)
    #    queue    = channel.queue("amqpgem.examples.hello_world", :auto_delete => true)
    #    exchange = channel.direct("amq.direct")
    #
    #    queue.bind(exchange)
    #
    #    channel.on_error do |ch, channel_close|
    #      puts channel_close.reply_text
    #      connection.close { EventMachine.stop }
    #    end
    #
    #    queue.subscribe do |metadata, payload|
    #      puts "metadata.routing_key : #{metadata.routing_key}"
    #      puts "metadata.content_type: #{metadata.content_type}"
    #      puts "metadata.priority    : #{metadata.priority}"
    #      puts "metadata.headers     : #{metadata.headers.inspect}"
    #      puts "metadata.timestamp   : #{metadata.timestamp.inspect}"
    #      puts "metadata.type        : #{metadata.type}"
    #      puts "metadata.delivery_tag: #{metadata.delivery_tag}"
    #      puts "metadata.redelivered : #{metadata.redelivered}"
    #
    #      puts "metadata.app_id      : #{metadata.app_id}"
    #      puts "metadata.exchange    : #{metadata.exchange}"
    #      puts
    #      puts "Received a message: #{payload}. Disconnecting..."
    #
    #      connection.close {
    #        EventMachine.stop { exit }
    #      }
    #    end
    #
    #    exchange.publish("Hello, world!",
    #                     :app_id      => "amqpgem.example",
    #                     :priority    => 8,
    #                     :type        => "kinda.checkin",
    #                     # headers table keys can be anything
    #                     :headers     => {
    #                       :coordinates => {
    #                         :latitude  => 59.35,
    #                         :longitude => 18.066667
    #                       },
    #                       :participants => 11,
    #                       :venue        => "Stockholm"
    #                     },
    #                     :timestamp   => Time.now.to_i)
    #  end
    #
    #
    # @option opts [Boolean ]:ack (false)   If this field is set to false the server does not expect acknowledgments
    #                                       for messages.  That is, when a message is delivered to the client
    #                                       the server automatically and silently acknowledges it on behalf
    #                                       of the client.  This functionality increases performance but at
    #                                       the cost of reliability.  Messages can get lost if a client dies
    #                                       before it can deliver them to the application.
    #
    # @option opts [Boolean] :nowait (false)  If set, the server will not respond to the method. The client should
    #                                        not wait for a reply method.  If the server could not complete the
    #                                        method it will raise a channel or connection exception.
    #
    # @option opts [#call] :confirm (nil)   If set, this proc will be called when the server confirms subscription
    #                                       to the queue with a basic.consume-ok message. Setting this option will
    #                                       automatically set :nowait => false. This is required for the server
    #                                       to send a confirmation.
    #
    # @option opts [Boolean] :exclusive (false) Request exclusive consumer access, meaning only this consumer can access the queue.
    #                                           This is useful when you want a long-lived shared queue to be temporarily accessible by just
    #                                           one application (or thread, or process). If application exclusive consumer is part of crashes
    #                                           or loses network connection to the broker, channel is closed and exclusive consumer is thus cancelled.
    #
    #
    # @yield [headers, payload] When block only takes one argument, yields payload to it. In case of two arguments, yields headers and payload.
    # @yieldparam [AMQP::Header] headers Headers (metadata) associated with this message (for example, routing key).
    # @yieldparam [String] payload Message body (content). On Ruby 1.9, you may want to check or enforce content encoding.
    #
    # @return [Queue] Self
    # @api public
    #
    # @see file:docs/Queues.textile Documentation guide on queues
    # @see #unsubscribe
    def subscribe(opts = {}, &block)
      raise Error, 'already subscribed to the queue' if @consumer_tag

      # having initial value for @consumer_tag makes a lot of obscure issues
      # go away. It is set to real value once we receive consume-ok (it is handled by
      # AMQ::Client::Queue we inherit from).
      @consumer_tag = "for now"

      opts[:nowait] = false if (@on_confirm_subscribe = opts[:confirm])

      # We have to maintain this multiple arities jazz
      # because older versions this gem are used in examples in at least 3
      # books published by O'Reilly :(. MK.
      delivery_shim = Proc.new { |method, headers, payload|
        case block.arity
        when 1 then
          block.call(payload)
        when 2 then
          h = Header.new(@channel, method, headers.decode_payload)
          block.call(h, payload)
        else
          h = Header.new(@channel, method, headers.decode_payload)
          block.call(h, payload, method.consumer_tag, method.delivery_tag, method.redelivered, method.exchange, method.routing_key)
        end
      }

      @channel.once_open do
        @consumer_tag = nil
        # consumer_tag is set by AMQ::Client::Queue once we receive consume-ok, this takes a while.
        self.consume(!opts[:ack], opts[:exclusive], (opts[:nowait] || block.nil?), opts[:no_local], nil, &opts[:confirm])
      end
      self.on_delivery(&delivery_shim)

      self
    end


    # Removes the subscription from the queue and cancels the consumer.
    # New messages will not be received by this queue instance.
    #
    # Due to the asynchronous nature of the protocol, it is possible for
    # "in flight" messages to be received after this call completes.
    # Those messages will be serviced by the last block used in a
    # {Queue#subscribe} or {Queue#pop} call.
    #
    # Additionally, if the queue was created with _autodelete_ set to
    # true, the server will delete the queue after its wait period
    # has expired unless the queue is bound to an active exchange.
    #
    # The method accepts a block which will be executed when the
    # unsubscription request is acknowledged as complete by the server.
    #
    # @option opts [Boolean] :nowait (true)  If set, the server will not respond to the method. The client should
    #                                        not wait for a reply method.  If the server could not complete the
    #                                        method it will raise a channel or connection exception.
    #
    # @yield [cancel_ok]
    # @yieldparam [AMQP::Protocol::Basic::CancelOk] cancel_ok AMQP method basic.cancel-ok. You can obtain consumer tag from it.
    #
    #
    # @api public
    def unsubscribe(opts = {}, &block)
      # @consumer_tag is nillified for us by AMQ::Client::Queue, that is,
      # our superclass. MK.
      @channel.once_open { self.cancel(opts.fetch(:nowait, true), &block) }
    end

    # Get the number of messages and active consumers (with active channel flow) on a queue.
    #
    # @example Getting number of messages and active consumers for a queue
    #
    #  AMQP::Channel.queue('name').status { |number_of_messages, number_of_active_consumers|
    #    puts number_of_messages
    #  }
    #
    # @yield [number_of_messages, number_of_active_consumers]
    # @yieldparam [Fixnum] number_of_messages Number of messages in the queue
    # @yieldparam [Fixnum] number_of_active_consumers Number of active consumers for the queue. Note that consumers can suspend activity (Channel.Flow) in which case they do not appear in this count.
    #
    # @api public
    def status(opts = {}, &block)
      raise ArgumentError, "AMQP::Queue#status does not make any sense without a block" unless block

      shim = Proc.new { |q, declare_ok| block.call(declare_ok.message_count, declare_ok.consumer_count) }

      @channel.once_open { self.declare(true, @durable, @exclusive, @auto_delete, false, nil, &shim) }
    end


    # Boolean check to see if the current queue has already subscribed
    # to messages delivery.
    #
    # Attempts to {Queue#subscribe} multiple times to the same exchange will raise an
    # Exception. Only a single block at a time can be associated with any
    # queue instance for processing incoming messages.
    #
    # @return [Boolean] true if there is a consumer tag associated with this Queue instance
    # @api public
    def subscribed?
      !!@consumer_tag
    end


    # Compatibility alias for #on_declare.
    #
    # @api public
    # @deprecated
    def callback
      @on_declare
    end




    # Don't use this method. It is a leftover from very early days and
    # it ruins the whole point of exchanges/queue separation.
    #
    # @note This method will be removed before 1.0 release
    # @deprecated
    # @api public
    def publish(data, opts = {})
      exchange.publish(data, opts.merge(:routing_key => self.name))
    end

    # Resets queue state. Useful for error handling.
    # @api plugin
    def reset
      initialize(@channel, @name, @opts)
    end


    protected

    # @private
    def self.add_default_options(name, opts, block)
      { :queue => name, :nowait => (block.nil? && !name.empty?) }.merge(opts)
    end

    private

    # Default direct exchange that we use to publish messages directly to this queue.
    # This is a leftover from very early days and will be removed before version 1.0.
    #
    # @deprecated
    def exchange
      @exchange ||= Exchange.new(@channel, :direct, AMQ::Protocol::EMPTY_STRING, :key => name)
    end
  end # Queue
end # AMQP
