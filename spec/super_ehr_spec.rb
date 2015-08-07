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
require 'date'


RSpec.configure do |c|
    c.extend VCR::RSpec
end

redirect_uri = "http://dashboard.ekodevices.com/sync_chrono"
access_token_url = "https://www.drchrono.com/o/authorize/?redirect_uri=https%3A//dashboard.ekodevices.com/sync_chrono&response_type=code&client_id=ayIg8rp7JcN9MeD8X1TYvx5xMH50nL1NNHONhXiWm8eXW6ntIpp6WYdehVA5tBDF&scopes=user"

##First set of tokens for testing suite, expire and block calls to the api
access_token = "J3ABMD0zhVJPDU4REl2DGDr3aUL9g1"
refresh_token = "9bdkNnBs2xWT7Wy0IwUWWTBZKySx6J"

##Second set of tokents for testing suite
new_access_token = "zIa6QLb9IxeZOA4E0Y0zqgD4VMcPyE"
new_refresh_token = "SjSbrjfNqtlYKqMZKiQBaoUvqARDwF"

#third set of tokens for testing suite
third_access_token = "etStG7r6vJeVY7CJoQfgMmm9ky9hgJ"
third_refresh_token = "WYTGL9Nd3Ytar3Dj2qErldBG3XmeXu"



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
                response = SuperEHR.drchrono_b('e7eTuVTwdZyyELuKS0SfAV9z1nP2Z2', 'lHiwUEoO2JnCfiCFbhAiSiOVPmUCU2', ENV["CHRONO_CLIENT_ID"], ENV["CHRONO_CLIENT_SECRET"], redirect_uri)
                #Gets all of the Patients from Connors account, there are 48 patients
                VCR.use_cassette "DrChronoAPI/get_patients_please" do
                    patients = response.get_patients
                    expect(patients.length).to eq(61)
                    expect(patients[0]["first_name"]).to eq("Jason")
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
            end
        end
        it "describes another instance of dr chrono, same id and secret, different set of tokens" do
            #Initializes another dr chrono instance since the session with the original expired, new access_token and refresh_token, same id and secret so the data for this chrono instance should be the same as the original
            VCR.use_cassette "DrChronoAPI/second_drchrono_instance" do
                chrono = SuperEHR.drchrono_b(new_access_token, new_refresh_token, ENV["CHRONO_CLIENT_ID"], ENV["CHRONO_CLIENT_SECRET"], redirect_uri)
                expect(chrono.access_token).to eq("56GkF9ZWRPbK2g6jZc1VFqPY2DJMAZ")
                expect(chrono.refresh_token).to eq("WN2Lxjix9vQ0w0pye5aceZKlA8wG0R")
            end
        end
        # it "describes another dr chrono instance" do
        #     VCR.use_cassette "DrChronoAPI/third_drchrono_instance" do
        #         response = SuperEHR.drchrono_b("f7uZi5b7GDKUB9xjlGNWbL39vqvh6t", "qDYGeHhPMXPQZbX6m2c7goqtmzaJYP", ENV["CHRONO_CLIENT_ID"], ENV["CHRONO_CLIENT_SECRET"], redirect_uri)
        #         #Uploads a pdf document with a given file path to the patient profile with given patient_id
        #         VCR.use_cassette "DrChronoAPI/upload_pdf" do
        #             description = "sample pdf, should return 201 code"
        #             patient_id = 3333917
        #             file_path = "examples/test.pdf"
        #             upload = response.upload_document(patient_id, file_path, description, 'post')
        #             #visit url to see if it worked
        #             #pdf is uploaded using this method
        #         end
        #         VCR.use_cassette "DrChronoAPI/delete_pdf" do
        #             description = "sample pdf, delete"
        #             patient_id = 3333917
        #             file_path = "examples/test.pdf"
        #             upload = response.upload_document(patient_id, file_path, description, 'delete')
        #             puts upload.inspect

        #         end
        #     end
        # end

        it "describes the refresh token process" do
            VCR.use_cassette "DrChronoAPI/refresh_token_test" do
                refresh_token = "Z9S1k0cz1P30wqblavw1Gg3yjiZbuS"
                access_token = "pnmxa7sbyDVlnYn1LFpc1vcjq"
                response = SuperEHR.drchrono_b(access_token, refresh_token, ENV["CHRONO_CLIENT_ID"], ENV["CHRONO_CLIENT_SECRET"], redirect_uri)
            end
        end
    end
