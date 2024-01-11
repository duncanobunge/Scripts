SELECT pd.patient_id,pd.gender,pd.dob,pd.unique_patient_no,c_visit_date,c_lab.viral_load_date,c_lab.viral_load,c_tca,c_refill_date,
father.patient_id,father.gender,father.dob,father.unique_patient_no,father.f_visit_date,father.viral_load_date as f_viral_load_date,father.viral_load as f_viral_load,father.f_tca,father.f_refill_date,
mother.patient_id,mother.gender,mother.dob,mother.unique_patient_no,mother.m_visit_date,mother.viral_load_date as m_viral_load_date,mother.viral_load as m_viral_load,mother.m_tca,mother.m_refill_date
from patient_demographics pd
left join (select patient_id,max(visit_date) as c_visit_date,max(next_appointment_date) as c_tca,max(refill_date) as c_refill_date from hiv_followup group by patient_id) hp on hp.patient_id=pd.patient_id
left join(SELECT patient_id,
max(visit_date) as viral_load_date,
mid(max(concat(visit_date,test_result)),11) as viral_load,
mid(max(concat(visit_date,urgency)),11) as urgency
FROM kenyaemr_datatools.laboratory_extract 
where lab_test= 'HIV VIRAL LOAD' group by patient_id) c_lab on c_lab.patient_id=pd.patient_id
left join bondo.relationship rs on rs.person_b=pd.patient_id
left join (SELECT pdf.patient_id,pdf.gender,pdf.dob,pdf.unique_patient_no,f_visit_date,f_tca,f_refill_date,f_lab.viral_load_date,f_lab.viral_load from patient_demographics pdf
left join (select patient_id,max(visit_date) as f_visit_date,max(next_appointment_date) as f_tca,max(refill_date) as f_refill_date from hiv_followup group by patient_id) hpf on hpf.patient_id=pdf.patient_id

left join(SELECT patient_id,
max(visit_date) as viral_load_date,
mid(max(concat(visit_date,test_result)),11) as viral_load,
mid(max(concat(visit_date,urgency)),11) as urgency
FROM kenyaemr_datatools.laboratory_extract 
where lab_test= 'HIV VIRAL LOAD' group by patient_id) f_lab on f_lab.patient_id=pdf.patient_id

where gender='m'
)father on father.patient_id=rs.person_a
left join (SELECT pdm.patient_id,pdm.gender,pdm.dob,pdm.unique_patient_no,m_visit_date,m_tca,m_refill_date,m_lab.viral_load_date,m_lab.viral_load from patient_demographics pdm
left join (select patient_id,max(visit_date) as m_visit_date,max(next_appointment_date) as m_tca,max(refill_date) as m_refill_date from hiv_followup group by patient_id) hpm on hpm.patient_id=pdm.patient_id

left join(SELECT patient_id,
max(visit_date) as viral_load_date,
mid(max(concat(visit_date,test_result)),11) as viral_load,
mid(max(concat(visit_date,urgency)),11) as urgency
FROM kenyaemr_datatools.laboratory_extract 
where lab_test= 'HIV VIRAL LOAD' group by patient_id) m_lab on m_lab.patient_id=pdm.patient_id

where gender='f')mother on mother.patient_id=rs.person_a

where pd.dob >'2001-03-01' and pd.unique_patient_no is not null and c_tca >= '2022-06-30'