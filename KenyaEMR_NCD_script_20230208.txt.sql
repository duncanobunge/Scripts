-- NCD Scripts
use openmrs;
select
  cc.patient_id,
  de.unique_patient_no as 'Unique Patient ID',
  date_format(cc.dob,'%d-%m-%Y') as 'DOB (dd-mm-yyyy ELSE missing)',
  DATE_FORMAT(FROM_DAYS(DATEDIFF(cc.latest_vis_date,cc.dob)), '%Y')+0 AS AgeatLastVisit,
  CASE
  WHEN cc.Gender ='F' THEN 'F'
  WHEN  cc.Gender ='M' THEN 'M' 
  ELSE 'Missing'
  END as 'Sex (F/M ELSE Missing)',
  date_format(cc.latest_vis_date,'%d-%m-%Y') as 'Date Last Appointment(dd-mm-yyyy)',
  date_format(cc.latest_tca,'%d-%m-%Y') as 'Date Next Appointment (dd-mm-yyyy)',
  '' as DrugDosageGiven,
  mid(max(concat(fup.visit_date, fup.weight)), 11) as 'Weight(kg)',
  GROUP_CONCAT((fup.weight) ORDER BY fup.visit_date  SEPARATOR '|') AS WeightSeq,
  mid(max(concat(fup.visit_date, fup.height)), 11) as 'Height(cm)',
  min(dr.date_started) as StartARTDate,
  mid(min(concat(dr.date_started, dr.regimen_name)), 11)as StartARTRegimen,
  mid(min(concat(dr.date_started, dr.regimen_line)), 11)as StartARTRegimenLine,
  max(dr.date_started) as CurrentARTStartDate,
  mid(max(concat(dr.date_started, dr.regimen_name)), 11) as CurrentARTRegimen,
  mid(max(concat(dr.date_started, dr.regimen_line)), 11)as CurrentARTRegimenLine,
  lee.VLLatestResult,
  lee.LatestVLDate,
  max(date(le.date_created)) as LatestVLDate,
  Round(mid(max(concat(fup.visit_date, fup.weight)), 11)/((mid(max(concat(fup.visit_date, fup.height)), 11)*0.01)*(mid(max(concat(fup.   visit_date, fup.height)), 11)*0.01)),2) as 'BMI',
  CASE WHEN mid(max(concat(fup.visit_date,fup.tb_status)),11) is NULL THEN 'Missing' ELSE 'YES' END AS 'TB Screening (Yes/No/Missing)',
  date_format(kenyaemr_etl.etl_ipt_initiation.visit_date,'%d-%m-%Y') as 'IPT Initiation Date (dd-mm-yyyy)',
  mid(max(concat(fup.visit_date, fup.cough)), 11) as 'Cough (Y/N/Missing)',
  CASE 
      WHEN mid(max(concat(fup.visit_date, fup.spatum_smear_ordered)),11)!='' OR  mid(max(concat(fup.visit_date, fup.chest_xray_ordered)), 11) !='' or
      mid(max(concat(fup.visit_date, fup.genexpert_ordered)), 11)!='' THEN 'Y'
      ELSE 'N'
      END AS 'InvestigationForCough',
  CASE 
      WHEN mid(max(concat(fup.visit_date, fup.spatum_smear_ordered)),11)!=''  then 'Sputum_smear'
      when mid(max(concat(fup.visit_date, fup.chest_xray_ordered)), 11) !='' then 'Chest_xray'
      when mid(max(concat(fup.visit_date, fup.genexpert_ordered)), 11)!='' THEN 'GeneXpert'
      ELSE 'Missing'
      END AS 'TypeOfInvestigation',
  CASE 
      WHEN mid(max(concat(fup.visit_date, fup.spatum_smear_result)),11)!='' THEN mid(max(concat(fup.visit_date, fup.spatum_smear_result)),11)
      WHEN mid(max(concat(fup.visit_date, fup.chest_xray_result)), 11) !='' THEN mid(max(concat(fup.visit_date, fup.chest_xray_result)), 11)
      WHEN mid(max(concat(fup.visit_date, fup.genexpert_result)), 11)!='' THEN  mid(max(concat(fup.visit_date, fup.genexpert_result)), 11)
      ELSE 'Missing'
      END AS 'InvestigationResult',
  mid(max(concat(fup.visit_date, fup.temperature)), 11) as 'Temperature',
