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


RSpec.describe SuperEHR do

    describe ".drchrono_b" do
        it "initializes SuperEHR as Dr Chrono instance" do
            VCR.use_cassette 'DrChronoAPI/create_chrono1' do
                response = SuperEHR.drchrono_b('e7eTuVTwdZyyELuKS0SfAV9z1nP2Z2', 'lHiwUEoO2JnCfiCFbhAiSiOVPmUCU2', ENV["CHRONO_CLIENT_ID"], ENV["CHRONO_CLIENT_SECRET"], redirect_uri)
                expect(response).to be_a SuperEHR::DrChronoAPI
            end
        end
    end

    describe ".allscripts" do
        it "initializes SuperEHR as Allscripts instance" do
            VCR.use_cassette "AllScriptsAPI/create_allscripts" do
                response = SuperEHR.allscripts("jmedici", "password01", ENV["ALLSCRIPTS_APP_USERNAME"], ENV["ALLSCRIPTS_APP_PASSWORD"], ENV["ALLSCRIPTS_APP_NAME"], true)
                expect(response).to be_a SuperEHR::AllScriptsAPI
            end
        end
    end

    describe ".athena" do
        it "initializes SuperEHR as Athena instance" do
            VCR.use_cassette "AthenaHealthAPI/initializeAthena" do
                response = SuperEHR.athena("preview1", ENV["ATHENA_HEALTH_KEY"], ENV["ATHENA_HEALTH_SECRET"], 195900)
                expect(response).to be_a SuperEHR::AthenaAPI

            end
        end
    end
end


RSpec.describe SuperEHR::BaseEHR do
    it "initilizes BaseEHR with default parameters" do
        base_ehr = SuperEHR::BaseEHR.new
        expect(base_ehr.get_default_params).to eq({})
        expect(base_ehr.get_request_headers).to eq({})
        expect(base_ehr.get_request_body).to eq({})
        #base_ehr.get_patient(1).should_receive(:error)
    end
end


RSpec.describe SuperEHR::DrChronoAPI do
    #initialize the Dr Chrono instance that the rest of the API tests will use
    VCR.use_cassette 'DrChronoAPI/create_chrono1' do

        response = SuperEHR.drchrono_b('e7eTuVTwdZyyELuKS0SfAV9z1nP2Z2', 'lHiwUEoO2JnCfiCFbhAiSiOVPmUCU2', ENV["CHRONO_CLIENT_ID"], ENV["CHRONO_CLIENT_SECRET"], redirect_uri)

        #Gets all of the Patients from Connors account, there are 48 patients
        describe "#get_patients" do
            it "gets all patients from users account" do
                VCR.use_cassette "DrChronoAPI/get_patients_please" do
                    patients = response.get_patients
                    expect(patients.length).to eq(61)
                    expect(patients[0]["first_name"]).to eq("Jason")
                end
            end
        end

        #Gets the patients changed after a certain date in the format MM/DD/YYYY
        describe "#get_changed_patients" do
            it "gets all changed patients since agiven date" do
                VCR.use_cassette "DrChronoAPI/get_changed_patient" do
                    changed_patients = response.get_changed_patients("07/13/2015")
                    expect(changed_patients[0]["first_name"]).to eq("Carly")
                    expect(changed_patients[1]).to eq(nil)
                end
            end
        end

        #Gets the id's of all the patients changed after a given date in the format MM/DD/YYYY
        describe "get_changed_patients_ids" do
            it "gets the id's of changed patients since a given date" do
                VCR.use_cassette "DrChronoAPI/get_changed_patient_ids" do
                    first_changed_patients = response.get_changed_patients_ids("07/13/2015")
                    expect(first_changed_patients.length).to eq(1)
                    expect(first_changed_patients[0]).to eq(4575630)
                end
            end
        end

        #Gets all the scheduled patients on a certain date in the format MM/DD/YYYY
        describe "#get_scheduled_patients" do
            it "gets all scheduled patients on a given date" do
                VCR.use_cassette "DrChronoAPI/get_scheduled_patients" do
                    first_scheduled_patients = response.get_scheduled_patients("07/13/2015")
                    expect(first_scheduled_patients.length).to eq(2)
                    expect(first_scheduled_patients[0]["first_name"]).to eq("Annie")
                    expect(first_scheduled_patients[1]["first_name"]).to eq("Jonas")
                end
            end
        end

    end

    context "when different set of tokens" do
        it "retrieves new access token with refresh token" do
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

        it "initializes new instance of Dr Chrono with refresh token" do
            VCR.use_cassette "DrChronoAPI/refresh_token_test" do
                refresh_token = "Z9S1k0cz1P30wqblavw1Gg3yjiZbuS"
                access_token = "pnmxa7sbyDVlnYn1LFpc1vcjq"
                response = SuperEHR.drchrono_b(access_token, refresh_token, ENV["CHRONO_CLIENT_ID"], ENV["CHRONO_CLIENT_SECRET"], redirect_uri)
                expect(response.access_token).to eq("Lb7CGck0eaEwVL3Vvmmo1atSucsNnm")
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
                    expect(patient_ids.length).to eq(10)
                end

                VCR.use_cassette "AllScriptsAPI/Touchworks/get_changed_patients" do
                    timestamp = Date.today
                    patients_since_now = client.get_changed_patients(timestamp)
                    expect(patients_since_now.length).to eq(10)
                end

                VCR.use_cassette "AllScriptsAPI/Touchworks/get_scheduled_patients" do
                    scheduled_patients = client.get_scheduled_patients(Date.today)
                    # expect(scheduled_patients.length).to eq(7)
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
                    expect(response[0]["savedocumentimageinfo"]).to be_an_instance_of(Array)
                end
            end
        end
    end
