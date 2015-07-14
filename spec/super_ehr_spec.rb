require "rspec"
require "super_ehr"
require "oauth2"
require 'httparty'
require 'json'
require 'webmock'
require 'rubygems'
require 'vcr'
require 'vcr_setup'
require 'curb'


RSpec.configure do |c|
    c.extend VCR::RSpec
end



client_id = "ayIg8rp7JcN9MeD8X1TYvx5xMH50nL1NNHONhXiWm8eXW6ntIpp6WYdehVA5tBDF"
client_secret = "XW64OeenH5usIdDMt57vu09mPdtLdHRoJPxAWWjBd0HAikUJsMIFeqrDtPmPfhNq"
redirect_uri = "http://dashboard.ekodevices.com/sync_chrono"
access_token_url = "https://www.drchrono.com/o/authorize/?redirect_uri=https%3A//dashboard.ekodevices.com/sync_chrono&response_type=code&client_id=ayIg8rp7JcN9MeD8X1TYvx5xMH50nL1NNHONhXiWm8eXW6ntIpp6WYdehVA5tBDF&scopes=user"

##First set of tokens for testing suite, expire and block calls to the api
access_token = "J3ABMD0zhVJPDU4REl2DGDr3aUL9g1"
refresh_token = "9bdkNnBs2xWT7Wy0IwUWWTBZKySx6J"

##Second set of tokents for testing suite
new_access_token = "zIa6QLb9IxeZOA4E0Y0zqgD4VMcPyE"
new_refresh_token = "SjSbrjfNqtlYKqMZKiQBaoUvqARDwF"



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
            #initializes the Dr Chrono instance that the rest of the API tests will use
            VCR.use_cassette 'DrChronoAPI/create_chrono1' do
                response = SuperEHR.drchrono_b(access_token, refresh_token, client_id, client_secret, redirect_uri)
                expect(response.access_token).to eq("TxHwWh0aFgdVjspV2N0Mm8EknawPYz")
                expect(response.refresh_token).to eq("4uLEwoaPdTsRk8x0EyLCH8dzniF4mx")
                #Gets all of the Patients from Connors account, there are 48 patients
                VCR.use_cassette "DrChronoAPI/get_patients" do
                    patients = response.get_patients
                    expect(patients.length).to eq(48)
                    expect(patients[0]["first_name"]).to eq("Jason")
                end
                #Gets patients by the id they are stored in the database, this id is used to identify the url for the patient as well; hidden behind the https://drchrono.com/api/patients/ namespace
                VCR.use_cassette "DrChronoAPI/get_patient_by_id" do
                    patient0 = response.get_patient(3921807)
                    expect(patient0["chart_id"]).to eq("PAPE000001")
                    patient1 = response.get_patient(3922255)
                    expect(patient1["last_name"]).to eq("Test")
                    patient2 = response.get_patient(56886648)
                    expect(patient2["first_name"]).to eq("Jonas")
                end
                #Gets the patients changed after a certain date in the format MM/DD/YYYY
                VCR.use_cassette "DrChronoAPI/get_changed_patient" do
                    changed_patients = response.get_changed_patients("07/13/2015")
                    expect(changed_patients[0]["first_name"]).to eq("Carly")
                    expect(changed_patients[1]).to eq(nil)
                end
                #Gets the id's of all the patients changed after a given date in the format MM/DD/YYYY
                VCR.use_cassette "DrChronoAPI/get_changed_patient_ids" do
                    first_changed_patients = response.get_changed_patients_ids("07/13/2015")
                    expect(first_changed_patients.length).to eq(1)
                    expect(first_changed_patients[0]).to eq(4575630)
                end
                #Gets all the scheduled patients on a certain date in the format MM/DD/YYYY
                VCR.use_cassette "DrChronoAPI/get_scheduled_patients" do
                    first_scheduled_patients = response.get_scheduled_patients("07/13/2015")
                    expect(first_scheduled_patients.length).to eq(2)
                    expect(first_scheduled_patients[0]["first_name"]).to eq("Annie")
                    expect(first_scheduled_patients[1]["first_name"]).to eq("Jonas")
                end
                #Uploads a txt document of a given file path to the profile of a patient with a given patient_id
                VCR.use_cassette "DrChronoAPI/upload_document" do 
                    description = "sample description"
                    patient_id = 4575630
                    file_path = "examples/drchrono.txt"
                    upload = response.upload_document(patient_id, file_path, description)
                    patient_url = upload["patient"]
                    patient_description = upload["description"]
                    patient_id_of_upload = patient_url[34..-1].to_i
                    expect(patient_description).to eq(description)
                    expect(patient_id_of_upload).to eq(patient_id)
                    document_url = upload["document"]
                    #make curl request and compare output to the source file
                    VCR.use_cassette "DrChronoAPI/curl_requests/test_txt" do
                        http = Curl.get(document_url)
                        # puts http.body_str
                        #This test puts correctly
                    end 
                end
            end
        end
        it "describes another instance of dr chrono, same id and secret, different set of tokens" do
            #Initializes another dr chrono instance since the session with the original expired, new access_token and refresh_token, same id and secret so the data for this chrono instance should be the same as the original
            VCR.use_cassette "DrChronoAPI/second_drchrono_instance" do
                chrono = SuperEHR.drchrono_b(new_access_token, new_refresh_token, client_id, client_secret, redirect_uri)
                expect(chrono.access_token).to eq("56GkF9ZWRPbK2g6jZc1VFqPY2DJMAZ")
                expect(chrono.refresh_token).to eq("WN2Lxjix9vQ0w0pye5aceZKlA8wG0R")
                #Uploads a pdf document with a given file path to the patient profile with given patient_id
                VCR.use_cassette "DrChronoAPI/upload_pdf" do
                    description = "sample pdf"
                    patient_id = 3333917
                    file_path = "examples/test.pdf"
                    upload = chrono.upload_document(patient_id, file_path, description)
                    patient_url = upload["patient"]
                    patient_description = upload["description"]
                    patient_id_of_upload = patient_url[34..-1].to_i
                    expect(patient_id_of_upload).to eq(patient_id)
                    expect(patient_description).to eq(description)
                    new_document_url = upload["document"]
                    puts new_document_url
                    #visit url to see if it worked
                    #pdf is uploaded using this method
                end
            end
        end

    end
end
