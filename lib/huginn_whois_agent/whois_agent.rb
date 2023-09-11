require 'whois-parser'

module Agents
  class WhoisAgent < Agent
    include FormConfigurable
    can_dry_run!
    default_schedule 'every_1h'

    description do
      <<-MD
      The Whois Agent is used to check a domain's status.

      `type` can be registered / available

      `domain` is the checked domain.

      `debug` is used to verbose mode.

      `timeout` is the timeout limit, the client raises a Timeout::Error exception.

      `expected_receive_period_in_days` is used to determine if the Agent is working. Set it to the maximum number of days
      that you anticipate passing without this Agent receiving an incoming Event.
      MD
    end

    event_description <<-MD
      Events look like this:

          {
            "domain": "google.com",
            "registered": "true"
          }
    MD

    def default_options
      {
        'debug' => 'false',
        'expected_receive_period_in_days' => '2',
        'domain' => '',
        'timeout' => '5',
        'type' => 'registered',
        'changes_only' => 'true'
      }
    end

    form_configurable :expected_receive_period_in_days, type: :string
    form_configurable :domain, type: :string
    form_configurable :timeout, type: :number
    form_configurable :changes_only, type: :boolean
    form_configurable :debug, type: :boolean
    form_configurable :type, type: :array, values: ['registered', 'available']
    def validate_options
      errors.add(:base, "type has invalid value: should be 'registered' 'available'") if interpolated['type'].present? && !%w(registered available).include?(interpolated['type'])

      if options.has_key?('changes_only') && boolify(options['changes_only']).nil?
        errors.add(:base, "if provided, changes_only must be true or false")
      end

      unless options['domain'].present?
        errors.add(:base, "domain is a required field")
      end

      unless options['timeout'].present?
        errors.add(:base, "timeout is a required field")
      end

      if options.has_key?('debug') && boolify(options['debug']).nil?
        errors.add(:base, "if provided, debug must be true or false")
      end

      unless options['expected_receive_period_in_days'].present? && options['expected_receive_period_in_days'].to_i > 0
        errors.add(:base, "Please provide 'expected_receive_period_in_days' to indicate how many days can pass before this Agent is considered to be not working")
      end
    end

    def working?
      event_created_within?(options['expected_receive_period_in_days']) && !recent_error_logs?
    end

    def check
      trigger_action
    end

    private

    def whois_check()
      whois = Whois::Client.new(:timeout => interpolated['timeout'].to_i)
      record = whois.lookup(interpolated['domain'])
      parser = record.parser

      if interpolated['debug'] == 'true'
        log "parser :"
        log parser.inspect()
      end

      return parser
    end

    def is_registered()

      parser =  whois_check()
      if interpolated['debug'] == 'true'
        log "registered is #{parser.registered?}"
      end
      if interpolated['changes_only'] == 'true'
        if parser.registered? != memory['is_registered']
          create_event :payload => { 'domain' => "#{interpolated['domain']}", 'registered' => "#{parser.registered?}" }
          memory['is_registered'] = parser.registered?
        end
      else
        create_event :payload => { 'domain' => "#{interpolated['domain']}", 'registered' => "#{parser.registered?}" }
        if parser.registered? != memory['is_registered']
          memory['is_registered'] = parser.registered?
        end
      end
    end

    def is_available()

      parser =  whois_check()
      if interpolated['debug'] == 'true'
        log "available is #{parser.available?}"
      end

      if interpolated['changes_only'] == 'true'
        if parser.available? != memory['is_available']
          create_event :payload => { 'domain' => "#{interpolated['domain']}", 'available' => "#{parser.available?}" }
          memory['is_available'] = parser.available?
        end
      else
        create_event :payload => { 'domain' => "#{interpolated['domain']}", 'available' => "#{parser.available?}" }
        if parser.available? != memory['is_available']
          memory['is_available'] = parser.available?
        end
      end
    end

    def trigger_action

      case interpolated['type']
      when "registered"
        is_registered()
      when "available"
        is_available()
      else
        log "Error: type has an invalid value (#{type})"
      end
    end
  end
end
