require 'kongfigurator'
require 'climate_control'

RSpec.describe Kongfigurator do
  describe "#get_kong_url" do
    subject { described_class.new.get_kong_url }

    around do |example|
      ClimateControl.modify KONG_URL: kong_url do
        example.call
      end
    end

    context "when no kong url is set" do
      let(:kong_url) { nil }

      it "should return an error code" do
        expect { subject }.to raise_error { |error|
          expect(error).to be_a(SystemExit)
          expect(error.status).to eq(1)
        }
      end
    end

    context "when kong url is set" do
      let(:kong_url) { 'http://example.com' }

      it "should return a new URI containing the URL" do
        expect(subject).to eq(URI(kong_url))
      end
    end
  end

  describe "#get_composure" do
    subject { described_class.new.get_composure }

    let(:composure) { 'docker-compose.yml' }

    around do |example|
      ClimateControl.modify KONG_DOCKER_CONFIG: composure do
        example.call
      end
    end

    context "when no composure url is set" do
      let(:composure) { nil }

      it "should return an error code" do
        expect { subject }.to raise_error { |error|
          expect(error).to be_a(SystemExit)
          expect(error.status).to eq(2)
        }
      end
    end

    context "when file is missing" do
      let(:file_exists) { false }

      it "should return an error code" do
        expect(File).to receive(:exist?).with(composure).and_return(file_exists)
        expect { subject }.to raise_error { |error|
          expect(error).to be_a(SystemExit)
          expect(error.status).to eq(3)
        }
      end
    end

    context "when file is found" do
      let(:file_exists) { true }

      it "should return parsed YAML" do
        expect(File).to receive(:exist?).with(composure).and_return(file_exists)
        expect(File).to receive(:new).with(composure).and_return(File.new('spec/fixtures/example.yml'))
        expect(subject).not_to be_empty
      end
    end
  end

  describe "#check_kong_reachable" do
    let(:kong_url) { 'http://example.com' }
    subject { described_class.new.check_kong_reachable(kong_url) }

    before do
      stub_const("Kongfigurator::MAX_CONNECTION_ATTEMPTS", 1)
      stub_const("Kongfigurator::CONNECTION_DELAY", 0)
    end

    context "http get doesn't raise an exception" do
      before do
        expect(Net::HTTP).to receive(:get_response).with(kong_url).and_return(http_response)
      end

      context "when we fail to connect" do
        let(:http_response) { Net::HTTPServiceUnavailable }

        it "should return an error code" do
          expect { subject }.to raise_error { |error|
            expect(error).to be_a(SystemExit)
            expect(error.status).to eq(4)
          }
        end
      end

      context "when we succeed in connecting" do
        let(:http_response) { Net::HTTPSuccess.new(1.0, 200, "OK") }

        it "should return with no error" do
          expect { subject }.not_to raise_error
        end
      end
    end

    context "http get raises exception" do
      before do
        expect(Net::HTTP).to receive(:get_response).with(kong_url).and_raise(StandardError)
      end

      it "should handle the exceptions and return the correct error code" do
        expect { subject }.to raise_error { |error|
          expect(error).to be_a(SystemExit)
          expect(error.status).to eq(4)
        }
      end
    end
  end

  describe "#register_apis" do
    let(:kong_url) { 'http://example.com' }
    subject { described_class.new.register_apis(kong_url, composure) }

    context "when we pass in an empty YAML file" do
      let(:composure) { {} }

      it "should do nothing" do
        expect(Net::HTTP).to_not receive(:post_form).with(kong_url, anything)
        expect { subject }.not_to raise_error
      end
    end

    context "when we pass in a YAML file with no labels section" do
      let(:composure) { YAML.load(File.new('spec/fixtures/config_with_no_labels_section.yml')) }

      it "should do nothing" do
        expect(Net::HTTP).to_not receive(:post_form).with(kong_url, anything)
        expect { subject }.not_to raise_error
      end
    end

    context "when we pass in a YAML file with labels but no upstream url or request path" do
      let(:composure) { YAML.load(File.new('spec/fixtures/config_with_no_upstream_url_or_request_path.yml')) }

      it "should do nothing" do
        expect(Net::HTTP).to_not receive(:post_form).with(kong_url, anything)
        expect { subject }.not_to raise_error
      end
    end

    context "when we pass in a YAML file with labels and an upstream url but no request path" do
      let(:composure) { YAML.load(File.new('spec/fixtures/config_with_upstream_url_but_no_request_path.yml')) }

      it "should do nothing" do
        expect(Net::HTTP).to_not receive(:post_form).with(kong_url, anything)
        expect { subject }.not_to raise_error
      end
    end

    context "when we pass in a YAML file with labels and a request path but no upstream url" do
      let(:composure) { YAML.load(File.new('spec/fixtures/config_with_request_path_but_no_upstream_url.yml')) }

      it "should do nothing" do
        expect(Net::HTTP).to_not receive(:post_form).with(kong_url, anything)
        expect { subject }.not_to raise_error
      end
    end

    context "when we pass in a YAML file with a basic config" do
      let(:composure) { YAML.load(File.new('spec/fixtures/config_with_basic_config.yml')) }
      let(:expected_data) { { 'upstream_url' => 'http://api:8080/endpoint/', 'request_path' => '/example_api', 'name' => 'example_api' } }

      it "should register the basic api with Kong" do
        expect(Net::HTTP).to receive(:post_form).with(kong_url, expected_data)
        expect { subject }.not_to raise_error
      end
    end

    context "when we pass in a YAML file with a basic config with strip path set" do
      let(:composure) { YAML.load(File.new('spec/fixtures/config_with_strip_path.yml')) }
      let(:expected_data) { { 'upstream_url' => 'http://api:8080/endpoint/', 'request_path' => '/v1/example_api', 'name' => 'example_api', 'strip_request_path' => 'true' } }

      it "should register the basic api with Kong" do
        expect(Net::HTTP).to receive(:post_form).with(kong_url, expected_data)
        expect { subject }.not_to raise_error
      end
    end

    context "when we pass in a YAML file with an overridden container name" do
      let(:composure) { YAML.load(File.new('spec/fixtures/config_with_overridden_container_name.yml')) }
      let(:expected_data) { { 'upstream_url' => 'http://api:8080/endpoint/', 'request_path' => '/example_api', 'name' => 'other_container_name' } }

      it "should register with Kong with the correct container name" do
        expect(Net::HTTP).to receive(:post_form).with(kong_url, expected_data)
        expect { subject }.not_to raise_error
      end
    end
  end
end
