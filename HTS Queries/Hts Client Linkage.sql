SELECT
        hc.PatientPK,
        hc.SiteCode,
        hc.FacilityName,
        'OpenMRS' AS EMR,
        'UCSF Clinical Kisumu' AS Project,
        hc.HtsNumber,
        MAX(IF(o.concept_id=8156,DATE(o.date_created),NULL)) AS DatePrefferedToBeEnrolled,
        MAX(IF(o.concept_id=8156,o.value_text,NULL)) AS FacilityReferredTo,
        MAX(IF(o.concept_id=8157,o.value_text,NULL)) AS HandedOverTo,
        NULL AS HandedOverToCadre,
        MAX(IF(o.concept_id=8156,o.value_text,NULL)) AS EnrolledFacilityName,
        MAX(IF(o.concept_id=8156,DATE(o.date_created),NULL)) AS ReferralDate,
        MAX(IF(o.concept_id=6742,DATE(o.value_datetime),NULL)) AS DateEnrolled,
        MAX(IF(o.concept_id=6455,o.value_text,NULL)) AS ReportedCCCNumber,
        NULL AS ReportedStartARTDate
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
    LEFT OUTER JOIN obs o ON o.person_id = pt.patient_id AND o.voided=0 AND o.concept_id IN (8157,8156,6742,6455)
    GROUP BY pt.patient_id
    HAVING DatePrefferedToBeEnrolled IS NOT NULL;