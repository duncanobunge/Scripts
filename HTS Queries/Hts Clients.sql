SELECT
        pt.patient_id AS PatientPK,
        la.`value_reference` AS SiteCode,
        l.name AS FacilityName,
        'OpenMRS' AS EMR,
        'UCSF Clinical Kisumu' AS Project,
        MAX(pi.identifier) AS HtsNumber,
        DATE(p.birthdate) AS DOB,
        IF(p.gender = 'M', 'Male',IF(p.gender = 'F','Female',NULL)) AS Gender,
        MAX(IF(o.concept_id = 1054,cn.name,NULL)) AS MaritalStatus,
        MAX(IF(o.concept_id = 7766,IF(cn.name = 'Gen Pop','General Population',IF(cn.name = 'Key Pop','Key Population',NULL)),NULL)) AS PopulationType,
        MAX(IF(o.concept_id = 7771,cn.name,NULL)) AS KeyPopulationType,
        MAX(IF(o.concept_id = 7923,cn.name,NULL)) AS PatientDisabled,
        pa.county_district AS County,
        pa.address6 AS SubCounty,
        pa.address5 AS Ward
    FROM patient pt
    LEFT OUTER JOIN person_address pa ON pt.patient_id = pa.person_id AND pt.voided = 0 AND pa.voided = 0
    LEFT OUTER JOIN encounter e ON pt.patient_id = e.patient_id AND e.voided = 0
    INNER JOIN patient_identifier `pi` ON pi.patient_id = pt.patient_id AND pi.identifier_type IN (18,1) AND pi.voided=0
    INNER JOIN person p ON p.person_id = pt.patient_id
    INNER JOIN location l ON pi.location_id = l.location_id AND l.location_id IN (2,40,265,238,217,215,237,216,42,261,41,258,233,267,44,228,43)
    INNER JOIN location_attribute la ON l.location_id = la.location_id AND la.attribute_type_id = 1
    LEFT OUTER JOIN obs o ON o.person_id = pt.patient_id AND o.voided=0 AND o.concept_id IN (1054,7766,7771,7923)
    LEFT OUTER JOIN concept_name cn ON cn.concept_id = o.value_coded
    GROUP BY pt.patient_id
    HAVING DOB IS NOT NULL AND Gender IS NOT NULL;