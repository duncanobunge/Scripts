SELECT
        hc.FacilityName,
        hc.SiteCode,
        hc.PatientPK,
        hc.HtsNumber,
        'OpenMRS' AS EMR,
        'UCSF Clinical Kisumu' AS Project,
        e.encounter_id AS EncounterId,
        DATE(e.encounter_datetime) AS TestDate,
        MAX(IF(o.concept_id=7136,(CASE o.value_coded WHEN 1065 THEN "Yes" WHEN 1066 THEN "No" ELSE NULL END),NULL)) AS EverTestedForHiv,
        MAX(IF(o.concept_id=7658,(CASE o.value_coded WHEN 7659 THEN 3 WHEN 7660 THEN 12 WHEN 7661 THEN 13 WHEN 1729 THEN NULL END),NULL)) AS MonthsSinceLastTest,
        MAX(IF(o.concept_id=8138,(CASE o.value_coded WHEN 8137 THEN "Individual" WHEN 1756 THEN "Couple" ELSE NULL END),NULL)) AS ClientTestedAs,
        MAX(IF(o.concept_id=8174,(
           CASE o.value_coded
               WHEN 1357 THEN "OPD"
               WHEN 8170 THEN "IPD"
               WHEN 1354 THEN "VCT"
               WHEN 8172 THEN "MCH"
               WHEN 8175 THEN "TB Clinic"
               WHEN 8173 THEN "PNS"
               WHEN 7656 THEN "Family Testing"
               WHEN 8171 THEN "VMMC"
               ELSE NULL
               END ), NULL))AS EntryPoint,
        MAX(IF(o.concept_id=8145,(
          CASE o.value_coded
              WHEN 8139 THEN "HP/PITC"
              WHEN 8140 THEN "Non Provider Initiated Testing"
              WHEN 8141 THEN "Integrated VCT Center"
              WHEN 8142 THEN "Stand Alone VCT Center"
              WHEN 8143 THEN "Home Based Testing"
              WHEN 8144 THEN "Mobile Outreach HTS"
              WHEN 7629 THEN "HTS for Non-Patient[NP]"
          ELSE NULL
          END ),NULL)) AS TestStrategy,
        MAX(IF(t.test_1_result IS NOT NULL, t.test_1_result, NULL)) AS TestResult1,
        MAX(IF(t.test_2_result IS NOT NULL, t.test_2_result, NULL)) AS TestResult2,
        MAX(IF(o.concept_id=8155,(CASE o.value_coded WHEN 703 THEN "Positive" WHEN 664 THEN "Negative" WHEN 7864 THEN "Inconclusive" ELSE NULL END),NULL)) AS FinalTestResult,
        MAX(IF(o.concept_id=7936,(CASE o.value_coded WHEN 1065 THEN "Yes" WHEN 1066 THEN "No" ELSE NULL END),NULL)) AS PatientGivenResult,
        MAX(IF(o.concept_id=7791,cn.name,NULL)) AS TBScreening,
        MAX(IF(o.concept_id=7937,(CASE o.value_coded WHEN 1065 THEN "Yes" WHEN 1066 THEN "No" ELSE NULL END),NULL)) AS ClientSelfTested,
        MAX(IF(o.concept_id=6096,(CASE o.value_coded WHEN 1065 THEN "Yes" WHEN 1066 THEN "No" ELSE NULL END),NULL)) AS CoupleDiscordant,
        IF(e.encounter_type = 46,"Initial",IF(e.encounter_type = 47,"Repeat",NULL)) AS TestType,
        MAX(IF(o.concept_id=8168,(CASE o.value_coded WHEN 1065 THEN "Yes" WHEN 1066 THEN "No" ELSE "" END),NULL)) AS Consent
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
    ) hc ON pt.patient_id = hc.PatientPK AND SiteCode = hc.SiteCode
    INNER JOIN visit v ON pt.patient_id = v.patient_id AND v.voided = 0
    LEFT JOIN encounter e ON pt.patient_id = e.patient_id AND e.encounter_type IN (46,47)
    JOIN person p ON p.person_id = pt.patient_id
    INNER JOIN (
         SELECT
                   o.person_id,
                   o.encounter_id,
                   o.obs_group_id,
                   MAX(IF(o.concept_id=1040, (CASE o.value_coded WHEN 703 THEN "Positive" WHEN 664 THEN "Negative" WHEN 1304 THEN "Invalid"  ELSE NULL END),NULL)) AS test_1_result ,
                   MAX(IF(o.concept_id=1326, (CASE o.value_coded WHEN 703 THEN "Positive" WHEN 664 THEN "Negative" WHEN 1175 THEN "N/A"  ELSE NULL END),NULL)) AS test_2_result
         FROM obs o
         INNER JOIN encounter e ON e.encounter_id = o.encounter_id
         WHERE o.concept_id IN (1040, 1326)
         GROUP BY e.encounter_id, o.obs_group_id
    ) t ON e.encounter_id = t.encounter_id
    LEFT OUTER JOIN obs o ON o.person_id = pt.patient_id AND o.voided=0 AND o.concept_id IN (7136,7658,8138,8174,8145,8155,7936,7937,6096,8168,7791)
    INNER JOIN concept_name cn ON cn.concept_id = o.value_coded
    GROUP BY pt.patient_id, TestType;