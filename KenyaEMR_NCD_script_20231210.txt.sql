use openmrs;
SET @StartDate=date_format('2017-01-01','%m-%d-%Y') ;
SET @EndDate = date_format('2022-09-30','%m-%d-%Y') ;
SET @reportingDate=date_format(curdate(),'%m-%d-%Y');
select
  cc.patient_id,
  de.unique_patient_no as 'UniquePatientID',
  date_format(cc.dob,'%m-%d-%Y') as 'DOB',
  DATE_FORMAT(FROM_DAYS(DATEDIFF(cc.latest_vis_date,cc.dob)), '%Y')+0 AS AgeatLastVisit,
  cc.Gender as 'Sex',
  date_format(COALESCE(ee.date_first_enrolled_in_care, cc.enroll_date),'%m-%d-%Y') as DateEnrolledHIVCare,
  date_format(COALESCE(cc.latest_vis_date,max(fup.visit_date)),'%m-%d-%Y') as 'LatestVisitDate',
  date_format(COALESCE(cc.latest_tca,max(fup.next_appointment_date)),'%m-%d-%Y') as 'NextAppointmentDate',
  
  mid(max(concat(fup.visit_date, fup.weight)), 11) as 'Weight',
  mid(max(concat(fup.visit_date, fup.height)), 11) as 'Height',
  date_format((dr.date_started),'%m-%d-%Y') as StartARTDate,
  mid(min(concat(dr.date_started, dr.regimen_name)), 11)as StartARTRegimen,
  mid(min(concat(dr.date_started, dr.regimen_line)), 11)as StartARTRegimenLine,
  date_format(max(dr.date_started),'%m-%d-%Y') as CurrentARTStartDate,
  mid(max(concat(dr.date_started, dr.regimen_name)), 11) as CurrentARTRegimen,
  mid(max(concat(dr.date_started, dr.regimen_line)), 11)as CurrentARTRegimenLine,
  lee.VLLatestResult,
  date_format(lee.LatestVLDate,'%m-%d-%Y') as MostRecentVLDate,
  Round(mid(max(concat(fup.visit_date, fup.weight)), 11)/((mid(max(concat(fup.visit_date, fup.height)), 11)*0.01)*(mid(max(concat(fup.   visit_date, fup.height)), 11)*0.01)),2) as 'BMI',
  CASE WHEN mid(max(concat(fup.visit_date,fup.tb_status)),11) is NULL THEN 'Missing' ELSE 'YES' END AS 'TB Screening',
  date_format(kenyaemr_etl.etl_ipt_initiation.visit_date,'%m-%d-%Y') as 'IPTInitiationDate',
  mid(max(concat(fup.visit_date, fup.cough)), 11) as 'Cough',
  CASE 
      WHEN mid(max(concat(fup.visit_date, fup.spatum_smear_ordered)),11)!='' OR  mid(max(concat(fup.visit_date, fup.chest_xray_ordered)), 11) !='' or
      mid(max(concat(fup.visit_date, fup.genexpert_ordered)), 11)!='' THEN 'Y'
      ELSE 'N'
      END AS 'InvestigationForCough',
  mid(max(concat(fup.visit_date, fup.temperature)), 11) as 'Temperature',

  mid(max(concat(fup.visit_date, fup.nutritional_status)), 11) as NutritionStatus,
  mid(max(concat(fup.visit_date, fup.general_examination)), 11) as GeneralExamination,

  mid(max(concat(fup.visit_date, fup.has_chronic_illnesses_cormobidities)), 11) as ChronicCormobidities,
  ei.ChronicIllness,
  date_format(ei.LatestIllnessOnset,'%m-%d-%Y') as LatestIllnessOnset,
  mid(max(concat(fup.visit_date, fup.systolic_pressure)), 11) as Systolic,
  mid(max(concat(fup.visit_date, fup.diastolic_pressure)), 11) as Diastolic,
  date_format(fup.visit_date,'%m-%d-%Y') as BPTestDate ,
  g.glucoseTest,
  date_format(g.glucoseTestDate,'%m-%d-%Y')as GlucoseTestDate,
	mid(max(concat(eds.visit_date, eds.PHQ_9_rating)), 11) as PHQ9Rating,
	date_format(max(eds.visit_date),'%m-%d-%Y') as LatestDepressionScreeningDate,
	mid(max(concat(adas.visit_date, adas.smoking_frequency)), 11) as smoking_frequency,
	mid(max(concat(adas.visit_date, adas.drugs_use_frequency)), 11) as drugs_use_frequency,
	mid(max(concat(adas.visit_date,  adas.alcohol_drinking_frequency)), 11) as alcohol_drinking_frequency,
	date_format(max(adas.visit_date),'%m-%d-%Y') as AlcoholDrugMostRecentScreeningDate,
    cc.started_on_drugs
from kenyaemr_etl.etl_hiv_enrollment ee 
left outer join kenyaemr_etl.etl_current_in_care cc on ee.patient_id=cc.patient_id
inner join kenyaemr_etl.etl_drug_event dr ON ee.patient_id = dr.patient_id
inner join kenyaemr_etl.etl_patient_hiv_followup fup on ee.patient_id= fup.patient_id
inner join kenyaemr_etl.etl_patient_demographics de on ee.patient_id = de.patient_id
left outer join kenyaemr_etl.etl_depression_screening eds ON ee.patient_id = eds.patient_id
LEFT OUTER JOIN kenyaemr_etl.etl_alcohol_drug_abuse_screening  adas ON ee.patient_id=adas.patient_id
left outer join kenyaemr_etl.etl_laboratory_extract le on ee.patient_id = le.patient_id
left outer join kenyaemr_etl.etl_ipt_outcome on ee.patient_id =  kenyaemr_etl.etl_ipt_outcome.patient_id
LEFT OUTER JOIN kenyaemr_etl.etl_ipt_initiation ON ee.patient_id = kenyaemr_etl.etl_ipt_initiation.patient_id
left outer join kenyaemr_etl.etl_patient_program_discontinuation eppd ON ee.patient_id=eppd.patient_id and eppd.program_name='HIV'
left outer join(
select
   ei.patient_id,
   ei.chronic_illness_onset_date as onset_date,
   max(ei.chronic_illness_onset_date) as LatestIllnessOnset,
   mid(max(concat(ei.visit_date, ei.chronic_illness)), 11) as ChronicIllness
from kenyaemr_etl.etl_allergy_chronic_illness ei
group by ei.patient_id
)as ei on ee.patient_id = ei.patient_id
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
) as g on ee.patient_id=g.patient_id
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
)as lee on ee.patient_id = lee.patient_id

group by patient_id
having DateEnrolledHIVCare between @StartDate and @EndDate

