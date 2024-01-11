SELECT (select sitecode from kenyaemr_datatools.default_facility_info) as mfl,(select facilityname from kenyaemr_datatools.default_facility_info) as facility_name,unique_patient_no,Gender,
dob,TIMESTAMPDIFF(YEAR, DOB, CURDATE()) AS Age,ovc.visit_date as date_enrolled,ovc.client_enrolled_cpims,lab1.viral_load_date as initial_vl_date,lab1.viral_load as initial_vl,
lab.viral_load_date as current_vl_date,lab.viral_load as current_vl FROM kenyaemr_datatools.patient_demographics pd
inner join(select patient_id,max(visit_date) as visit_date, max(next_appointment_date) as tca from hiv_followup 
where next_appointment_date>='2022-06-30'
group by patient_id )fup on fup.patient_id=pd.patient_id
left join (select * from kenyaemr_etl.etl_ovc_enrolment) ovc on ovc.patient_id=pd.patient_id
left join(SELECT et.patient_id, 
et.visit_date as viral_load_date,
et.test_result as viral_load,
et.urgency as urgency
FROM kenyaemr_datatools.laboratory_extract et
inner join (SELECT patient_id,max(visit_date) as date1 FROM kenyaemr_datatools.laboratory_extract 
where lab_test= 'HIV VIRAL LOAD' group by patient_id
)lab1 on lab1.patient_id=et.patient_id and lab1.date1=et.visit_date
where lab_test= 'HIV VIRAL LOAD' 
group by et.patient_id) lab on lab.patient_id = pd.patient_id

left join(SELECT et.patient_id, 
et.visit_date as viral_load_date,
et.test_result as viral_load,
et.urgency as urgency
FROM kenyaemr_datatools.laboratory_extract et
inner join (SELECT patient_id,max(visit_date) as date1 FROM kenyaemr_datatools.laboratory_extract 
where lab_test= 'HIV VIRAL LOAD'  
 and visit_date< (select max(visit_date) from kenyaemr_etl.etl_ovc_enrolment 
 where kenyaemr_etl.etl_ovc_enrolment.patient_id=kenyaemr_datatools.laboratory_extract.patient_id
)
group by patient_id
)lab1 on lab1.patient_id=et.patient_id and lab1.date1=et.visit_date
where lab_test= 'HIV VIRAL LOAD' 
group by et.patient_id) lab1 on lab1.patient_id = pd.patient_id

where TIMESTAMPDIFF(YEAR, DOB, CURDATE())>0 and TIMESTAMPDIFF(YEAR, DOB, CURDATE())<18