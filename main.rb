require 'net/http'
require 'yaml'

def get_kong_url
  if !ENV.has_key? 'KONG_URL'
    puts 'Set KONG_URL environment variable!'
    exit 1
  end
  URI(ENV['KONG_URL'])
end

def get_composure
  composure_file = File.new('docker-compose.yml')
  if composure_file.nil?
    puts 'Add docker-compose.yml'
    exit 2
  end
  YAML.load(composure_file)
end

def check_kong_reachable(kong_url)
  while true do
    puts "Trying to reach Kong..."
    begin
      if Net::HTTP.get_response(kong_url).is_a?(Net::HTTPSuccess)
        break
      end
    rescue StandardError
      puts "Caught exception when trying to reach Kong, retrying"
    end
    sleep(5)
  end
end

def register_apis(kong_url, composure)
  composure.each do |container|
    if !container[1].has_key? 'labels'
      next
    end
    if !container[1]['labels']['kong_register'] == 'true'
      puts "Container #{container[0]} has kong registration falsey"
      next
    end

    puts "Container #{container[0]} is Kong enabled"
    konfig = container[1]['labels'].reject {|key, value| !key.start_with? 'kong_'}

    form_data = {
      'upstream_url' => konfig['kong_upstream_url'],
      'request_path' => konfig.has_key?('kong_version') ? "/#{konfig['kong_version']}/#{container[0]}" : "/#{container[0]}",
      'name' => container[0]
    }
    if konfig.has_key? 'kong_strip_request_path'
      form_data['strip_request_path'] = konfig['kong_strip_request_path']
    end

    puts "\tSending registration data #{form_data}"
    result = Net::HTTP.post_form(kong_url, form_data)
    puts "\tRegistering #{container[0]} got return code #{result}"
  end
end

kong_url = get_kong_url
puts "Read Kong URL #{kong_url}"

composure = get_composure

check_kong_reachable(kong_url)

register_apis(kong_url, composure)