CASE 
  when mid(max(concat(fup.visit_date, fup.nutritional_status)), 11)=114413 THEN 'overweight/obese'
  when mid(max(concat(fup.visit_date, fup.nutritional_status)), 11)=163303 THEN 'Moderate acute malnutrition'
  when mid(max(concat(fup.visit_date, fup.nutritional_status)), 11)=163302 THEN 'Severe acute malnutrition'
  when mid(max(concat(fup.visit_date, fup.nutritional_status)), 11)=1115 THEN 'Normal'
  ELSE 'Missing'
  end as 'Nutrition_status',
  mid(max(concat(fup.visit_date, fup.general_examination)), 11) as General_examination,
  CASE
    WHEN mid(max(concat(fup.visit_date, fup.has_chronic_illnesses_cormobidities)), 11)=1066 THEN 'No'
    WHEN mid(max(concat(fup.visit_date, fup.has_chronic_illnesses_cormobidities)), 11)=1065 THEN 'Yes'
    ELSE 'Missing'
  END as ChronicCormobidities,
  ei.ChronicIllness,
  ei.LatestIllnessOnset,
  group_concat(concat_ws(':',ei.Chronic_Illness, ei.onset_date) order by ei.onset_date separator '|') as ChronicIllness_Seq,
  mid(max(concat(fup.visit_date, fup.systolic_pressure)), 11) as Systolic,
  mid(max(concat(fup.visit_date, fup.diastolic_pressure)), 11) as Diastolic,
  fup.visit_date as BPTestDate ,
  g.glucoseTest,
  g.glucoseTestDate,
  CASE
            WHEN mid(max(concat(eds.visit_date, eds.PHQ_9_rating)), 11)=157790 THEN 'mild depression'
            WHEN mid(max(concat(eds.visit_date, eds.PHQ_9_rating)), 11)=134017 THEN 'Moderate Major Depression'
            WHEN mid(max(concat(eds.visit_date, eds.PHQ_9_rating)), 11)=126627 THEN 'Severe Depression'
            WHEN mid(max(concat(eds.visit_date, eds.PHQ_9_rating)), 11)=134011 THEN 'Moderate Recurrent Major Depression'
			WHEN mid(max(concat(eds.visit_date, eds.PHQ_9_rating)), 11)=1115 THEN 'Normal'
            ELSE 'Missing'
        END as PHQ9Rating,
max(eds.visit_date) as LatestDepressionScreeningDate,
 CASE
        WHEN mid(max(concat(adas.visit_date, adas.smoking_frequency)), 11) IN (163200) THEN 'Unknown if ever smoked'
        WHEN mid(max(concat(adas.visit_date, adas.smoking_frequency)), 11) IN (163199) THEN 'Current every day smoker'
        WHEN mid(max(concat(adas.visit_date, adas.smoking_frequency)), 11) IN (152807) THEN 'Former Smoker'
        WHEN mid(max(concat(adas.visit_date, adas.smoking_frequency)), 11) IN (163196) THEN 'Current light tobacco smoker'
        WHEN mid(max(concat(adas.visit_date, adas.smoking_frequency)), 11) IN (163195) THEN 'Current heavy tobacco smoker'
        WHEN mid(max(concat(adas.visit_date, adas.smoking_frequency)), 11) IN (152722) THEN 'Smoker'
        WHEN mid(max(concat(adas.visit_date, adas.smoking_frequency)), 11) IN (163197) THEN 'Current some day smoker'
        ELSE 'Missing'
        END as smoking_frequency,
      CASE 
        WHEN mid(max(concat(adas.visit_date, adas.drugs_use_frequency)), 11) IN (1090) THEN 'Never'
        WHEN mid(max(concat(adas.visit_date, adas.drugs_use_frequency)), 11) IN (1091) THEN 'Monthly or less'
        WHEN mid(max(concat(adas.visit_date, adas.drugs_use_frequency)), 11) IN (1092) THEN '2 to 4 times a month'
        WHEN mid(max(concat(adas.visit_date, adas.drugs_use_frequency)), 11) IN (1093) THEN '2 to 3 times a week'
        WHEN mid(max(concat(adas.visit_date, adas.drugs_use_frequency)), 11) IN (1094) THEN '4 to 5 times a week'
        WHEN mid(max(concat(adas.visit_date, adas.drugs_use_frequency)), 11) IN (1095) THEN '6 or more times a week'
        ELSE 'Missing'
        END as drugs_use_frequency,
      CASE 
	   WHEN mid(max(concat(adas.visit_date,  adas.alcohol_drinking_frequency)), 11) IN (1090) THEN 'Never' 
       WHEN mid(max(concat(adas.visit_date,  adas.alcohol_drinking_frequency)), 11) IN (1091) THEN 'Monthly or less' 
       WHEN mid(max(concat(adas.visit_date,  adas.alcohol_drinking_frequency)), 11) IN (1092) THEN '2 to 4 times a month'
       WHEN mid(max(concat(adas.visit_date,  adas.alcohol_drinking_frequency)), 11) IN (1093) THEN '2 to 3 times a week'
       WHEN mid(max(concat(adas.visit_date,  adas.alcohol_drinking_frequency)), 11) IN (1094) THEN '4 to 5 times a week' 
       WHEN mid(max(concat(adas.visit_date,  adas.alcohol_drinking_frequency)), 11) IN (1095) THEN '6 or more times a week' 
       ELSE 'Missing'
       END as alcohol_drinking_frequency,
	  max(adas.visit_date) as CagelatestScreeningDate
