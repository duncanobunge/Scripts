
select '2022-06-16' into @endDate;

select tx.patient_id,mfl,name,UPN,gender,dob,current_weight,date_of_current_weight,height,Date_of_Order as 'last vl order date',viral_load_date,
viral_load,art_start_date,latest_vis_date,latest_tca,previous_regimen,previous_regimen_date,current_regimen,current_regimen_date,current_regimen_line
from
(select 
patient_id,mfl,name,
UPN,gender,dob,weight as current_weight,weightdate as date_of_current_weight,height,viral_load_date,
viral_load,art_start_date,latest_vis_date,latest_tca,previous_regimen,previous_regimen_date,current_regimen,current_regimen_date,current_regimen_line from( 
 select fup.visit_date,fup.patient_id as patient_id, min(e.visit_date) as enroll_date,
max(fup.visit_date) as latest_vis_date,
mid(max(concat(fup.visit_date,fup.next_appointment_date)),11) as latest_tca,
max(d.visit_date) as date_discontinued,
d.patient_id as disc_patient,
de.patient_id as started_on_drugs,
art.art_start_date,
pr.regimen_name as previous_regimen,
art1.regimen_name as current_regimen,
pr.regimen_date as previous_regimen_date,
art1.regimen_date as current_regimen_date,
art1.regimen_line as current_regimen_line,
p.dob as dob,
p.gender as gender,
bmi.weight,
bmi.weightdate,
bmi.height,
p.unique_patient_no as UPN,
lab.viral_load_date,
 (
Select value_reference from openmrs.location 
left join (SELECT openmrs.location_attribute.value_reference,openmrs.location_attribute.location_id FROM openmrs.location_attribute where openmrs.location_attribute.attribute_type_id=1) mfl on mfl.location_id=openmrs.location.location_id
where openmrs.location.location_id =
(SELECT openmrs.global_property.property_value FROM openmrs.global_property where openmrs.global_property.property='kenyaemr.defaultlocation' limit 1)
) as mfl,
 (
Select name from openmrs.location 
left join (SELECT openmrs.location_attribute.value_reference,openmrs.location_attribute.location_id FROM openmrs.location_attribute where openmrs.location_attribute.attribute_type_id=1) mfl on mfl.location_id=openmrs.location.location_id
where openmrs.location.location_id =
(SELECT openmrs.global_property.property_value FROM openmrs.global_property where openmrs.global_property.property='kenyaemr.defaultlocation' limit 1)
) as name,
lab.viral_load
from kenyaemr_datatools.hiv_followup fup
join kenyaemr_datatools.patient_demographics p on p.patient_id=fup.patient_id
join kenyaemr_datatools.hiv_enrollment e on fup.patient_id=e.patient_id
left outer join kenyaemr_datatools.drug_event de on e.patient_id = de.patient_id and de.program='HIV' 
left join
(SELECT patient_id,min(date_started) as art_start_date
FROM kenyaemr_datatools.drug_event 
group by patient_id) art on art.patient_id = fup.patient_id

left join
(SELECT patient_id,
mid(max(concat(visit_date,regimen_name)),11) as regimen_name,
mid(max(concat(visit_date,regimen_name)),1,10) as regimen_date,
mid(max(concat(visit_date,regimen_line)),11) as regimen_line
FROM kenyaemr_datatools.drug_event 
where discontinued is null
group by patient_id) art1 on art1.patient_id = fup.patient_id

left join
(
SELECT patient_id,
mid(max(concat(visit_date,regimen_name)),11) as regimen_name,
mid(max(concat(visit_date,regimen_name)),1,10) as regimen_date
FROM kenyaemr_datatools.drug_event 
where discontinued = 1
group by patient_id
order by visit_date desc
) pr on pr.patient_id = fup.patient_id

left join
(SELECT patient_id,
mid(max(concat(visit_date,weight)),11) as weight,
mid(max(concat(visit_date,weight)),1,10) as weightdate,
mid(max(concat(visit_date,height)),11) as height
FROM kenyaemr_datatools.hiv_followup 
group by patient_id) bmi on bmi.patient_id = fup.patient_id

left join(SELECT patient_id,
max(visit_date) as viral_load_date,
mid(max(concat(visit_date,test_result)),11) as viral_load
FROM kenyaemr_datatools.laboratory_extract 
where lab_test= 'HIV VIRAL LOAD' group by patient_id) lab on lab.patient_id = fup.patient_id

left outer JOIN
(select patient_id, visit_date from kenyaemr_datatools.patient_program_discontinuation
 where date(visit_date) <= @endDate and program_name='HIV'
group by patient_id
) d on d.patient_id = fup.patient_id
where fup.visit_date <= @endDate
group by patient_id
 having (started_on_drugs is not null and started_on_drugs <> "") and 
 (((disc_patient is null and date_add(date(latest_tca), interval 30 DAY)  >= @endDate) or 
 (date(latest_tca) > date(date_discontinued) and date(latest_vis_date)> date(date_discontinued) 
and date_add(date(latest_tca), interval 30 DAY)  >= @endDate ))
          ) 
        ) t)tx 
        left outer join (SELECT e.patient_id,
SUBSTRING_INDEX(GROUP_CONCAT(IF(o.concept_id IN(1271) AND o.value_coded IN(856),DATE(o.obs_datetime),NULL)ORDER BY e.encounter_datetime SEPARATOR '|'),'|',-1) AS Date_of_Order

FROM openmrs.encounter e
LEFT OUTER JOIN openmrs.obs o ON o.encounter_id=e.encounter_id and o.voided=0 and e.voided=0 AND o.concept_id IN (856,1305,1271)
LEFT OUTER JOIN openmrs.concept_name cn ON o.value_coded=cn.concept_id AND cn.voided=0 AND cn.locale = 'en' and cn.concept_name_type='FULLY_SPECIFIED'
group by patient_id)ty on tx.patient_id=ty.patient_id;
