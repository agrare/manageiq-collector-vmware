require 'manageiq/providers/vmware/active_mq_client'

class ManageIQ::Providers::Vmware::MiqQueue
  # options:
  #   :message
  #   :sender (optional)
  #   :message_type (optional)
  #   :service
  #   :resource (optional)
  #   :other keys same as put_background_job
  def self.put_job(client = nil, options)
    assert_options(options, [:message, :service])

    options = options.dup
    address, headers = queue_for_publish(options)
    headers[:sender] = options.delete(:sender) if options[:sender]
    headers[:message_type] = options.delete(:message_type) if options[:message_type]

    unless client
      client = ManageIQ::Providers::Vmware::ActiveMqClient.open
      close_on_exit = true
    end
    client.publish(address, options[:message].to_yaml, headers)
    #pp("Address(#{address}), msg(#{options[:message].inspect}), headers(#{headers.inspect})")
    client.close if close_on_exit
  end

  def self.queue_for_publish(options)
    resource = options.delete(:resource) || 'none'
    address = "queue/#{options.delete(:service)}.#{resource}"

    headers = {:"destination-type" => "ANYCAST"}
    headers[:expires] = options.delete(:expires_on).to_i * 1000 if options[:expires_on]
    headers[:AMQ_SCHEDULED_TIME] = options.delete(:deliver_on).to_i * 1000 if options[:deliver_on]
    headers[:priority] = options.delete(:priority) if options[:priority]

    [address, headers]
  end
  private_class_method :queue_for_publish

  def self.assert_options(options, keys)
    keys.each do |key|
      raise "options must contains key #{key}" if options[key].nil?
    end
  end
  private_class_method :assert_options

end
