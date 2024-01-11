-- INSTRUCTIONS-----
-- DEFINITION: TX_RTT: This is a quarterly indicator and the query should output a list list of those patient who experienced an interruption before 
-- the reporting period, came back to treatment in the reporting period and were able to stay in treatment up to the end of the reporting period.
-- Replace :startDate and :endDate with the correct reporting period Dates eg replace :startDate with '2020-10-01' and :endDate with '2020-12-31'

use openmrs;

SET @Start_Date='2017-01-01' ;
SET @End_Date = '2021-12-31' ;

SELECT
    
	 TX_RTT.patient_id, 
	 TX_RTT.UPN,
	 edfi.siteCode,
	 edfi.FacilityName as SiteName,
	 pa.county_district as County,
	 pa.state_province as Sub_county,
	 pa.address6 as Location,
	 pa.address5 as Sub_location,
	 pa.city_village as Village,
	 pa.address2 as Landmark,
	 TX_RTT.gender As Sex,
	 TX_RTT.DoB,
	 DATE_FORMAT(FROM_DAYS(DATEDIFF(max(date(ephf.visit_date)),epd.DOB)), '%Y')+0 AS AgeatLastVisit,
     ehe.date_confirmed_hiv_positive,
     COALESCE(ehe.date_first_enrolled_in_care, ecic.enroll_date) as DateEnrolledinHIVCare,
	 TX_RTT.ART_Start_Date,
	 mid(min(concat(dr.date_started, dr.regimen_name)), 11)as StartARTRegimen,
	 mid(min(concat(dr.date_started, dr.regimen_line)), 11)as StartARTRegimenLine,
	 max(dr.date_started) as CurrentARTStartDate,
	 mid(max(concat(dr.date_started, dr.regimen_name)), 11) as CurrentARTRegimen,
	 mid(max(concat(dr.date_started, dr.regimen_line)), 11) as CurrentARTRegimenLine,
	 GROUP_CONCAT(ephf.who_stage ORDER BY ephf.visit_date SEPARATOR '|') as WHOStageSeq,
	 GROUP_CONCAT(IF(ephf.who_stage,DATE(ephf.visit_date),null) ORDER BY ephf.visit_date SEPARATOR '|') as WHOStageDateSeq,
	 GROUP_CONCAT(IF(ele.lab_test IN (856,1305),ele.test_result,null) ORDER BY ele.visit_date SEPARATOR '|') as VLResultSeq,
	 GROUP_CONCAT(IF(ele.lab_test IN (856,1305),DATE(ele.visit_date),null) ORDER BY ele.visit_date SEPARATOR '|') as VLDateSeq,
	 GROUP_CONCAT(IF(ele.lab_test IN (856,1305),ele.order_reason,null) ORDER BY ele.visit_date SEPARATOR '|') as VLOrderReasonSeq,
	 GROUP_CONCAT(IF(ele.lab_test IN (5497),ele.test_result,null) ORDER BY ele.visit_date SEPARATOR '|') as CD4CountSeq,
	 GROUP_CONCAT(IF(ele.lab_test IN (5497),DATE(ele.visit_date),null) ORDER BY ele.visit_date SEPARATOR '|') as CD4CountDateSeq,
	 mid(max(concat(ephf.visit_date,ephf.weight)), 11) as RecentWeight,
	 mid(max(concat(ephf.visit_date,ephf.height)), 11) as RecentHeight,
	 mid(max(concat(ephf.visit_date,ephf.diastolic_pressure)), 11) as RecentDiastolicBP,
	 mid(max(concat(ephf.visit_date,ephf.systolic_pressure)), 11) as RecentsystolicBP,
	 CASE
        WHEN mid(max(concat(ephf.visit_date,ephf.tb_status)), 11)=1663 THEN 'Completed TB RX'
        WHEN mid(max(concat(ephf.visit_date,ephf.tb_status)), 11)=1662 THEN 'On TB RX'
        WHEN mid(max(concat(ephf.visit_date,ephf.tb_status)), 11)=1661 THEN 'TB Diagnosed'
        WHEN mid(max(concat(ephf.visit_date,ephf.tb_status)), 11)=1660 THEN 'No TB signs'
        WHEN mid(max(concat(ephf.visit_date,ephf.tb_status)), 11)=142177 THEN 'Suspected TB'
        WHEN mid(max(concat(ephf.visit_date,ephf.tb_status)), 11)=160737 THEN 'Not Assessed of TB'
        ELSE 'Missing'
        END as TBScreeningAtLastVisit,
	max(etbe.visit_date) as MostRecentTBEnrollmentDate,
	CASE
		WHEN mid(max(concat(ephf.visit_date,ephf.differentiated_care)), 11)=164942 THEN 'Standard Care'
		WHEN mid(max(concat(ephf.visit_date,ephf.differentiated_care)), 11)=164943 THEN 'Fast Track care'
		WHEN mid(max(concat(ephf.visit_date,ephf.differentiated_care)), 11)=164944 THEN 'Community ART distribution - HCW led'
		WHEN mid(max(concat(ephf.visit_date,ephf.differentiated_care)), 11)=164945 THEN 'Community ART distribution – Peer led'
		WHEN mid(max(concat(ephf.visit_date,ephf.differentiated_care)), 11)=164946 THEN 'Facility ART distribution group'
		END AS 'DCM_model',
	min(ipt.visit_date) as IPTStartdate,   
	CASE 
       WHEN ipto.outcome IN (983) THEN 'WEIGHT CHANGE'
       WHEN ipto.outcome IN (1267) THEN 'COMPLETED'
       WHEN ipto.outcome IN (102) THEN 'Toxicity_Drug'
       WHEN ipto.outcome IN (5622) THEN 'Other'
       WHEN ipto.outcome IN (112141) THEN 'TUBERCULOSIS'
	   WHEN ipto.outcome IN (160034) THEN 'Died'
       ELSE 'missing'
       END as IPTCompletionstatus,
	   max(ipto.visit_date) as IPTOutcomedate,
   CASE 
	   WHEN mid(max(concat(ephf.visit_date,ephf.family_planning_method)), 11)=5279 THEN 'Injectable contraceptives'
	   WHEN mid(max(concat(ephf.visit_date,ephf.family_planning_method)), 11)=5278 THEN 'Diaphragm'
	   WHEN mid(max(concat(ephf.visit_date,ephf.family_planning_method)), 11)=5275 THEN 'Intrauterine device'
	   WHEN mid(max(concat(ephf.visit_date,ephf.family_planning_method)), 11)=5276 THEN 'Female sterilization'
	   WHEN mid(max(concat(ephf.visit_date,ephf.family_planning_method)), 11)=190 THEN 'Condoms'
	   WHEN mid(max(concat(ephf.visit_date,ephf.family_planning_method)), 11)=780 THEN 'Oral contraception'
	   WHEN mid(max(concat(ephf.visit_date,ephf.family_planning_method)), 11)=5277 THEN 'Natural family planning'
	   WHEN mid(max(concat(ephf.visit_date,ephf.family_planning_method)), 11)=159524 THEN 'Sexual abstinence'
	   WHEN mid(max(concat(ephf.visit_date,ephf.family_planning_method)), 11)=78796 THEN 'LEVONORGESTREL'
	   WHEN mid(max(concat(ephf.visit_date,ephf.family_planning_method)), 11)=1472 THEN 'Tubal ligation procedure'
	   WHEN mid(max(concat(ephf.visit_date,ephf.family_planning_method)), 11)=907 THEN 'MEDROXYPROGESTERONE ACETATE'
	   WHEN mid(max(concat(ephf.visit_date,ephf.family_planning_method)), 11)=1489 THEN 'Vasectomy'
	   WHEN mid(max(concat(ephf.visit_date,ephf.family_planning_method)), 11)=1359 THEN 'NORPLANT (IMPLANTABLE CONTRACEPTIVE)'
	   WHEN mid(max(concat(ephf.visit_date,ephf.family_planning_method)), 11)=136452 THEN 'IUD Contraception'
	   WHEN mid(max(concat(ephf.visit_date,ephf.family_planning_method)), 11)=159837 THEN 'Hysterectomy'
	   WHEN mid(max(concat(ephf.visit_date,ephf.family_planning_method)), 11)=160570 THEN 'Emergency contraceptive pills'
	   WHEN mid(max(concat(ephf.visit_date,ephf.family_planning_method)), 11)=136163 THEN 'Lactational amenorrhea'
	   WHEN mid(max(concat(ephf.visit_date,ephf.family_planning_method)), 11)=159589 THEN 'Implantable contraceptive (unspecified type)'
	   WHEN mid(max(concat(ephf.visit_date,ephf.family_planning_method)), 11)=5622 THEN 'Other (specify)'
	   ELSE 'Missing'
	   END AS 'FPMethodatLastVisit',
	CASE 
           WHEN mid(max(concat(ephf.visit_date,ephf.pregnancy_status)),11) IN (1066) THEN 'No'
           WHEN mid(max(concat(ephf.visit_date,ephf.pregnancy_status)),11) IN (1065) THEN 'Yes'
           WHEN mid(max(concat(ephf.visit_date,ephf.pregnancy_status)),11) IN (1067) THEN 'Unknown'
           ELSE 'Missing'
           END AS 'PregnancyStatusatLastVisit',
	CASE 
           WHEN mid(max(concat(ephf.visit_date,ephf.breastfeeding)),11) IN (1066) THEN 'No'
           WHEN mid(max(concat(ephf.visit_date,ephf.breastfeeding)),11) IN (1065) THEN 'Yes'
           WHEN epd.Gender IN('M') THEN 'NA'
           ELSE 'Missing'
           END AS 'BreastFeedingStatusAtLastVisit',
	CASE 
           WHEN mid(max(concat(ephf.visit_date,ephf.wants_pregnancy)),11) IN (1066) THEN 'No'
           WHEN mid(max(concat(ephf.visit_date,ephf.wants_pregnancy)),11) IN (1065) THEN 'Yes'
           WHEN epd.Gender IN('M') THEN 'NA'
           ELSE 'Missing'
           END AS 'Pregnancy intention assessment at last visit',
	
      CASE
		   WHEN mid(max(concat(ephf.visit_date,ephf.stability)), 11)=1 THEN 'Yes'
		   WHEN mid(max(concat(ephf.visit_date,ephf.stability)), 11)=2 THEN 'No'
		   ELSE 'Missing'
		   END as PatientEstablished,

	 CASE
		  WHEN mid(max(concat(eme.visit_date,eme.service_type)),11)=1622 THEN 'ANC'
		  WHEN mid(max(concat(eme.visit_date,eme.service_type)),11)=1623 THEN 'PNC'
		  WHEN mid(max(concat(eme.visit_date,eme.service_type)),11)=164835 THEN 'L&D'
		  END as RecentMCHServiceType,
     Max(eme.visit_date) as MostRecentMCHEnrollmentDate,
     date(eme.first_anc_visit_date) as MostRecentANCVisitEnrollmentDate,
     max(mav.visit_date) as MostRecentANCVisitEncounterDate,
     max(mpv.visit_date) as MostRecentPNCVisitEncounterDate,
     Max(TX_RTT.LastVisit) as LastEncDatePriorITT,
     Max(TX_RTT.PrevTCA) as LastTCAPriorITT,
     Max(date_add(TX_RTT.PrevTCA, interval 31 day)) as ITTAcquisitionDate,
     TX_RTT.LastEncAfterIIT as ReturnDatePostIIT,
     TX_RTT.Next_Appointment AS LastTCAAfterITT,
     ecic.latest_vis_date,
	  GROUP_CONCAT(ecdt.tracing_type ORDER BY ecdt.visit_date SEPARATOR '|') as TracingTypeSeq,
	  GROUP_CONCAT(IF(DATE(ecdt.date_created),DATE(ecdt.visit_date),null) ORDER BY ecdt.visit_date SEPARATOR '|') as TracingDateSeq,
	  GROUP_CONCAT(IF(DATE(ecdt.date_created),ecdt.tracing_outcome,null) ORDER BY ecdt.visit_date SEPARATOR '|') as TracingOutcomeSeq,
	  GROUP_CONCAT(IF(DATE(ecdt.date_created),ecdt.reason_for_missed_appointment,null) ORDER BY ecdt.visit_date SEPARATOR '|') as ReasonForMissedAppointmentSeq,
	  GROUP_CONCAT(IF(ecdt.visit_date ,ecdt.non_coded_missed_appointment_reason,'Missing') ORDER BY ecdt.visit_date SEPARATOR '|') as ReasonForMissedAppointmentNonCodedSeq,
	  -- mid(max(concat(date(ecdt.visit_date),ecdt.reason_for_missed_appointment)),11) as RecentMissedAppointmentReason,
	 --  mid(max(concat(date(ecdt.visit_date),ecdt.non_coded_missed_appointment_reason)),11) as RecentMissedAppointmentNonCodedReason,
      GROUP_CONCAT(ephf.next_appointment_date ORDER BY ephf.visit_date SEPARATOR '|') as TCASeq,
     ecic.latest_tca
