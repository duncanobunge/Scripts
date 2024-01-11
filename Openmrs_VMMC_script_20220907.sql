use openmrs;
select
   l.county_district AS SubCounty,
   l.postal_code AS MFL_Code,
   l.name,
   pi.identifier,
   CASE
     WHEN MAX(IF(o.concept_id=6527,o.value_coded,NULL))=7449 THEN 'Mobilizer/CHW'
     WHEN MAX(IF(o.concept_id=6527,o.value_coded,NULL))=7450 THEN 'OPD/MCH/HTC'
     ELSE ''
     END AS MainSourceOfVMMCInfo,
--    MAX(IF(o.concept_id in(8283),o.value_numeric,null)) as Consent_Form_Serial_Number,
   CONCAT_WS(" ",pn.given_name,pn.middle_name,pn.family_name) AS ClientFullName,
   p.gender as Sex,
   date_format(p.birthdate,'%d-%m-%Y') as 'DoB',
   date_format(max(date(e.encounter_datetime)),'%d-%m-%Y') as 'CircumDate',
   CASE 
        WHEN MAX(IF(o.concept_id=7776,o.value_coded,NULL))=1066 THEN 'No'
        WHEN MAX(IF(o.concept_id=7776,o.value_coded,NULL))=1065 THEN 'Yes' 
        ELSE ''
        END AS EligibleForTesting,
   CASE
        WHEN MAX(IF(e.encounter_type in(46) and o.concept_id=8155,o.value_coded,NULL))=664 THEN 'Negative'
        WHEN MAX(IF(e.encounter_type in(46) and o.concept_id=8155,o.value_coded,NULL))=703 THEN 'Positive'
        ELSE ''
        END AS HIVTestResults,
   CASE
       WHEN MAX(IF(o.concept_id=7451,o.value_coded,NULL))=1848 THEN 'Negative'
       WHEN MAX(IF(o.concept_id=7451,o.value_coded,NULL))=1847 THEN 'Positive'
       ELSE ''
       END AS HIVSelfReport,
   CASE
       WHEN MAX(IF(o.concept_id=7452,o.value_coded,NULL))=1065 THEN 'Yes'
       WHEN MAX(IF(o.concept_id=7452,o.value_coded,NULL))=1066 THEN 'No'
       ELSE ''
       END AS BleedingDisorder,
    CASE
      WHEN MAX(IF(e.encounter_type=33 AND o.concept_id=8242,o.value_coded,NULL))=1065 THEN 'Yes'
      WHEN MAX(IF(e.encounter_type=33 AND o.concept_id=8242,o.value_coded,NULL))=1066 THEN 'No'
      ELSE ''
      END AS EverSurgicalOperated,
    MAX(IF(e.encounter_type=33 AND o.concept_id=8276,o.value_text,NULL)) as SpecifyOperation, 
	max(IF(e.encounter_type=33 AND o.concept_id in (5085),o.value_text,NULL)) as BP,
    MAX(IF(e.encounter_type=33 AND o.concept_id=5087,o.value_numeric,NULL)) as Pulse,
    MAX(IF(e.encounter_type=33 AND o.concept_id=5089,o.value_numeric,NULL)) as Weight,
    MAX(IF(e.encounter_type=33 AND o.concept_id=5088,o.value_numeric,NULL)) as Temp,
    max(IF(e.encounter_type=33 AND o.concept_id in (8286),o.value_text,NULL)) as IP_BP,
    MAX(IF(e.encounter_type=33 AND o.concept_id=8285,o.value_numeric,NULL)) as IP_Pulse,
    MAX(IF(e.encounter_type=33 AND o.concept_id=8284,o.value_numeric,NULL)) as IP_Temp, 
   CASE
      WHEN MAX(IF(e.encounter_type=33 AND o.concept_id=8245,o.value_coded,NULL))=1065 THEN 'Yes'
      WHEN MAX(IF(e.encounter_type=33 AND o.concept_id=8245,o.value_coded,NULL))=1066 THEN 'No'
      ELSE ''
      END AS InGoodHealth,
   CASE
      WHEN MAX(IF(e.encounter_type=33 AND o.concept_id=8168,o.value_coded,NULL))=1065 THEN 'Yes'
      WHEN MAX(IF(e.encounter_type=33 AND o.concept_id=8168,o.value_coded,NULL))=1066 THEN 'No'
      ELSE ''
      END AS Consented,
   CASE
      WHEN MAX(IF(e.encounter_type=33 AND o.concept_id=8278,o.value_coded,NULL))=89 THEN 'paracetamol'
      WHEN MAX(IF(e.encounter_type=33 AND o.concept_id=8278,o.value_coded,NULL))=436 THEN 'diclofenac'
      ELSE ''
      END AS PreOperativeMedGiven,
   CASE 
      WHEN MAX(IF(o.concept_id=7417,o.value_coded,NULL))=7639 THEN 'Dorsal slit'
      WHEN MAX(IF(o.concept_id=7417,o.value_coded,NULL))=5622 THEN 'Other'
      ELSE ''
      END AS ProcedureType, 
  MAX(IF(o.concept_id=8280,o.value_text,NULL)) AS SpecifyOtherProcedureType,
  CASE
      WHEN MAX(IF(e.encounter_type=33 AND o.concept_id=7422,o.value_coded,NULL))=7432 THEN 'lignocaine'
      WHEN MAX(IF(e.encounter_type=33 AND o.concept_id=7422,o.value_coded,NULL))=1550 THEN 'other drug'
      ELSE ''
      END AS AnesthesiaUsed,
  CASE 
      WHEN MAX(IF(o.concept_id=8250,o.value_coded,NULL))=8249 THEN '1%'
      WHEN MAX(IF(o.concept_id=8250,o.value_coded,NULL))=8248 THEN '2%'
      ELSE ''
      END AS AnesthesiaConcentration,
   mid(min(concat(date(e.encounter_datetime), IF(o.concept_id=7427,o.value_numeric,NULL))), 11)as 'AnesthesiaVolume',
   MAX(IF(o.concept_id=8290,o.value_text,NULL)) AS StartTime,
   MAX(IF(o.concept_id=8291,o.value_text,NULL)) AS EndTime,
   CASE
     WHEN MAX(IF(e.encounter_type=33 AND o.concept_id=7196 ,o.value_coded,NULL))=1066 THEN 'No' 
     WHEN MAX(IF(e.encounter_type=33 AND o.concept_id=7196 ,o.value_coded,NULL))=1065 THEN 'Yes' 
     ELSE ''
     END AS AEDuringSurgery,
    CASE
      WHEN MAX(IF(e.encounter_type=33 AND o.concept_id=7455,o.value_coded,NULL))=1065 THEN 'Yes'
      WHEN MAX(IF(e.encounter_type=33 AND o.concept_id=7455,o.value_coded,NULL))=1066 THEN 'No'
      ELSE ''
      END AS PostOperativeMedGiven,
   MAX(IF(e.encounter_type=33 AND o.concept_id=8251 ,o.value_coded,NULL)) AS SeverityOfAEDuring,
   MAX(IF(o.concept_id IN (8252,8293),o.value_text,NULL)) AS Surgeon,
   MAX(IF(o.concept_id IN(1570,8328),o.value_text,NULL)) AS Assistant,
   date_format(z.PostSurgeryVisitDate,'%d-%m-%Y') as FollowUpVisitDate,
   CASE 
       WHEN z.PostSurgeryVisit=7438 THEN 'Yes'
       ELSE ''
       END AS 'PostSurgeryVisit',
   CASE
       WHEN z.AEPostSurgery=1066 THEN 'No'
       WHEN z.AEPostSurgery=1065 THEN 'Yes'
	   ELSE ''
       END AS 'AEPostSurgery',
	z.SeverityOfAEPost