end

RSpec.describe SuperEHR::AllScriptsAPI do
    describe "allscripts" do
        it "describes an instance of Touchworks AllScriptsAPI" do
            VCR.use_cassette "AllScriptsAPI/create_allscripts" do
                client = SuperEHR.allscripts("jmedici", "password01", ENV["ALLSCRIPTS_APP_USERNAME"], ENV["ALLSCRIPTS_APP_PASSWORD"], ENV["ALLSCRIPTS_APP_NAME"], true)
                VCR.use_cassette "AllScriptsAPI/Touchworks/get_patient" do
                    patient = client.get_patient(33)
                    expect(patient).to be_an_instance_of(Hash)
                end

                VCR.use_cassette "AllScriptsAPI/Touchworks/get_changed_patients_ids" do 
                    patient_ids = client.get_changed_patients_ids(Date.today)
                    expect(patient_ids.length).to eq(18)
                end

                VCR.use_cassette "AllScriptsAPI/Touchworks/get_changed_patients" do
                    timestamp = Date.today
                    patients_since_now = client.get_changed_patients(timestamp)
                    expect(patients_since_now.length).to eq(18)
                end

                VCR.use_cassette "AllScriptsAPI/Touchworks/get_scheduled_patients" do
                    scheduled_patients = client.get_scheduled_patients(Date.today)
                    expect(scheduled_patients.length).to eq(7)
                end

                VCR.use_cassette "AllScriptsAPI/Touchworks/upload_pdf" do
                    filepath = "examples/test.pdf"
                    description = "example.pdf"
                    patient_id = 33
                    response = client.upload_document(patient_id, filepath, description)
                    expect(response[0]["savedocumentimageinfo"]).to be_an_instance_of(Array)
                end

                VCR.use_cassette "AllScriptsAPI/Touchworks/get_all_patients" do
                    all_patients = client.get_changed_patients("01/01/1900")
                end

            end
        end
        it "describes an instance of professional AllScriptsAPI" do
            VCR.use_cassette "AllScriptsAPI/Professional/create_allscripts" do 
                client = SuperEHR.allscripts("terry", "manning", ENV["ALLSCRIPTS_APP_USERNAME"], ENV["ALLSCRIPTS_APP_PASSWORD"], ENV["ALLSCRIPTS_APP_NAME"], false)
                VCR.use_cassette "AllScriptsAPI/Professional/get_patient" do
                    patient = client.get_patient(1)
                    expect(patient["Firstname"]).to eq("James")
                end

                VCR.use_cassette "AllScriptsAPI/Professional/get_changed_patients_ids" do
                    patient_ids = client.get_changed_patients_ids('01/01/2013')
                    expect(patient_ids.length).to eq(339)

                end

                VCR.use_cassette "AllScriptsAPI/Professional/get_changed_patients" do
                    timestamp = Date.today
                    patients_since_now = client.get_changed_patients('01/01/2013')
                    expect(patients_since_now.length).to eq(339)
                end

                VCR.use_cassette "AllScriptsAPI/Professional/get_scheduled_patients" do
                    scheduled_patients = client.get_scheduled_patients(Date.today)
                    expect(scheduled_patients).to eq([]) 
                end

                VCR.use_cassette "AllScriptsAPI/Professional/upload_pdf" do
                    filepath = "examples/test.pdf"
                    patient_id = 1
                    description = "test.pdf"
                    response = client.upload_document(patient_id, filepath, description)
                    expect(response).to be_true
                    expect(response[0]["savedocumentimageinfo"]).to be_an_instance_of(Array)
                end

            end
        end
    end
end


