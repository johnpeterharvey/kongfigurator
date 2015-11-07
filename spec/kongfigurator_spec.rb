require 'kongfigurator'
require 'climate_control'

RSpec.describe Kongfigurator, "#get_kong_url" do
  context "when no kong url is set" do
    it "should return an error code" do
      ClimateControl.modify KONG_URL: nil do
        expect { Kongfigurator.new.get_kong_url }.to raise_error { |error|
          expect(error).to be_a(SystemExit)
          expect(error.status).to eq(1)
        }
      end
    end
  end

  context "when kong url is set" do
    it "should return a new URI containing the URL" do
      ClimateControl.modify KONG_URL: 'http://localhost' do
        expect(Kongfigurator.new.get_kong_url).to eq(URI('http://localhost'))
      end
    end
  end
end
