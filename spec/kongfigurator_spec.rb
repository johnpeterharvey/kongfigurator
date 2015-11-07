require 'kongfigurator'
require 'climate_control'

RSpec.describe Kongfigurator, "#get_kong_url" do
  context "with no kong url set" do
    it "should return error code 1" do
      ClimateControl.modify KONG_URL "" do
        begin
          kongfig = new Kongfigurator
          kongfig.get_kong_url
        rescue SystemExit=>e
          expect(e.status).to eq(1)
        end
      end
    end
  end
end
