-- this script extract all patients who are described as Widowed in the registration form and are active in HIV care. 
use kenyaemr_etl;
select
 ecc.patient_id,
 epd.unique_patient_no as upn,
 concat(epd.given_name," ",epd.middle_name," ", epd.family_name) as name,
 epd.DOB,
 ecc.Gender,
 epd.marital_status,
 epd.phone_number,
 epd.occupation,
 epd.next_of_kin,
 epd.next_of_kin_phone,
 epd.next_of_kin_relationship,
 epd.education_level,
 ecc.enroll_date,
 ecc.latest_vis_date,
 ecc.latest_tca,
 ecc.started_on_drugs
from kenyaemr_etl.etl_current_in_care ecc
inner join kenyaemr_etl.etl_patient_demographics epd on ecc.patient_id=epd.patient_id
where epd.marital_status in ('Widowed')