from kenyaemr_etl.etl_current_in_care cc
inner join kenyaemr_etl.etl_drug_event dr ON cc.patient_id = dr.patient_id
inner join kenyaemr_etl.etl_patient_hiv_followup fup on cc.patient_id= fup.patient_id
inner join kenyaemr_etl.etl_patient_demographics de on cc.patient_id = de.patient_id
inner join kenyaemr_etl.etl_hiv_enrollment ee on cc.patient_id = ee.patient_id
left outer join kenyaemr_etl.etl_depression_screening eds ON cc.patient_id = eds.patient_id
LEFT OUTER JOIN kenyaemr_etl.etl_alcohol_drug_abuse_screening  adas ON cc.patient_id=adas.patient_id
left outer join kenyaemr_etl.etl_laboratory_extract le on cc.patient_id = le.patient_id
left outer join kenyaemr_etl.etl_ipt_outcome on cc.patient_id =  kenyaemr_etl.etl_ipt_outcome.patient_id
LEFT OUTER JOIN kenyaemr_etl.etl_ipt_initiation ON cc.patient_id = kenyaemr_etl.etl_ipt_initiation.patient_id
left outer join(
select
   ei.patient_id,
   ei.chronic_illness_onset_date as onset_date,
   max(ei.chronic_illness_onset_date) as LatestIllnessOnset,
  CASE
   WHEN ei.chronic_illness=149019 THEN 'Alzheimer disease'
   WHEN ei.chronic_illness=148423 THEN 'Arthritis'
   WHEN ei.chronic_illness=153754 THEN 'Asthma'
   WHEN ei.chronic_illness=159351 THEN 'Cancer'
   WHEN ei.chronic_illness=119270 THEN 'Cardio Vascular'
   WHEN ei.chronic_illness=120637 THEN 'Chronic Hepatitis'
   WHEN ei.chronic_illness=145438 THEN 'Chronic Kidney Disease'
   WHEN ei.chronic_illness=1295 THEN 'Chronic Onstructive pulmonary Disease'
   WHEN  ei.chronic_illness=120576 THEN 'Chronic Renal Failure'
   WHEN  ei.chronic_illness=119692 THEN 'Cystic Fibrosis'
   WHEN  ei.chronic_illness=120291 THEN 'Deafness and Hearing Impairment'
   WHEN  ei.chronic_illness=119481 THEN 'Diabetes'
   WHEN  ei.chronic_illness=118631 THEN 'Endometriosis'
   WHEN  ei.chronic_illness=117855 THEN 'Epilepsy'
   WHEN  ei.chronic_illness=117789 THEN 'Glaucoma'
   WHEN  ei.chronic_illness=139071 THEN 'HeartDisease'
   WHEN  ei.chronic_illness=115728 THEN 'Hyperlipidaemia'
   WHEN  ei.chronic_illness=117399 THEN 'Hypertension'
   WHEN  ei.chronic_illness=117321 THEN 'Hypothyroidism'
   WHEN  ei.chronic_illness=151342 THEN 'Mental illness'
   WHEN  ei.chronic_illness=133687 THEN 'Multiple Sclerosis'
   WHEN  ei.chronic_illness=115115 THEN 'Obesity'
   WHEN  ei.chronic_illness=114662 THEN 'Osteoporosis'
   WHEN  ei.chronic_illness=117703 THEN 'Sickle cell Anaemia'
   WHEN  ei.chronic_illness=118976 THEN 'Thyroid disease'
   ELSE 'Missing'
   END as Chronic_Illness,
   CASE
   WHEN mid(max(concat(ei.visit_date, ei.chronic_illness)), 11)=149019 THEN 'Alzheimer disease'
   WHEN mid(max(concat(ei.visit_date, ei.chronic_illness)), 11)=148423 THEN 'Arthritis'
   WHEN mid(max(concat(ei.visit_date, ei.chronic_illness)), 11)=153754 THEN 'Asthma'
   WHEN mid(max(concat(ei.visit_date, ei.chronic_illness)), 11)=159351 THEN 'Cancer'
   WHEN mid(max(concat(ei.visit_date, ei.chronic_illness)), 11)=119270 THEN 'Cardio Vascular'
   WHEN mid(max(concat(ei.visit_date, ei.chronic_illness)), 11)=120637 THEN 'Chronic Hepatitis'
   WHEN mid(max(concat(ei.visit_date, ei.chronic_illness)), 11)=145438 THEN 'Chronic Kidney Disease'
   WHEN mid(max(concat(ei.visit_date, ei.chronic_illness)), 11)=1295 THEN 'Chronic Onstructive pulmonary Disease'
   WHEN mid(max(concat(ei.visit_date, ei.chronic_illness)), 11)=120576 THEN 'Chronic Renal Failure'
   WHEN mid(max(concat(ei.visit_date, ei.chronic_illness)), 11)=119692 THEN 'Cystic Fibrosis'
   WHEN mid(max(concat(ei.visit_date, ei.chronic_illness)), 11)=120291 THEN 'Deafness and Hearing Impairment'
   WHEN mid(max(concat(ei.visit_date, ei.chronic_illness)), 11)=119481 THEN 'Diabetes'
   WHEN mid(max(concat(ei.visit_date, ei.chronic_illness)), 11)=118631 THEN 'Endometriosis'
   WHEN mid(max(concat(ei.visit_date, ei.chronic_illness)), 11)=117855 THEN 'Epilepsy'
   WHEN mid(max(concat(ei.visit_date, ei.chronic_illness)), 11)=117789 THEN 'Glaucoma'
   WHEN mid(max(concat(ei.visit_date, ei.chronic_illness)), 11)=139071 THEN 'HeartDisease'
   WHEN mid(max(concat(ei.visit_date, ei.chronic_illness)), 11)=115728 THEN 'Hyperlipidaemia'
   WHEN mid(max(concat(ei.visit_date, ei.chronic_illness)), 11)=117399 THEN 'Hypertension'
   WHEN mid(max(concat(ei.visit_date, ei.chronic_illness)), 11)=117321 THEN 'Hypothyroidism'
   WHEN mid(max(concat(ei.visit_date, ei.chronic_illness)), 11)=151342 THEN 'Mental illness'
   WHEN mid(max(concat(ei.visit_date, ei.chronic_illness)), 11)=133687 THEN 'Multiple Sclerosis'
   WHEN mid(max(concat(ei.visit_date, ei.chronic_illness)), 11)=115115 THEN 'Obesity'
   WHEN mid(max(concat(ei.visit_date, ei.chronic_illness)), 11)=114662 THEN 'Osteoporosis'
   WHEN mid(max(concat(ei.visit_date, ei.chronic_illness)), 11)=117703 THEN 'Sickle cell Anaemia'
   WHEN mid(max(concat(ei.visit_date, ei.chronic_illness)), 11)=118976 THEN 'Thyroid disease'
   ELSE 'Missing'
   END as ChronicIllness
from kenyaemr_etl.etl_allergy_chronic_illness ei
group by ei.patient_id
)as ei on cc.patient_id = ei.patient_id
left outer join(
select
  o.person_id,
  cc.patient_id,
  date(o.obs_datetime) as glucoseTestDate,
  mid(max(concat(date(o.obs_datetime), o.value_numeric)), 11) as glucoseTest
from obs o
left outer join  kenyaemr_etl.etl_current_in_care cc on o.person_id=cc.patient_id
where o.concept_id in (887,160912)
group by o.person_id
) as g on cc.patient_id=g.patient_id
left outer join(
select
  le.patient_id,
  MAX(le.visit_date),
  CASE
    WHEN le.lab_test=1305 THEN 'LDL' 
    WHEN le.lab_test=856 and mid(max(concat(date(le.date_created), le.test_result)), 11)=1302 THEN 'LDL'
    WHEN le.lab_test=856 THEN mid(max(concat(date(le.date_created), le.test_result)), 11)
    END as VLLatestResult,
  max(date(le.date_created)) as LatestVLDate,
  max(le.date_test_result_received),
  max(le.date_created)
from kenyaemr_etl.etl_laboratory_extract le
where le.lab_test in (856,1305)
group by le.patient_id
)as lee on cc.patient_id = lee.patient_id
group by patient_id
-- order by rand()
-- limit 25
