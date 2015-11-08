require 'net/http'
require 'yaml'

class Kongfigurator

  MAX_CONNECTION_ATTEMPTS = 120
  CONNECTION_DELAY        = 5

  def get_kong_url
    if !ENV.has_key? 'KONG_URL'
      puts 'Set KONG_URL environment variable!'
      exit 1
    end
    URI(ENV['KONG_URL'])
  end

  def get_composure
    if !ENV.has_key? 'KONG_DOCKER_CONFIG'
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
    composure.each do |service_name, service_config|
      if !service_config.has_key?('labels') || !service_config['labels'].has_key?('kong')
        next
      end

      puts "Container #{service_name} is Kong enabled"
      service_config['labels']['kong'].each do |registration_data|
        form_data = {
          'upstream_url' => registration_data['upstream_url'],
          'request_path' => registration_data.has_key?('version') ? "/#{registration_data['version']}/#{service_name}" : "/#{service_name}",
          'name' => service_name
        }

        if registration_data.has_key? 'strip_request_path'
          form_data['strip_request_path'] = konfig['strip_request_path']
        end

        result = Net::HTTP.post_form(kong_url, form_data)
        puts "\tRegistering #{service_name} with url #{form_data['upstream_url']} got return code #{result}"
      end
    end
  end

  def main
    kong_url = get_kong_url
    puts "Read Kong URL #{kong_url}"

    composure = get_composure

    check_kong_reachable(kong_url)

    register_apis(kong_url, composure)
  end
end
