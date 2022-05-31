-- this scripts pulls all the active clients as at end of the immediate reported month
-- from the linelist, use systematic sampling to generate your sample size for RDQA activities.
-- paste your sample size line-list on the EMR sheet on the RDQA tool.
-- On the Greencard sheet proceed with the manual entry from the paper greencard.
-- Finally check on your on the Scores sheets
use kenyaemr_etl;
select
  cc.patient_id,
  de.unique_patient_no as 'CCC Number (Unique Patient ID)',
  CASE
  WHEN cc.Gender ='F' THEN 'Female'
  WHEN  cc.Gender ='M' THEN 'Male' 
  ELSE 'Missing'
  END as 'Sex (Female/Male ELSE Missing)',
  date_format(cc.dob,'%d/%m/%Y') as 'Date of Birth (dd/mm/yyyy ELSE missing)',
  date_format(ee.date_confirmed_hiv_positive,'%d/%m/%Y') as 'Date Confirmed HIV Positive',
  date_format(cc.enroll_date,'%d/%m/%Y') as 'Date Enrolled in HIV Care (dd/mm/yyyy)',
  date_format(min(dr.date_started),'%d/%m/%Y') as 'Date of ART initiation (dd/mm/yyyy)',
  mid(min(concat(dr.date_started, dr.regimen_name)), 11)as 'Initial ART Regimen',
  mid(max(concat(dr.date_started, dr.regimen_name)), 11) as 'Current ART regimen',
  Round(mid(max(concat(fup.visit_date, fup.weight)), 11)/((mid(max(concat(fup.visit_date, fup.height)), 11)*0.01)*(mid(max(concat(fup.visit_date, fup.height)), 11)*0.01)),2) as 'BMI at last visit',
  CASE WHEN mid(max(concat(fup.visit_date,fup.tb_status)),11) is NULL THEN 'Missing' ELSE 'YES' END AS 'TB Screening at last visit',
  CASE 
		   WHEN mid(max(concat(fup.visit_date,fup.tb_status)),11) IN (1663) THEN 'TB RX Completed'
		   WHEN mid(max(concat(fup.visit_date,fup.tb_status)),11) IN (142177) THEN 'Pr TB'
		   WHEN mid(max(concat(fup.visit_date,fup.tb_status)),11) IN (1661) THEN 'TB Diagnosed'
		   WHEN mid(max(concat(fup.visit_date,fup.tb_status)),11) IN (1660) THEN 'No TB'
		   WHEN mid(max(concat(fup.visit_date,fup.tb_status)),11) IN (1662) THEN 'TB Rx'
		   WHEN mid(max(concat(fup.visit_date,fup.tb_status)),11) IN (160737) THEN 'Not Done'
		   ELSE 'Missing'
		   END AS 'TB Screening outcome',
  date_format(kenyaemr_etl.etl_ipt_initiation.visit_date,'%d/%m/%Y') as 'IPT Start Date (dd/mm/yyyy)',
    CASE 
		   WHEN kenyaemr_etl.etl_ipt_outcome.outcome IN (112141) THEN 'Discontinued'
		   WHEN kenyaemr_etl.etl_ipt_outcome.outcome IN (1267) THEN 'Completed'
		   ELSE 'Missing'
		   END As 'IPT status',
    date_format(kenyaemr_etl.etl_ipt_outcome.visit_date,'%d/%m/%Y') as 'IPT Outcome Date (dd/mm/yyyy)',
	-- le.VL_SEQ AS VL_SEQ,
	le.second_last_vl_result AS 'Second last VL result',
	le.second_last_vl_date AS 'Second Last VL date',
	le.recent_vl_result AS 'Recent Viral load Result',
	le.recent_vl_result_date AS 'Most Recent Viral load date (dd/mm/yyyy)',
    date_format(cc.latest_vis_date,'%d/%m/%Y') as 'Last clinical encounter date (dd/mm/yyyy)',
    date_format(cc.latest_tca,'%d/%m/%Y') as 'Next appointment date (dd/mm/yyyy)',
    CASE 
           WHEN mid(max(concat(fup.visit_date,fup.wants_pregnancy)),11) IN (1066) THEN 'No'
           WHEN mid(max(concat(fup.visit_date,fup.wants_pregnancy)),11) IN (1065) THEN 'Yes'
           WHEN cc.Gender IN('M') THEN 'NA'
           ELSE 'Missing'
         END AS 'Pregnancy intention assessment at last visit',
	'Missing' as'Initial EID within 8 weeks',
	'Missing' as 'Infant prophylaxis'
from kenyaemr_etl.etl_current_in_care cc
inner join kenyaemr_etl.etl_drug_event dr ON cc.patient_id = dr.patient_id
inner join kenyaemr_etl.etl_patient_hiv_followup fup on cc.patient_id= fup.patient_id
inner join kenyaemr_etl.etl_patient_demographics de on cc.patient_id = de.patient_id
inner join kenyaemr_etl.etl_hiv_enrollment ee on cc.patient_id = ee.patient_id
left outer join kenyaemr_etl.etl_ipt_outcome on cc.patient_id =  kenyaemr_etl.etl_ipt_outcome.patient_id
LEFT OUTER JOIN kenyaemr_etl.etl_ipt_initiation ON cc.patient_id = kenyaemr_etl.etl_ipt_initiation.patient_id
LEFT OUTER JOIN (
select
le.patient_id,
SUBSTRING_INDEX(GROUP_CONCAT(IF(le.lab_test in ('856','1305'),le.test_result,null) ORDER BY le.date_created SEPARATOR '|') 
,'|',-2) AS VL_SEQ,
CASE
 WHEN SUBSTRING_INDEX(SUBSTRING_INDEX(GROUP_CONCAT(IF(le.lab_test in ('856','1305'),le.test_result,null) ORDER BY le.date_created SEPARATOR '|') 
,'|',-2),'|',1)='1302' THEN 'LDL'
 ELSE SUBSTRING_INDEX(SUBSTRING_INDEX(GROUP_CONCAT(IF(le.lab_test in ('856','1305'),le.test_result,null) ORDER BY le.date_created SEPARATOR '|') 
,'|',-2),'|',1) 
END AS second_last_vl_result,
Date_format(SUBSTRING_INDEX(SUBSTRING_INDEX(GROUP_CONCAT(IF(le.lab_test in ('856','1305'),le.date_created,null) ORDER BY le.date_created SEPARATOR '|') 
,'|',-2),'|',1),'%d/%m/%Y') AS second_last_vl_date,
CASE
 WHEN SUBSTRING_INDEX(SUBSTRING_INDEX(GROUP_CONCAT(IF(le.lab_test in ('856','1305'),le.test_result,null) ORDER BY le.date_created SEPARATOR '|') 
,'|',-2),'|',-1)='1302' THEN 'LDL'
 ELSE SUBSTRING_INDEX(SUBSTRING_INDEX(GROUP_CONCAT(IF(le.lab_test in ('856','1305'),le.test_result,null) ORDER BY le.date_created SEPARATOR '|') 
,'|',-2),'|',-1) 
END AS recent_vl_result,
Date_format(SUBSTRING_INDEX(SUBSTRING_INDEX(GROUP_CONCAT(IF(le.lab_test in ('856','1305'),le.date_created,null) ORDER BY le.date_created SEPARATOR '|') 
,'|',-2),'|',-1),'%d/%m/%Y') AS recent_vl_result_date
from kenyaemr_etl.etl_laboratory_extract le
group by le.patient_id ) as le ON cc.patient_id=le.patient_id
group by patient_id