from encounter e 
INNER JOIN patient_identifier pi ON pi.patient_id = e.patient_id AND pi.voided=0 AND e.voided = 0
INNER JOIN patient vp ON vp.patient_id = e.patient_id AND vp.voided = 0
INNER JOIN person p ON p.person_id = e.patient_id AND p.voided=0
INNER JOIN person_name pn ON pn.person_id = e.patient_id AND pn.voided=0
INNER JOIN location l ON l.location_id = e.location_id
LEFT OUTER JOIN obs o ON o.encounter_id=e.encounter_id AND o.voided=0 
AND o.concept_id IN (8293,8251,7196,7525,1501,7455,1599,7194,7158,1544,7417,7439,6688,6501,6367,7444,7445,7451,7440,7452,1683,5995,8276,8242,
864,7428,7429,7430,7432,7040,1433,5085,5086,5087,5089,5088,1682,7453,7419,7420,1573,7422,7424,7427,8290,8291,1570,8155,8252,8168,6527,8280,1501,7776,8250,8328,8283
,8284,8285,8286,8278,8245)
LEFT OUTER JOIN (SELECT e.patient_id,
       MAX(IF(e.encounter_type=34, DATE(e.encounter_datetime),NULL)) AS PostSurgeryVisitDate,
       max(if(o.concept_id=1501,o.value_coded,null)) as PostSurgeryVisit,
       max(if(e.encounter_type=34 and o.concept_id=8256 ,o.value_coded,null)) as AEPostSurgery,
       max(if(e.encounter_type=34 and o.concept_id=8251 ,o.value_coded,null)) as SeverityOfAEPost
       FROM encounter e
	   left outer join obs o on o.encounter_id=e.encounter_id and o.voided=0 and o.concept_id in (8251,8256,1501)
       where e.encounter_type in (34) and e.voided = 0
	   group by e.patient_id
       )z on z.patient_id = e.patient_id
where e.encounter_type in (33,46,56) and date(e.encounter_datetime) between '2019-10-01' and '2022-08-31' and e.voided=0
group by e.patient_id

-- (33,34,46,56)



