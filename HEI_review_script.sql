USE openmrs;
SELECT
 a.*,
 IF(ppi.identifier_type IN (3),ppi.identifier, NULL) AS HEI_SystemUPN
FROM(
select
 ehe.patient_id,
 IF(pi.identifier_type IN (7,4),pi.identifier, NULL) AS HEINumber,
 r.person_b,
 r.relationship as rlship
FROM kenyaemr_etl.etl_hei_enrollment ehe
INNER JOIN openmrs.relationship r ON ehe.patient_id=r.person_b 
INNER JOIN openmrs.patient_identifier pi ON ehe.patient_id=pi.patient_id
GROUP BY ehe.patient_id
HAVING rlship IN (3))a
INNER JOIN openmrs.patient_identifier ppi ON a.patient_id = ppi.patient_id
group by a.patient_id;
