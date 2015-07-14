require "rspec"
require "super_ehr"
require "oauth2"
require 'httparty'
require 'json'
require 'webmock'
require 'rubygems'
require 'vcr'
require 'vcr_setup'


RSpec.configure do |c|
    c.extend VCR::RSpec
end


client_id = "ayIg8rp7JcN9MeD8X1TYvx5xMH50nL1NNHONhXiWm8eXW6ntIpp6WYdehVA5tBDF"
client_secret = "XW64OeenH5usIdDMt57vu09mPdtLdHRoJPxAWWjBd0HAikUJsMIFeqrDtPmPfhNq"
redirect_uri = "http://dashboard.ekodevices.com/sync_chrono"
access_token_url = "https://www.drchrono.com/o/authorize/?redirect_uri=https%3A//dashboard.ekodevices.com/sync_chrono&response_type=code&client_id=ayIg8rp7JcN9MeD8X1TYvx5xMH50nL1NNHONhXiWm8eXW6ntIpp6WYdehVA5tBDF&scopes=user"
access_token = "J3ABMD0zhVJPDU4REl2DGDr3aUL9g1"
refresh_token = "9bdkNnBs2xWT7Wy0IwUWWTBZKySx6J"


RSpec.describe SuperEHR::BaseEHR do
    it "Initilize BaseEHR" do
        base_ehr = SuperEHR::BaseEHR.new
        base_ehr.get_default_params.should == {}
        base_ehr.get_request_headers.should == {}
        base_ehr.get_request_body.should == {}
        #base_ehr.get_patient(1).should_receive(:error)
    end
end

RSpec.describe SuperEHR::DrChronoAPI do
    describe "Chrono" do
        it "describes a drchrono instance" do
            VCR.use_cassette 'DrChronoAPI/create_chrono1' do
                response = SuperEHR.drchrono_b(access_token, refresh_token, client_id, client_secret, redirect_uri)
                expect(response.access_token).to eq("TxHwWh0aFgdVjspV2N0Mm8EknawPYz")
                expect(response.refresh_token).to eq("4uLEwoaPdTsRk8x0EyLCH8dzniF4mx")
                VCR.use_cassette "DrChronoAPI/get_patients" do
                    patients = response.get_patients
                    expect(patients.length).to eq(48)
                    expect(patients[0]["first_name"]).to eq("Jason")
                end
                VCR.use_cassette "DrChronoAPI/get_patient_by_id" do
                    patient0 = response.get_patient(3921807)
                    expect(patient0["chart_id"]).to eq("PAPE000001")
                    patient1 = response.get_patient(3922255)
                    expect(patient1["last_name"]).to eq("Test")
                    patient2 = response.get_patient(56886648)
                    expect(patient2["first_name"]).to eq("Jonas")
                end
                VCR.use_cassette "DrChronoAPI/get_changed_patient" do
                    changed_patients = response.get_changed_patients("07/13/2015")
                    expect(changed_patients[0]["first_name"]).to eq("Carly")
                    expect(changed_patients[1]).to eq(nil)
                end
                VCR.use_cassette "DrChronoAPI/get_changed_patient_ids" do
                    first_changed_patients = response.get_changed_patients_ids("07/13/2015")
                    expect(first_changed_patients.length).to eq(1)
                    expect(first_changed_patients[0]).to eq(4575630)
                end
                VCR.use_cassette "DrChronoAPI/get_scheduled_patients" do
                    first_scheduled_patients = response.get_scheduled_patients("07/13/2015")
                    expect(first_scheduled_patients.length).to eq(2)
                    expect(first_scheduled_patients[0]["first_name"]).to eq("Annie")
                    expect(first_scheduled_patients[1]["first_name"]).to eq("Jonas")
                end
                VCR.use_cassette "DrChronoAPI/upload_document" do 
                    description = "sample description"
                    patient_id = 4575630
                    file_path = "examples/drchrono.txt"
                    upload = response.upload_document(patient_id, file_path, description)
                    puts upload.inspect
                end
            end
        end
    end
end

