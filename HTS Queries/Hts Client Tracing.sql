SELECT
        hc.FacilityName,
        hc.SiteCode,
        hc.PatientPK,
        hc.HtsNumber,
        'OpenMRS' AS EMR,
        'UCSF Clinical Kisumu' AS Project,
        MAX(IF(o.concept_id=7563,(CASE o.value_coded WHEN 6230 THEN 'Phone' WHEN 6227 THEN 'Physical' ELSE NULL END),NULL)) AS TracingType,
        MAX(IF(o.concept_id=7563,(CASE o.value_coded WHEN 6230 THEN DATE(obs_datetime) WHEN 6227 THEN DATE(obs_datetime) ELSE NULL END),NULL)) AS TracingDate,
        MAX(IF(o.concept_id=7824,(CASE o.value_coded WHEN 1065 THEN "Contacted and linked" WHEN 1066 THEN "Contacted but not linked" ELSE NULL END),NULL)) AS TracingOutcome
    FROM patient pt
    INNER JOIN (
        SELECT
            pt.patient_id AS PatientPK,
            la.`value_reference` AS SiteCode,
            l.name AS FacilityName,
            MAX(pi.identifier) AS HtsNumber,
            DATE(p.birthdate) AS DOB,
            IF(p.gender = 'M', 'Male',IF(p.gender = 'F','Female',NULL)) AS Gender
        FROM patient pt
        LEFT OUTER JOIN encounter e ON pt.patient_id = e.patient_id AND e.voided = 0
        INNER JOIN patient_identifier `pi` ON pi.patient_id = pt.patient_id AND pi.identifier_type IN (18,1) AND pi.voided=0
        INNER JOIN person p ON p.person_id = pt.patient_id
        INNER JOIN location l ON pi.location_id = l.location_id AND l.location_id IN (2,40,265,238,217,215,237,216,42,261,41,258,233,267,44,228,43)
        INNER JOIN location_attribute la ON l.location_id = la.location_id AND la.attribute_type_id = 1
        GROUP BY pt.patient_id
        HAVING DOB IS NOT NULL AND Gender IS NOT NULL
    ) hc ON pt.patient_id = hc.PatientPK
    LEFT JOIN encounter e ON pt.patient_id = e.patient_id AND e.encounter_type IN (44,45,46,47,48,49,53)
    LEFT OUTER JOIN obs o ON o.person_id = e.patient_id AND o.concept_id IN (7563,7824)
    GROUP BY pt.patient_id
    HAVING TracingType IS NOT NULL;