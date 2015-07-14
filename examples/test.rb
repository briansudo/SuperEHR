require'super_ehr'
require 'pp'
require 'sinatra'

# == DEMOS ==
# Enable Allscripts
enable_allscripts = false 
# Enable Athena
enable_athena     = false 
# Enable DrChrono
enable_drchrono   = true 
# Get all patient information for Changed Patients (Takes a long time)
get_all_changed_patient_info = false

if enable_allscripts 
  pp "########## ALLSCRIPTS ##########"

  # use touchworks ehr
  # jmedici is the ehr_username, password01 is the ehr_password
  a = SuperEHR.allscripts('ehr_username', 'ehr_password', 
                      'app_username', 'app_password', 'app_name',
                      true)

  # use professional ehr
  a = SuperEHR.allscripts('ehr_username', 'ehr_password', 
                      'app_username', 'app_password', 'app_name',
                      false)

  # Get Patient
  pp "get_patient(1)"
  pp "===="
  pp a.get_patient(1)

  puts ""
  
  if get_all_changed_patient_info
    # Get Changed Patients
    pp "get_changed_patients('01/01/2013')"
    pp "===="
    changed_patients = a.get_changed_patients("01/01/2013")
    pp changed_patients

    puts ""
  end
 
  
  # Get Changed Patients IDs
  pp "get_changed_patients_ids('01/01/2013')"
  pp "===="
  changed_patients = a.get_changed_patients_ids("01/01/2013")
  pp changed_patients.join(' ')

  puts ""
  

  # Get Scheduled Patients
  pp "get_scheduled_patients('11/03/2014')"
  pp "===="
  pp a.get_scheduled_patients('11/03/2014')

  puts ""

  # Upload documents
  pp "upload_document(758, 'test.pdf', 'Test Document')"
  pp "===="
  pp a.upload_document(758, "test.pdf", 'Test Document')

  puts ""

end

if enable_athena

  pp "########## ATHENA ##########"
  version = 'preview1'

  at = SuperEHR.athena('version', 'key', 'secret', 'practice_id')

  # Get Patient
  pp "get_patient(1)"
  pp "===="
  pp at.get_patient(1)

  puts ""
  
  if get_all_changed_patient_info
    # Get Changed Patients
    pp "get_changed_patients('01/01/2015')"
    pp "===="
    changed_patients = at.get_changed_patients("01/01/2015")
    pp changed_patients
    
    puts ""
  end

  # Get Changed Patients IDs
  pp "get_changed_patients_ids('01/01/2015')"
  pp "===="
  changed_patients = at.get_changed_patients_ids("01/01/2015")
  pp changed_patients.join(' ')

  puts ""

  # Get Scheduled Patients
  pp "get_scheduled_patients('11/03/2013')"
  pp "===="
  pp at.get_scheduled_patients('11/03/2013')

  puts ""

  # Upload documents
  pp "upload_document(1683, 'test.pdf', 'Test Document')"
  pp "===="
  pp at.upload_document(1683, "test.pdf", "Test Document")

end

if enable_drchrono
  
  client_id = "ayIg8rp7JcN9MeD8X1TYvx5xMH50nL1NNHONhXiWm8eXW6ntIpp6WYdehVA5tBDF"
  client_secret = "XW64OeenH5usIdDMt57vu09mPdtLdHRoJPxAWWjBd0HAikUJsMIFeqrDtPmPfhNq"
  redirect_url = "https%3A//dashboard.ekodevices.com/sync_chrono"
  access_token_url = "https://drchrono.com/o/authorize/?redirect_uri=#{redirect_url}/&response_type=code&client_id=#{client_id}&scopes=https://drchrono.com/api/patients/"
  system("open", access_token_url)

  get '/drchrono/' do
    access_code = params[:code]

    pp access_code

    puts "\n\n\n"

    pp "########## DrChrono ##########"
    d = SuperEHR.drchrono(access_code, client_id, client_secret, redirect_url)
    
    puts "\n"

    # Get Patient
    pp "get_patient(4757018)"
    pp "===="
    pp d.get_patient(4757018)

    puts ""

    # Get Patients
    pp "get_patients()"
    pp "===="
    pp d.get_patients()

    puts ""

    # Get Changed Patients
    pp "get_changed_patients('12/01/2014')"
    pp "===="
    changed_patients = d.get_changed_patients("12/01/2014")
    #pp changed_patients.join(' ') 
    pp changed_patients

    puts ""

    # Get Changed Patients IDs
    pp "get_changed_patients_ids('07/01/2014')"
    pp "===="
    changed_patients = d.get_changed_patients_ids("07/01/2014")
    pp changed_patients.join('')

    puts ""

    # Get Scheduled Patients
    pp "get_scheduled_patients('10/13/2012')"
    pp "===="
    pp d.get_scheduled_patients('10/13/2014')

    puts ""

    # Upload documents
    pp "upload_document(4757018, 'test.pdf', 'Test Document')"
    pp "===="
    pp d.upload_document(4757018, "test.pdf", "Test Document")

    # Ignore
    if not access_code
      "oh bugger"
    else
      access_code
    end
  end

end
