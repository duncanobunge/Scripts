-- This report line lists all patients who are new on treatment.
-- PARAMETERS:
-- 2 For location id 2 for lumumba
-- :endDate for end of reporting period e.g '2016-06-30' It must be a date

SELECT 
	MAX(IF(pi.identifier_type=3,pi.identifier,NULL)) AS FACES_ID,
	MIN(IF(pi.identifier_type=9,pi.identifier,NULL)) AS UPN,
    CONCAT_WS(' ',pn.given_name, pn.middle_name, pn.family_name) AS PatientName,
    	p.gender, 
    	DATE(p.birthdate) AS DoB,
DATEDIFF(DATE(:endDate),p.birthdate) DIV 365.25 AS Age,
CASE  
WHEN (DATEDIFF(:endDate,p.birthdate)DIV 365.25)<1 THEN '<1 Yr' 
WHEN (DATEDIFF(:endDate,p.birthdate)DIV 365.25) BETWEEN 1 AND 4.99 THEN '1-4 Yrs'
WHEN (DATEDIFF(:endDate,p.birthdate)DIV 365.25) BETWEEN 5 AND 9.99 THEN '5-9 Yrs' 
WHEN (DATEDIFF(:endDate,p.birthdate)DIV 365.25) BETWEEN 10 AND 14.99 THEN '10-14 Yrs' 
WHEN (DATEDIFF(:endDate,p.birthdate)DIV 365.25) BETWEEN 15 AND 19.99 THEN '15-19 Yrs' 
WHEN (DATEDIFF(:endDate,p.birthdate)DIV 365.25) BETWEEN 20 AND 24.99 THEN '20-24 Yrs' 
WHEN (DATEDIFF(:endDate,p.birthdate)DIV 365.25) BETWEEN 25 AND 29.99 THEN '25-29 Yrs' 
WHEN (DATEDIFF(:endDate,p.birthdate)DIV 365.25) BETWEEN 30 AND 34.99 THEN '30-34 Yrs' 
WHEN (DATEDIFF(:endDate,p.birthdate)DIV 365.25) BETWEEN 35 AND 39.99 THEN '35-39 Yrs' 
WHEN (DATEDIFF(:endDate,p.birthdate)DIV 365.25) BETWEEN 40 AND 44.99 THEN '40-44 Yrs' 
WHEN (DATEDIFF(:endDate,p.birthdate)DIV 365.25) BETWEEN 45 AND 49.99 THEN '45-49 Yrs' 
WHEN (DATEDIFF(:endDate,p.birthdate)DIV 365.25) >=50 THEN '50+ Yrs' 
ELSE NULL
END AS Age_Group,
First_Encounter,Last_Encounter, 
lt.LastTCADate,
IF(Missed_Appointment_Days<1,'N/A',Missed_Appointment_Days) AS Missed_Appointment_Days,
Days_to_NextTCA AS Days_to_Next_DrugPick,
Months_to_NextTCA AS Months_to_Next_DrugPick,
-- on_arv,
CurreRegimen,
CurreRegimenDate,
Date_Started_ART,
-- on_PPCT,
DFC_CategoryModel,
ClientStatus,
DFC_CategoryToday  
FROM encounter e
INNER JOIN patient_identifier `pi` ON pi.patient_id = e.patient_id AND pi.identifier_type IN(3,9) 
AND pi.voided=0 AND e.voided=0 AND  e.encounter_type IN(21,22,14,42,550,85,86) AND e.location_id = :location  
AND DATE(e.encounter_datetime) <= DATE(:endDate) 
INNER JOIN person p ON p.person_id = e.patient_id AND p.voided = 0
INNER JOIN person_name pn ON e.patient_id=pn.person_id AND pn.voided = 0
INNER  JOIN
(
	SELECT
		e.patient_id AS patient_id,
    MIN(DATE(e.encounter_datetime)) AS First_Encounter,
	MAX(DATE(e.encounter_datetime)) AS Last_Encounter, 
	DATE(mid(max(concat(e.encounter_datetime,date(o.value_datetime))),20)) AS LastTCADate,
    DATEDIFF(DATE(:endDate),DATE(mid(max(concat(e.encounter_datetime,date(o.value_datetime))),20))) AS Missed_Appointment_Days,
    DATEDIFF(DATE(mid(max(concat(e.encounter_datetime,date(if(o.concept_id IN (1938,1582,5096,7628),o.value_datetime,NULL)))),20)),MAX(DATE(if(o.concept_id IN (1938,1582,5096,7628),e.encounter_datetime,null)))) AS Days_to_NextTCA,
    CASE 
    WHEN IF(o.concept_id IN (1938,1582,5096,7628),DATEDIFF(DATE(mid(max(concat(e.encounter_datetime,date(if(o.concept_id IN (1938,1582,5096,7628),o.value_datetime,NULL)))),20)),MAX(DATE(if(o.concept_id IN (1938,1582,5096,7628),e.encounter_datetime,null)))),NULL)<77 THEN '<3 Months' 
    WHEN IF(o.concept_id IN (1938,1582,5096,7628),DATEDIFF(DATE(mid(max(concat(e.encounter_datetime,date(if(o.concept_id IN (1938,1582,5096,7628),o.value_datetime,NULL)))),20)),MAX(DATE(if(o.concept_id IN (1938,1582,5096,7628),e.encounter_datetime,null)))),NULL) BETWEEN 77 AND 175 THEN '3-5 Months' 
    WHEN IF(o.concept_id IN (1938,1582,5096,7628),DATEDIFF(DATE(mid(max(concat(e.encounter_datetime,date(if(o.concept_id IN (1938,1582,5096,7628),o.value_datetime,NULL)))),20)),MAX(DATE(if(o.concept_id IN (1938,1582,5096,7628),e.encounter_datetime,null)))),NULL)>175 THEN '6+ Months' 
    END AS Months_to_NextTCA  
    FROM encounter e 
	INNER JOIN obs o ON e.encounter_id = o.encounter_id AND e.encounter_type IN (21,22,14,42,550,85,86) 
    AND DATE(encounter_datetime) <=DATE(:endDate) AND e.voided=0 
	AND o.concept_id IN (1938,1582,5096,7469,7628) AND o.voided=0 AND o.value_datetime IS NOT NULL 
	GROUP BY patient_id 
    HAVING Missed_Appointment_Days < 31 
) AS lt ON e.patient_id=lt.patient_id 
INNER JOIN (
SELECT e.patient_id,
MAX(IF(o.concept_id=1571 ,1,0)) AS on_arv,
MID(MAX(CONCAT(e.encounter_datetime,IF(o.concept_id IN (1571),cn.name,NULL))),20) AS CurreRegimen,
MID(MAX(CONCAT(e.encounter_datetime,IF(o.concept_id IN (1571),date(o.obs_datetime),NULL))),20) AS CurreRegimenDate 
FROM encounter e 
INNER JOIN obs o ON e.encounter_id=o.encounter_id AND e.voided=0 AND o.voided=0 
AND o.concept_id in(1571) AND DATE(e.encounter_datetime)<=DATE(:endDate) 
INNER JOIN concept_name cn ON cn.concept_id = o.value_coded 
group by e.patient_id 
)reg on e.patient_id=reg.patient_id 
INNER JOIN(
  SELECT  
  e.patient_id,
COALESCE(COALESCE(MIN(IF(o.concept_id IN (6746,6739),DATE(o.value_datetime),NULL)),
		MIN(IF(o.concept_id IN (1255) AND o.value_coded=1256,DATE(o.obs_datetime),NULL))),
		COALESCE(MID(MIN(CONCAT(e.encounter_datetime,IF(o.concept_id IN(1592,6506) AND o.value_coded IN(1407,6197) ,DATE(o.obs_datetime),NULL))),20),
		MID(MIN(CONCAT(e.encounter_datetime,IF(o.concept_id=1571 ,DATE(o.obs_datetime),NULL))),20))
		) AS  Date_Started_ART, 
	MAX(IF(o.concept_id IN(1409,1592,1572) AND o.value_coded=1405 ,1,0)) AS on_PPCT 
    FROM encounter e 
INNER JOIN obs o ON o.encounter_id=e.encounter_id AND o.voided=0 AND o.concept_id IN (1592,1572,1409,6746,6739,1571,1255,1592,6506) 
AND e.voided=0 AND DATE(e.encounter_datetime) <= DATE(:endDate) 
group by e.patient_id  
) art ON e.patient_id=art.patient_id 
LEFT OUTER JOIN (
SELECT 
e.patient_id,
MID(MAX(CONCAT(e.encounter_datetime,IF(o.concept_id=8402,cn.name,NULL))),20)AS DFC_CategoryModel,
MID(MAX(CONCAT(e.encounter_datetime,IF(o.concept_id in(8215,8216),cn.name,NULL))),20)AS ClientStatus,
MID(MAX(CONCAT(e.encounter_datetime,IF(o.concept_id=8210,cn.name,NULL))),20)AS DFC_CategoryToday,
MID(MAX(CONCAT(e.encounter_datetime,DATE(e.encounter_datetime))),20)AS LastEncounterDate
FROM
encounter e 
INNER JOIN obs o on o.encounter_id = e.encounter_id and e.voided = 0 
and o.concept_id in (6742,1353,6746,6739,8402,8215,8216,7067,8387,8210) AND e.voided=0 AND o.voided=0 
AND e.encounter_type in (1,2,3,4,21,22,42,85,86,550) 
AND DATE(e.encounter_datetime) <= DATE(:endDate) AND e.location_id = :location
LEFT OUTER JOIN concept_name cn ON cn.concept_id=o.value_coded AND cn.concept_name_type='FULLY_SPECIFIED' 
group by e.patient_id
having DFC_CategoryToday is not null 
)stb ON e.patient_id=stb.patient_id

WHERE e.patient_id NOT IN(
  SELECT
         fx.patient_id from
		(
     SELECT e.patient_id,
        max(date(e.encounter_datetime)) AS Last_Enc,
        DiscontinuationDate
		FROM encounter e 
		INNER JOIN( 
        SELECT e.patient_id,
        date(MAX(e.encounter_datetime)) as DiscontinuationDate
		FROM encounter e INNER JOIN obs o ON e.encounter_id=o.encounter_id and e.voided=0 and o.voided=0 
        AND e.encounter_type in(6)
        AND date(e.encounter_datetime)<=DATE(:endDate) 
        group by e.patient_id
        )disc ON e.patient_id=disc.patient_id 
        where e.voided=0 
        AND date(e.encounter_datetime)<=DATE(:endDate) and e.encounter_type IN (21,22,14,42,550,85,86) 
        group by e.patient_id 
        HAVING DiscontinuationDate>=Last_Enc 
	)fx
 ) 
 AND ((Date_Started_ART IS NOT NULL AND Date_Started_ART <= DATE(:endDate)) OR on_arv = 1) 
GROUP BY e.patient_id 
HAVING FACES_ID NOT IN('00000KTU-4','00000KLM-0') 
;