FROM(
SELECT en.encounter_id,e.patient_id,
FACES_ID,UPN,Patient_Name,gender,DoB,Age,ART_Start_Date,
MAX(date(e.encounter_datetime)) as LastVisit,
SUBSTRING_INDEX(GROUP_CONCAT(DATE(o.value_datetime) ORDER BY DATE(e.encounter_datetime) DESC,e.date_created DESC SEPARATOR '| '),'|',1) AS  PrevTCA,
tca.TCA as Next_Appointment, 
tca.Last_Enc AS LastEncAfterIIT,
FormName,encounter_date,GivenTCA,Effective_Discontinuation_Date  
FROM encounter e 
INNER JOIN obs o ON e.encounter_id=o.encounter_id AND o.voided=0 and o.concept_id in(5096,162549) 
INNER JOIN encounter_type et ON e.encounter_type=et.encounter_type_id AND et.name IN('HIV Enrollment','HIV Consultation','ART Refill') 
and et.retired=0 
INNER JOIN(
SELECT 
e.patient_id AS patient_id,
    MAX(IF(pit.name in('Unique Patient Number'),pi.identifier,null)) AS UPN,
MAX(IF(pit.name in('Patient Clinic Number'),pi.identifier,null)) AS FACES_ID,
    CONCAT_WS(' ',pn.given_name, pn.middle_name, pn.family_name) AS Patient_Name,
    	p.gender, 
    	DATE(p.birthdate) AS DoB,
DATEDIFF(DATE(@End_Date),p.birthdate) DIV 365.25 AS Age

FROM encounter e
INNER JOIN patient_identifier `pi` ON pi.patient_id = e.patient_id 
INNER JOIN patient_identifier_type pit ON pi.identifier_type=pit.patient_identifier_type_id AND pit.retired=0 and pi.voided=0 
AND pi.voided=0 AND e.voided=0 
AND DATE(e.encounter_datetime) <= DATE(@End_Date) 
INNER JOIN encounter_type et ON e.encounter_type=et.encounter_type_id 
 AND et.name IN('HIV Enrollment','HIV Consultation','ART Refill') 
and et.retired=0 
INNER JOIN person p ON p.person_id = e.patient_id AND p.voided = 0
INNER JOIN person_name pn ON e.patient_id=pn.person_id AND pn.voided = 0 
group by e.patient_id
)pat ON e.patient_id=pat.patient_id
INNER JOIN(
  SELECT  
  e.patient_id,
COALESCE(MIN(IF(o.concept_id in(159599),DATE(o.value_datetime),NULL)),
IF(o.concept_id IN(160540) AND o.value_coded IN(5622,159937,159938,160536,160537,160538,160539,160541,160542,160544,160631,162050,162223,160563),MIN(DATE(e.encounter_datetime)),NULL)
) AS ART_Start_Date

    FROM encounter e 
INNER JOIN obs o ON o.encounter_id=e.encounter_id AND o.voided=0 AND o.concept_id IN (159599,160540) 
AND e.voided=0 
group by e.patient_id  
) art ON e.patient_id=art.patient_id
INNER JOIN (
SELECT e.encounter_id,e.patient_id,
GROUP_CONCAT(f.name SEPARATOR ',') AS FormName,
date(e.encounter_datetime) as encounter_date,
date(o.value_datetime) as GivenTCA
FROM encounter e 
inner join encounter_type et ON e.encounter_type=et.encounter_type_id AND e.voided=0  
AND et.name IN('HIV Enrollment','HIV Consultation','ART Refill') and et.retired=0 
INNER JOIN form f ON e.form_id=f.form_id 
INNER JOIN obs o ON e.encounter_id=o.encounter_id AND o.voided=0 and o.concept_id in(5096,162549) 
WHERE encounter_datetime between date(@Start_Date) and date(@End_Date) 
group by e.patient_id,encounter_date 
order by e.patient_id,e.encounter_id ASC 
) en on  e.patient_id=en.patient_id 
INNER JOIN(
select e.patient_id,max(date(e.encounter_datetime)) as Last_Enc, 
SUBSTRING_INDEX(GROUP_CONCAT(DATE(o.value_datetime) ORDER BY DATE(e.encounter_datetime) DESC,e.date_created DESC SEPARATOR '| '),'|',1) AS  TCA 
FROM encounter e 
INNER JOIN obs o ON e.encounter_id=o.encounter_id and e.voided=0 and o.voided=0 and date(e.encounter_datetime)<=date(@End_Date) 
and o.concept_id in(5096,162549)  
INNER JOIN encounter_type et ON e.encounter_type=et.encounter_type_id 
 AND et.name IN('HIV Enrollment','HIV Consultation','ART Refill') and et.retired=0
group by e.patient_id 
HAVING DATE_ADD(TCA, INTERVAL 31 DAY)>=(@End_Date)
) tca on e.patient_id=tca.patient_id 


LEFT JOIN(
SELECT DISTINCT(e.patient_id) AS patient_id,
MAX(IF(o.concept_id in(161555) AND o.value_coded in(159492),true,NULL)) AS is_TO,
MAX(IF(o.concept_id in(160649),DATE(o.value_datetime),NULL)) AS Date_TO,
MAX(IF(o.concept_id in(164384),DATE(o.value_datetime),NULL)) AS Effective_Discontinuation_Date,
MAX(IF(o.concept_id in(164133),DATE(o.value_datetime),NULL)) AS Date_Discontinuation_Verified,
CASE  
when o.concept_id in(1285) AND o.value_coded=1065 THEN 'Yes'  
when o.concept_id in(1285) AND o.value_coded=1066 THEN 'No' 
else null END AS Transfer_Out_Verified,
MAX(Date(e.encounter_datetime)) AS LastEncounter,
All_LastEncounter
FROM obs o
INNER JOIN 
encounter e ON o.encounter_id=e.encounter_id 
-- AND DATE(e.encounter_datetime)<=DATE(@endDate) 
and e.voided=0 and o.voided=0
AND o.concept_id IN (160649,164384,1285,161555,164133)
INNER JOIN encounter_type et ON e.encounter_type=et.encounter_type_id AND et.name in('HIV Discontinuation')
INNER JOIN (
SELECT e.patient_id AS patient_id,MAX(DATE(e.encounter_datetime)) AS All_LastEncounter 
FROM encounter e 
WHERE 
-- DATE(e.encounter_datetime) <= DATE(@endDate) and 
e.voided=0 
GROUP BY patient_id
) AS enc ON e.patient_id=enc.patient_id
 group by patient_id 
HAVING LastEncounter>=All_LastEncounter  
and is_TO=1 
AND Transfer_Out_Verified="yes" 
AND Effective_Discontinuation_Date<=DATE(@End_Date)
) AS t_o on e.patient_id=t_o.patient_id

WHERE DATE(e.encounter_datetime)<en.encounter_date and 
e.patient_id not in(
  -- EXCLUDE ALL DEATHS      
	SELECT 
       DISTINCT (o.person_id) AS patient_id 
	FROM obs o
	JOIN encounter e ON o.encounter_id=e.encounter_id AND DATE(e.encounter_datetime)<=DATE(@endDate) and e.voided=0 and o.voided=0
	AND o.concept_id IN (1543) AND DATE(o.value_datetime) IS NOT NULL 
)group by en.patient_id,en.encounter_id 
HAVING DATEDIFF(DATE(encounter_date),DATE(PrevTCA))>30 AND date_add(date(Next_Appointment), interval 30 day)>=@End_Date 
AND (Effective_Discontinuation_Date IS NULL OR !(Effective_Discontinuation_Date BETWEEN LastVisit AND LastEncAfterIIT))
)TX_RTT  
INNER JOIN kenyaemr_etl.etl_current_in_care ecic ON TX_RTT.patient_id = ecic.patient_id
INNER JOIN kenyaemr_etl.etl_patient_demographics epd ON TX_RTT.patient_id = epd.patient_id
INNER JOIN kenyaemr_etl.etl_patient_hiv_followup ephf ON TX_RTT.patient_id = ephf.patient_id
INNER JOIN kenyaemr_etl.etl_hiv_enrollment ehe ON TX_RTT.patient_id = ehe.patient_id
LEFT OUTER JOIN kenyaemr_etl.etl_drug_event dr ON TX_RTT.patient_id = dr.patient_id AND dr.program IN ('HIV')
LEFT OUTER JOIN kenyaemr_etl.etl_ipt_initiation ipt ON TX_RTT.patient_id = ipt.patient_id
LEFT OUTER JOIN kenyaemr_etl.etl_ipt_outcome  ipto ON TX_RTT.patient_id = ipto.patient_id
LEFT OUTER JOIN kenyaemr_etl.etl_depression_screening eds ON TX_RTT.patient_id  = eds.patient_id
LEFT OUTER JOIN kenyaemr_etl.etl_alcohol_drug_abuse_screening  adas ON TX_RTT.patient_id=adas.patient_id
LEFT OUTER JOIN kenyaemr_etl.etl_cervical_cancer_screening eccs ON TX_RTT.patient_id=eccs.patient_id
LEFT OUTER JOIN kenyaemr_etl.etl_laboratory_extract ele ON TX_RTT.patient_id=ele.patient_id 
LEFT OUTER JOIN kenyaemr_etl.etl_mch_enrollment eme ON TX_RTT.patient_id= eme.patient_id
LEFT OUTER JOIN kenyaemr_etl.etl_mch_postnatal_visit mpv ON TX_RTT.patient_id=mpv.patient_id
LEFT OUTER JOIN kenyaemr_etl.etl_mch_antenatal_visit mav ON TX_RTT.patient_id=mav.patient_id
LEFT OUTER JOIN kenyaemr_etl.etl_tb_enrollment etbe ON TX_RTT.patient_id=etbe.patient_id
LEFT OUTER JOIN kenyaemr_etl.etl_ccc_defaulter_tracing ecdt ON TX_RTT.patient_id=ecdt.patient_id
LEFT OUTER JOIN person_address pa on ehe.patient_id=pa.person_id
LEFT OUTER JOIN(
			SELECT
				  o.person_id,
				  date(obs_datetime) as RBSTestDate,
				  mid(max(concat(DATE(o.obs_datetime), o.value_numeric)), 11) as RBSTestResult
			FROM openmrs.obs o
			WHERE o.concept_id IN (887,160912)
			GROUP BY o.person_id
) AS g ON TX_RTT.patient_id = g.person_id,
kenyaemr_etl.etl_default_facility_info edfi
GROUP BY TX_RTT.patient_id
HAVING TX_RTT.ART_Start_Date BETWEEN @Start_Date AND @End_Date

