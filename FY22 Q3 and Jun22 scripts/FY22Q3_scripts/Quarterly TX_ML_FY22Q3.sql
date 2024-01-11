use openmrs;
set @reportDate='2023-06-30';
set @startDate ='2023-03-31';
set @endDate ='2023-06-30';

select UPN as PatientID,dob,age_last_visit as AgeAtVisit,gender,art_start_date as StartARTDate,tx_ml,last_visit as LastVisit,
case when tx_ml="died" then date(tx_ml_date) else last_tca end as outcome_date from( 
 select fup.visit_date,fup.patient_id, min(e.visit_date) as enroll_date,
max(fup.visit_date) as latest_vis_date,
mid(max(concat(fup.visit_date,fup.next_appointment_date)),11) as latest_tca,
max(d.visit_date) as date_discontinued,
if(max(tx_disc.visit_date)>=max(fup.visit_date),max(tx_disc.visit_date),'') as tx_ml_date,
case
when max(tx_disc.visit_date)>=max(fup.visit_date) then mid(max(concat(tx_disc.visit_date,tx_disc.discontinuation_reason)),20)
when datediff(date(mid(max(concat(fup.visit_date,fup.next_appointment_date)),11)),date(@reportDate)) <90 then 'LTFU_<3'
when datediff(date(mid(max(concat(fup.visit_date,fup.next_appointment_date)),11)),date(@reportDate)) >=90 then 'LTFU_>3'
	end as tx_ml,
tca.last_visit,
tca.last_tca,
d.patient_id as disc_patient,
de.patient_id as started_on_drugs,
art.art_start_date,
p.dob,
round(datediff(max(fup.visit_date),p.dob)/365,0) as age_last_visit,
p.gender as gender,
p.unique_patient_no as UPN
from kenyaemr_etl.etl_patient_hiv_followup fup
join kenyaemr_etl.etl_patient_demographics p on p.patient_id=fup.patient_id
join kenyaemr_etl.etl_hiv_enrollment e on fup.patient_id=e.patient_id
left outer join kenyaemr_etl.etl_drug_event de on e.patient_id = de.patient_id and de.program='HIV' 
and date(date_started) <= date(@reportDate)
left join
(SELECT patient_id,min(date_started) as art_start_date
FROM kenyaemr_etl.etl_drug_event 
group by patient_id) art on art.patient_id = fup.patient_id

left  JOIN
(select patient_id, visit_date,discontinuation_reason from kenyaemr_etl.etl_patient_program_discontinuation
 where date(visit_date) <= date(@reportDate) and program_name='HIV'
group by patient_id
) d on d.patient_id = fup.patient_id 

left join (select patient_id,
max(visit_date) as last_visit,
mid(max(concat(visit_date,next_appointment_date)),11) as last_tca
from kenyaemr_etl.etl_patient_hiv_followup
where visit_date <= date(@reportDate)
group by patient_id
)tca on tca.patient_id=fup.patient_id

left  JOIN
(select patient_id, visit_date,discontinuation_reason from kenyaemr_etl.etl_patient_program_discontinuation
 where date(visit_date) <= date(@reportDate) and program_name='HIV'
group by patient_id
) tx_disc on tx_disc.patient_id = fup.patient_id

where fup.visit_date <= date('2022-03-31')
group by patient_id
 having (started_on_drugs is not null and started_on_drugs <> "") and 
 (((disc_patient is null and date_add(date(latest_tca), interval 30 DAY)  >= date('2022-03-31')) or 
 (date(latest_tca) > date(date_discontinued) and date(latest_vis_date)> date(date_discontinued) 
and date_add(date(latest_tca), interval 30 DAY)  >= date(@reportDate) ))
          ) 
        ) t 
  where t.patient_id NOT IN      
        (
     
select patient_id from( 
 select fup.visit_date,fup.patient_id, min(e.visit_date) as enroll_date,
max(fup.visit_date) as latest_vis_date,
mid(max(concat(fup.visit_date,fup.next_appointment_date)),11) as latest_tca,
max(d.visit_date) as date_discontinued,
d.patient_id as disc_patient,
de.patient_id as started_on_drugs,
art.art_start_date,
p.dob as dob,
p.gender as gender,
p.unique_patient_no as UPN
from kenyaemr_etl.etl_patient_hiv_followup fup
join kenyaemr_etl.etl_patient_demographics p on p.patient_id=fup.patient_id
join kenyaemr_etl.etl_hiv_enrollment e on fup.patient_id=e.patient_id
left outer join kenyaemr_etl.etl_drug_event de on e.patient_id = de.patient_id and de.program='HIV' 
and date(date_started) <= date(@reportDate)
left join
(SELECT patient_id,min(date_started) as art_start_date
FROM kenyaemr_etl.etl_drug_event 
group by patient_id) art on art.patient_id = fup.patient_id
left  JOIN
(select patient_id, visit_date,discontinuation_reason from kenyaemr_etl.etl_patient_program_discontinuation
 where date(visit_date) <= date(@reportDate) and program_name='HIV'
group by patient_id
) d on d.patient_id = fup.patient_id 
where fup.visit_date <= date(@reportDate)
group by patient_id
 having (started_on_drugs is not null and started_on_drugs <> "") and 
 (((disc_patient is null and date_add(date(latest_tca), interval 30 DAY)  >= date(@reportDate)) or 
 (date(latest_tca) > date(date_discontinued) and date(latest_vis_date)> date(date_discontinued) 
and date_add(date(latest_tca), interval 30 DAY)  >= date(@reportDate) ))
          ) 
        ) p)

        union 
        select UPN as PatientID,dob,age_last_visit as AgeAtVisit,gender,art_start_date as StartARTDate,tx_ml,last_visit as LastVisit,
        case when tx_ml="died" then date(tx_ml_date) else last_tca end as outcome_date from( 
 select fup.visit_date,fup.patient_id, min(e.visit_date) as enroll_date,
max(fup.visit_date) as latest_vis_date,
mid(max(concat(fup.visit_date,fup.next_appointment_date)),11) as latest_tca,
max(d.visit_date) as date_discontinued,
if(max(tx_disc.visit_date)>=max(fup.visit_date),max(tx_disc.visit_date),'') as tx_ml_date,
case
when max(tx_disc.visit_date)>=max(fup.visit_date) then mid(max(concat(tx_disc.visit_date,tx_disc.discontinuation_reason)),20)
when datediff(date(mid(max(concat(fup.visit_date,fup.next_appointment_date)),11)),date(@reportDate)) <90 then 'LTFU_<3'
when datediff(date(mid(max(concat(fup.visit_date,fup.next_appointment_date)),11)),date(@reportDate)) >=90 then 'LTFU_>3'
	end as tx_ml,
tca.last_visit,
tca.last_tca,
d.patient_id as disc_patient,
de.patient_id as started_on_drugs,
art.art_start_date,
p.dob,
round(datediff(max(fup.visit_date),p.dob)/365,0) as age_last_visit,
p.gender as gender,
p.unique_patient_no as UPN
from kenyaemr_etl.etl_patient_hiv_followup fup
join kenyaemr_etl.etl_patient_demographics p on p.patient_id=fup.patient_id
join kenyaemr_etl.etl_hiv_enrollment e on fup.patient_id=e.patient_id
left outer join kenyaemr_etl.etl_drug_event de on e.patient_id = de.patient_id and de.program='HIV' 
and date(date_started) <= date(@reportDate) and date(date_started) >= date('2022-01-01')
left join
(SELECT patient_id,min(date_started) as art_start_date
FROM kenyaemr_etl.etl_drug_event 
group by patient_id) art on art.patient_id = fup.patient_id

left  JOIN
(select patient_id, visit_date,discontinuation_reason from kenyaemr_etl.etl_patient_program_discontinuation
 where date(visit_date) <= date(@reportDate) and program_name='HIV'
group by patient_id
) d on d.patient_id = fup.patient_id 

left join (select patient_id,
max(visit_date) as last_visit,
mid(max(concat(visit_date,next_appointment_date)),11) as last_tca
from kenyaemr_etl.etl_patient_hiv_followup
where visit_date <= date(@reportDate)
group by patient_id
)tca on tca.patient_id=fup.patient_id

left  JOIN
(select patient_id, visit_date,discontinuation_reason from kenyaemr_etl.etl_patient_program_discontinuation
 where date(visit_date) <= date(@reportDate) and program_name='HIV'
group by patient_id
) tx_disc on tx_disc.patient_id = fup.patient_id

where fup.visit_date <= date(@reportDate)
group by patient_id
 having (art_start_date>=date('2023-01-01') and art_start_date<=date(@reportDate))
        ) t 
  where t.patient_id NOT IN      
        (
     
select patient_id from( 
 select fup.visit_date,fup.patient_id, min(e.visit_date) as enroll_date,
max(fup.visit_date) as latest_vis_date,
mid(max(concat(fup.visit_date,fup.next_appointment_date)),11) as latest_tca,
max(d.visit_date) as date_discontinued,
d.patient_id as disc_patient,
de.patient_id as started_on_drugs,
art.art_start_date,
p.dob as dob,
p.gender as gender,
p.unique_patient_no as UPN
from kenyaemr_etl.etl_patient_hiv_followup fup
join kenyaemr_etl.etl_patient_demographics p on p.patient_id=fup.patient_id
join kenyaemr_etl.etl_hiv_enrollment e on fup.patient_id=e.patient_id
left outer join kenyaemr_etl.etl_drug_event de on e.patient_id = de.patient_id and de.program='HIV' 
and date(date_started) <= date(@reportDate)
left join
(SELECT patient_id,min(date_started) as art_start_date
FROM kenyaemr_etl.etl_drug_event 
group by patient_id) art on art.patient_id = fup.patient_id
left  JOIN
(select patient_id, visit_date,discontinuation_reason from kenyaemr_etl.etl_patient_program_discontinuation
 where date(visit_date) <= date(@reportDate) and program_name='HIV'
group by patient_id
) d on d.patient_id = fup.patient_id 
where fup.visit_date <= date(@reportDate)
group by patient_id
 having (started_on_drugs is not null and started_on_drugs <> "") and 
 (((disc_patient is null and date_add(date(latest_tca), interval 30 DAY)  >= date(@reportDate)) or 
 (date(latest_tca) > date(date_discontinued) and date(latest_vis_date)> date(date_discontinued) 
and date_add(date(latest_tca), interval 30 DAY)  >= date(@reportDate) ))
          ) 
        ) p)
        