end


RSpec.describe SuperEHR::AthenaAPI do

    VCR.use_cassette "AthenaHealthAPI/initializeAthena" do

        client = SuperEHR.athena("preview1", ENV["ATHENA_HEALTH_KEY"], ENV["ATHENA_HEALTH_SECRET"], 195900)

        describe "#get_patient" do
            it "gets all patients from users account" do
                VCR.use_cassette "AthenaHealthAPI/get_patient_by_id" do
                    response = client.get_patient(1)
                    expect(response["lastname"]).to eq("Huff")
                    expect(response["city"]).to eq("ASHBURN")
                    expect(response["sex"]).to eq("M")
                end
            end
        end

        describe "#get_changed_patients_ids" do
            it "gets the id's of changed patients since agiven date" do
                #when running rspec, you must delete this cassette because it calls a new end_time every call
                VCR.use_cassette "AthenaHealthAPI/get_changed_patients_ids" do
                    response = client.get_changed_patients_ids("01/01/2015")
                    expect(response[0]).to eq("3646")
                    expect(response[1]).to eq("3647")
                    expect(response.length).to eq(1074)
                end
            end
        end

        describe "#get_changed_patients" do
            it "gets all changed patients since a given date" do
                #when running rspec, you must delete this cassette because it calls a new end_time every call
                VCR.use_cassette "AthenaHealthAPI/get_changed_patients" do
                    response = client.get_changed_patients("01/01/2015")
                    expect(response[0]["patientid"]).to eq("3646")
                    expect(response.length).to eq(1074)
                end
            end
        end

        describe "#get_scheduled_patients" do
            it "gets all scheduled patients on a given date" do
                VCR.use_cassette "AthenaHealthAPI/get_scheduled_patients" do
                    response = client.get_scheduled_patients("08/07/2015")
                    expect(response.length).to eq(4)
                end
            end
        end

        describe "#upload_document" do
            it "uploads a PDF to a patients record" do
                VCR.use_cassette "AthenaHealthAPI/upload_pdf/single_department_id" do
                    patient_id = 3646
                    file_path = "examples/test.pdf"
                    description = "example pdf"
                    response = client.upload_document(patient_id, file_path, description)
                end

                #when running rspec, you must delete this cassette because it calls a new end_time every call
                VCR.use_cassette "AthenaHealthAPI/get_all_patients" do
                    response = client.get_patients
                    expect(response.length).to eq(1079)
                end
            end
        end

        #when running rspec, you must delete this cassette because it calls a new end_time every call
        VCR.use_cassette "AthenaHealthAPI/get_all_patients" do
            response = client.get_patients
        end
    end
end


