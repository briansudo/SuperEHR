# SuperEHR (Ruby Gem)
Integrate with various EHRs seamlessly. Generalizes various EHR vendors' idiosyncrasies into one general template. Extending and adding more features to this Gem is easy. Currently supports: Allscripts, Athena, DrChrono.

Each EHR has the following methods, unless otherwise noted:

```ruby
def get_patient(patient_id)
def get_patients            DRCHRONO ONLY
def get_changed_patients(day)
def get_changed_patients_ids(day)
def get_scheduled_patients(day)
def upload_document(patient_id, filepath, description)
```

To use:

```ruby
require 'super_ehr'

allscripts = SuperEHR.allscripts('ehr_username', 'ehr_password', 'app_username', 'app_password', 'app_name', false)

athena = SuperEHR.athena('version', 'key', 'secret', 'practice_id')

drchrono = SuperEHR.drchrono('access_code', 'client_id', 'client_secret', 'redirect_url')
drchrono2 = SuperEHR.drchrono_b('access_token', 'refresh_token', 'client_id', 'client_secret', 'redirect_url')
```
---

The API Calls
---
```ruby
def get_patient(patient_id)
```
Returns a hash containing all of the available patient information for patient with `patient_id`.

Depending on the API, `get_patient` may be used in other calls. This is because of API differences between vendors.
* Allscripts uses `get_patient` to return patient information as the other calls return only patient ids
* DrChrono uses `get_patient` to get a patient's primary physician id in the `upload_document` call

---
```ruby
def get_patients DRCHRONO ONLY
```
Returns a list of hashes containing patient information for all patients the client has access to.

_Only DrChrono has this API call._ Other APIs use other calls mentioned below to retrieve a large number of accessible patients.

---
```ruby
def get_changed_patients(day)
```
`day` should have the format `MM/DD/YYYY`
Returns a list of patient info of patients changed in the EHR since `day`

---
```ruby
def get_changed_patients_ids(day)
```
`day` should have the format `MM/DD/YYYY`
Same as above, but returns ids instead.

---
```ruby
def get_scheduled_patients(day, department_id=1 ATHENA ONLY)
```
`day` is a date with the format `MM/DD/YYYY`. For Athena, there is a second parameter `department_id` that is by default set to 1. You must insert the correct department_id for this call.
Returns a list of patients scheduled for `day`.

---
```ruby
def upload_document(patient_id, filepath, description, department_id=-1)
```
Uploads a document to the EHR. For Allscripts, `description` is not used, but still pass in `""` as it is required. For Athena, there is a second parameter `department_id` that is by default set to -1. If you call `upload_document` without passing in a `department_id`, the implementation will call `get_patient(patient_id)` and get the appropriate `department_id` for that patient.

---

Examples:
===

Allscripts | [Example Output](https://github.com/briansudo/SuperEHR/blob/master/examples/allscripts.txt)
---
```ruby
  # use touchworks ehr
  #a = SuperEHR.allscripts('ehr_username', 'ehr_password', 
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
```

Athena | [Example Output](https://github.com/briansudo/SuperEHR/blob/master/examples/athena.txt)
---
```ruby
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
```

DrChrono | [Example Output](https://github.com/briansudo/SuperEHR/blob/master/examples/drchrono.txt)
---
```ruby
  client_id = "client_id"
  client_secret = "client_secret"
  redirect_url = "redirect_url"
  access_token_url = "https://drchrono.com/o/authorize/?redirect_uri=#{redirect_url}/&response_type=code&client_id=#{client_id}"
  system("open", access_token_url)

  get '/drchrono/' do
    access_code = params[:code]

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
    pp changed_patients.join(' ')

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
```
