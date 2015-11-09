require 'net/http'
require 'yaml'

class Kongfigurator

  MAX_CONNECTION_ATTEMPTS = 120
  CONNECTION_DELAY        = 5

  def get_kong_url
    if ENV['KONG_URL'] == nil
      puts 'Set KONG_URL environment variable!'
      exit 1
    end
    URI(ENV['KONG_URL'])
  end

  def get_composure
    if ENV['KONG_DOCKER_CONFIG'] == nil
      puts 'Set KONG_DOCKER_CONFIG environment variable!'
      exit 2
    end

    config = ENV['KONG_DOCKER_CONFIG']
    if !File.exist? config
      puts "Failed to find docker config #{config}"
      exit 3
    end
    YAML.load(File.new(config))
  end

  def check_kong_reachable(kong_url)
    attempts = 0
    #Up to 10 minutes of attempts before failing
    while attempts < MAX_CONNECTION_ATTEMPTS do
      puts "Trying to reach Kong..."
      begin
        if Net::HTTP.get_response(kong_url).is_a? Net::HTTPSuccess
          break
        end
      rescue StandardError
        puts "Caught exception when trying to reach Kong, retrying"
      end
      attempts += 1
      sleep(CONNECTION_DELAY)
    end

    if attempts >= MAX_CONNECTION_ATTEMPTS
      puts "Failed to connect to Kong after #{MAX_CONNECTION_ATTEMPTS} attempts"
      exit 4
    end
  end

  def register_apis(kong_url, composure)
    composure.select { |_, service_config|
      service_config.has_key?('labels') && service_config['labels'].has_key?('kong_upstream_url') && service_config['labels'].has_key?('kong_request_path')
    }.each do |service_name, service_config|
      service_name = service_config['container_name'] || service_name
      label_config = service_config['labels']

      puts "Container #{service_name} is Kong enabled"
      form_data = {
        'upstream_url' => label_config['kong_upstream_url'],
        'request_path' => label_config['kong_request_path'],
        'name' => service_name
      }

      if label_config.has_key? 'kong_strip_request_path'
        form_data['strip_request_path'] = label_config['kong_strip_request_path']
      end

      result = Net::HTTP.post_form(kong_url, form_data)
      puts "\tRegistering #{service_name} with url #{form_data['upstream_url']} got return code #{result}"
    end
  end

  def main
    kong_url = get_kong_url
    puts "Read Kong URL #{kong_url}"

    composure = get_composure
    puts "Read docker compose file"

    check_kong_reachable(kong_url)

    register_apis(kong_url, composure)
  end
end
