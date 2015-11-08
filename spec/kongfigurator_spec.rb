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

    before do
      expect(File).to receive(:exist?).with(composure).and_return(file_exists)
    end

    context "when file is missing" do
      let(:file_exists) { false }

      it "should return an error code" do
        expect { subject }.to raise_error { |error|
          expect(error).to be_a(SystemExit)
          expect(error.status).to eq(3)
        }
      end
    end

    context "when file is found" do
      let(:file_exists) { true }

      it "should return parsed YAML" do
        expect(File).to receive(:new).with(composure).and_return(File.new('spec/example.yml'))
        expect(subject).not_to be_empty
      end
    end
  end

  describe "#check_kong_reachable" do
    let(:kong_url) { 'http://example.com' }
    subject { described_class.new.check_kong_reachable(kong_url) }

    before do
      expect(Net::HTTP).to receive(:get_response).with(kong_url).and_return(http_response)
      stub_const("Kongfigurator::MAX_CONNECTION_ATTEMPTS", 1)
      stub_const("Kongfigurator::CONNECTION_DELAY", 0)
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
end
