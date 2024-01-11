select (select sitecode from kenyaemr_datatools.default_facility_info) as mfl,(select facilityname from kenyaemr_datatools.default_facility_info) as facility_name, 
UPN as ccc_number,dob as date_of_birth,gender,entry_point as Patient_Source,transferin_date,enroll_date as date_enrolled,art_start_date as Date_initiated_art,who_stage_enrollment,current_regimen,regimen_line as current_regimen_line,current_regimen_date,
latest_vis_date as lastvisit,latest_tca as TCA,art_dispensing_duration,tx_rtt,previousexpected_Date,rttdate,ipt_start_date as ipt_initiation_date,
ipt_outcome_date,ipt_outcome as ipt_status,presumed_tb as presumptive_tb,
date_assessed as date_assessed_stability,
stability as DSD_Stability_Assessment,DSD_Model,viral_load_date,viral_load,urgency,art_status as status,anc_visit_date,anc_visit,ovc_date_enrolled,CPIMS_NO
 from( 
 select fup.visit_date,fup.patient_id, min(e.visit_date) as enroll_date,
 mid(min(concat_ws('',e.visit_date,entry_point)),11) as entry_point,
 mid(min(concat_ws('',e.visit_date,transfer_in_date)),11) as transferin_date,
max(fup.visit_date) as latest_vis_date,
mid(max(concat(fup.visit_date,fup.next_appointment_date)),11) as latest_tca,
case when current_model.stability='Yes' then 'Stable'
when current_model.stability='No' then 'Unstable'
else 'Not Done' end as stability,
current_model.date_assessed,
current_model.model as dsd_model,
max(d.visit_date) as date_discontinued,
who.who_enrollment as who_stage_enrollment,
d.patient_id as disc_patient,
de.patient_id as started_on_drugs,
art.art_start_date,
art1.regimen_name as current_regimen,
art1.regimen_line as regimen_line,
art1.current_regimen_date as current_regimen_date,
p.dob as dob,
case when p.gender='f' then 'Female' 
when p.gender='m' then 'Male'
else '' end as gender,
p.unique_patient_no as UPN,
if(rtt.latest_visit is null,'No','Yes') as tx_rtt,
rtt.latest_visit as rttdate,
rtt.date_missed as previousexpected_Date,
ipt.ipt_start_date,
ipt.ipt_outcome_date,
ipt.ipt_outcome,
tb.presumed_tb,
case when datediff(date(mid(max(concat(fup.visit_date,fup.next_appointment_date)),11)),date(max(fup.visit_date))) <90 then 'b_3'
when datediff(date(mid(max(concat(fup.visit_date,fup.next_appointment_date)),11)),date(max(fup.visit_date))) between 90 and 179 then '3_5'
when datediff(date(mid(max(concat(fup.visit_date,fup.next_appointment_date)),11)),date(max(fup.visit_date)))>179 then 'a_6' end as art_dispensing_duration,
case when max(fup.next_appointment_date)>'2022-06-30' then 'Active'
when max(fup.next_appointment_date)<='2022-06-30' then 'Defaulter'
end as art_status,
lab.viral_load_date,
lab.viral_load,
lab.urgency,
if(round(datediff(date(now()),art_start_date)/30,0)>=6,'DUE','NOT DUE') as DUE,
if(viral_load_date is not null,if(round(datediff(date('2022-06-30'),lab.viral_load_date)/30,1)>=12,'not_valid','valid'),'NA') as VL_VALID,
anc.visit_date as anc_visit_date,anc.anc_visit,ovc.visit_date as ovc_date_enrolled,ovc.client_enrolled_cpims as CPIMS_NO
from kenyaemr_datatools.hiv_followup fup
left join (
select 
patient_id,
max(visit_date) as date_assessed,
mid(max(concat(visit_date,differentiated_care)),11) as model,
mid(max(concat(visit_date,stability)),11) as stability
from kenyaemr_datatools.hiv_followup 
where person_present='Self (SF)' and visit_date<='2022-06-30'
group by patient_id
)current_model on current_model.patient_id=fup.patient_id
left join (
select 
patient_id,
mid(min(concat_ws('',fup1.visit_date,fup1.who_stage)),11) as who_enrollment
from kenyaemr_datatools.hiv_followup fup1
where who_stage != '' 
group by patient_id
)who on who.patient_id=fup.patient_id
join kenyaemr_datatools.patient_demographics p on p.patient_id=fup.patient_id
join kenyaemr_datatools.hiv_enrollment e on fup.patient_id=e.patient_id
left outer join kenyaemr_datatools.drug_event de on e.patient_id = de.patient_id and de.program='HIV' 
and date(date_started) <= date('2022-06-30')
left join
(SELECT patient_id,min(date_started) as art_start_date
FROM kenyaemr_datatools.drug_event 
group by patient_id) art on art.patient_id = fup.patient_id

left join
(SELECT patient_id,
mid(max(concat(visit_date,regimen_name)),11) as regimen_name,
mid(max(concat(visit_date,regimen_line)),11) as regimen_line,
max(visit_date) as current_regimen_date
FROM kenyaemr_datatools.drug_event 
where discontinued is null and program='HIV'
group by patient_id) art1 on art1.patient_id = fup.patient_id

left join(SELECT et.patient_id, 
et.visit_date as viral_load_date,
et.test_result as viral_load,
et.urgency as urgency
FROM kenyaemr_datatools.laboratory_extract et
inner join (SELECT patient_id,max(visit_date) as date1 FROM kenyaemr_datatools.laboratory_extract 
where lab_test= 'HIV VIRAL LOAD' group by patient_id
)lab1 on lab1.patient_id=et.patient_id and lab1.date1=et.visit_date
where lab_test= 'HIV VIRAL LOAD' 
group by et.patient_id) lab on lab.patient_id = fup.patient_id

left join(
select e.patient_id,lv.last_date as last_attend,lv.last_tca as date_missed,v.latest_visit
 from (
select fup.visit_date,fup.patient_id,
max(fup.visit_date) as latest_vis_date,
mid(max(concat(fup.visit_date,fup.next_appointment_date)),11) as latest_tca,
d.visit_date as date_discontinued,
d.patient_id as disc_patient
from kenyaemr_datatools.hiv_followup fup

 -- ensure those discontinued are catered for
left outer JOIN
(select patient_id, max(visit_date) as visit_date from kenyaemr_datatools.patient_program_discontinuation
where date(visit_date) <= date_sub('2022-05-31', INTERVAL 1 DAY)  and program_name='HIV' and discontinuation_reason !='Lost to Follow'
group by patient_id -- check if this line is necessary
) d on d.patient_id = fup.patient_id
where fup.visit_date <= date_sub('2022-05-31', INTERVAL 1 DAY)
group by patient_id
--  we may need to filter lost to follow-up using this
having (
(((date(latest_tca) < date_sub('2022-05-31', INTERVAL 1 DAY)) and (date(latest_vis_date) < date(latest_tca))) ) and ((date(latest_tca) > date(date_discontinued) and date(latest_vis_date) > date(date_discontinued)) or disc_patient is null ) and datediff(date_sub('2022-05-31', INTERVAL 1 DAY), date(latest_tca)) > 30)
-- drop missd completely
) e 

inner join kenyaemr_datatools.hiv_followup r on r.patient_id=e.patient_id and date_add(date(r.next_appointment_date), interval 30 DAY)>('2022-06-30') and date(r.visit_date)<=('2022-06-30')
left outer join(select 
patient_id,
max(next_appointment_date) as last_tca,
mid(max(concat(next_appointment_date,visit_date)),11) as last_date
from kenyaemr_datatools.hiv_followup
where next_appointment_date < date_sub('2022-05-31', INTERVAL 30 DAY)
group by patient_id
) lv on lv.patient_id=e.patient_id 
left outer join (
select patient_id,
max(visit_date) as latest_visit
from kenyaemr_datatools.hiv_followup
where visit_date <='2022-06-30'
group by patient_id
) v on v.patient_id =e.patient_id 
group by e.patient_id
) rtt on rtt.patient_id=fup.patient_id

left join (select * from kenyaemr_etl.etl_ovc_enrolment) ovc on ovc.patient_id=fup.patient_id

left join(
SELECT patient_id,
max(visit_date) as visit_date,
max(anc_visit_number) as anc_visit 
FROM kenyaemr_datatools.mch_antenatal_visit 
where next_appointment_date > '2022-05-31' group by patient_id
)anc on anc.patient_id=fup.patient_id
left join openmrs.relationship rs on rs.person_a=fup.patient_id and rs.relationship=3
-- left join(SELECT patient_id,visit_date,next_appointment_date as tca FROM kenyaemr_datatools.hei_follow_up_visit where next_appointment_date>'2022-05-31'
-- ) hei on hei.patient_id=rs.person_b
left join(
select patient_id,
max(visit_date) as visit_date,
max(pnc_visit_no) as pnc_visit 
from kenyaemr_datatools.mch_postnatal_visit 
group by patient_id
)pnc on pnc.patient_id=fup.patient_id

left join(
select ipt_initiation.patient_id,min(visit_date) as ipt_start_date,ipt_outcome.ipt_outcome_date,ipt_outcome.ipt_outcome
  from kenyaemr_etl.etl_ipt_initiation ipt_initiation
left join (
   select patient_id,min(visit_date) as ipt_outcome_date,
   (case outcome when 159492 then "Transferred Out" when 160034 then "Died" when 5240 then "Lost to Follow" when 819 then "Cannot afford Treatment"  
  when 5622 then "Other" when 1067 then "Unknown" when 1267 then "Completed" when 112141 then "Developed TB" when 102 then "Drug Toxicity" when 159836 then "Discontinued" else "" end) as ipt_outcome
  from kenyaemr_etl.etl_ipt_outcome 
where voided=0
group by patient_id
  ) ipt_outcome on ipt_outcome.patient_id =ipt_initiation.patient_id
where voided=0
group by patient_id) ipt on ipt.patient_id=fup.patient_id

left join(
select patient_id,
visit_date,
mid(max(concat(visit_date,tb_status)),11) as presumed_tb,
tb_status
from kenyaemr_datatools.hiv_followup where visit_date between '2022-05-31' and '2022-06-30' and tb_status = 'Presumed TB'
group by patient_id
) tb on tb.patient_id=fup.patient_id

left outer JOIN
(select patient_id, max(visit_date) as visit_date from kenyaemr_datatools.patient_program_discontinuation
 where date(visit_date) <= date('2022-06-30') and program_name='HIV'
group by patient_id
) d on d.patient_id = fup.patient_id
where fup.visit_date <= date('2022-06-30') and date_add(date(next_appointment_date), interval 30 DAY)  >= date('2022-06-30') 
group by patient_id
 having  
 (((disc_patient is null and date_add(date(latest_tca), interval 30 DAY)  >= date('2022-06-30')) or 
 (date(latest_tca) > date(date_discontinued) and date(latest_vis_date)> date(date_discontinued) 
and date_add(date(latest_tca), interval 30 DAY)  >= date('2022-06-30') ))
          ) 
        ) t
union 
select 
(select sitecode from kenyaemr_datatools.default_facility_info) as mfl,(select facilityname from kenyaemr_datatools.default_facility_info) as facility_name,
UPN as ccc_number,dob as date_of_birth,gender,entry_point as Patient_Source,transferin_date,enroll_date as date_enrolled,art_start_date as Date_initiated_art,who_stage_enrollment,current_regimen,regimen_line as current_regimen_line,current_regimen_date,
latest_vis_date as lastvisit,latest_tca as TCA,art_dispensing_duration,tx_rtt,previousexpected_Date,rttdate,ipt_start_date as ipt_initiation_date,
ipt_outcome_date,ipt_outcome as ipt_status,presumed_tb as presumptive_tb,
date_assessed as date_assessed_stability,
stability as DSD_Stability_Assessment,DSD_Model,viral_load_date,viral_load,urgency,art_status as status,anc_visit_date,anc_visit,pnc_visit_date,pnc_visit
 from( 
 select fup.visit_date,fup.patient_id, min(e.visit_date) as enroll_date,
 mid(min(concat_ws('',e.visit_date,entry_point)),11) as entry_point,
 mid(min(concat_ws('',e.visit_date,transfer_in_date)),11) as transferin_date,
max(fup.visit_date) as latest_vis_date,
mid(max(concat(fup.visit_date,fup.next_appointment_date)),11) as latest_tca,
case when current_model.stability='Yes' then 'Stable'
when current_model.stability='No' then 'Unstable'
else 'Not Done' end as stability,
current_model.date_assessed,
current_model.model as dsd_model,
max(d.visit_date) as date_discontinued,
who.who_enrollment as who_stage_enrollment,
d.patient_id as disc_patient,
de.patient_id as started_on_drugs,
art.art_start_date,
art1.regimen_name as current_regimen,
art1.regimen_line as regimen_line,
art1.current_regimen_date as current_regimen_date,
p.dob as dob,
case when p.gender='f' then 'Female' 
when p.gender='m' then 'Male'
else '' end as gender,
p.unique_patient_no as UPN,
if(rtt.latest_visit is null,'No','Yes') as tx_rtt,
rtt.latest_visit as rttdate,
rtt.date_missed as previousexpected_Date,
ipt.ipt_start_date,
ipt.ipt_outcome_date,
ipt.ipt_outcome,
tb.presumed_tb,
case when datediff(date(mid(max(concat(fup.visit_date,fup.next_appointment_date)),11)),date(max(fup.visit_date))) <90 then 'b_3'
when datediff(date(mid(max(concat(fup.visit_date,fup.next_appointment_date)),11)),date(max(fup.visit_date))) between 90 and 179 then '3_5'
when datediff(date(mid(max(concat(fup.visit_date,fup.next_appointment_date)),11)),date(max(fup.visit_date)))>179 then 'a_6' end as art_dispensing_duration,
'Tx_New_ML' as art_status,
lab.viral_load_date,
lab.viral_load,
lab.urgency,
if(round(datediff(date(now()),art_start_date)/30,0)>=6,'DUE','NOT DUE') as DUE,
if(viral_load_date is not null,if(round(datediff(date('2022-06-30'),lab.viral_load_date)/30,1)>=12,'not_valid','valid'),'NA') as VL_VALID,
anc.visit_date as anc_visit_date,anc.anc_visit,pnc.visit_date as pnc_visit_date,pnc.pnc_visit
from kenyaemr_datatools.hiv_followup fup
left join (
select 
patient_id,
max(visit_date) as date_assessed,
mid(max(concat(visit_date,differentiated_care)),11) as model,
mid(max(concat(visit_date,stability)),11) as stability
from kenyaemr_datatools.hiv_followup 
where person_present='Self (SF)' and visit_date<='2022-06-30'
group by patient_id
)current_model on current_model.patient_id=fup.patient_id
left join (
select 
patient_id,
mid(min(concat_ws('',fup1.visit_date,fup1.who_stage)),11) as who_enrollment
from kenyaemr_datatools.hiv_followup fup1
where who_stage != '' 
group by patient_id
)who on who.patient_id=fup.patient_id
join kenyaemr_datatools.patient_demographics p on p.patient_id=fup.patient_id
join kenyaemr_datatools.hiv_enrollment e on fup.patient_id=e.patient_id
left outer join kenyaemr_datatools.drug_event de on e.patient_id = de.patient_id and de.program='HIV' 
and date(date_started) <= date('2022-06-30')
left join
(SELECT patient_id,min(date_started) as art_start_date
FROM kenyaemr_datatools.drug_event 
group by patient_id) art on art.patient_id = fup.patient_id

left join
(SELECT patient_id,
mid(max(concat(visit_date,regimen_name)),11) as regimen_name,
mid(max(concat(visit_date,regimen_line)),11) as regimen_line,
max(visit_date) as current_regimen_date
FROM kenyaemr_datatools.drug_event 
where discontinued is null and program='HIV'
group by patient_id) art1 on art1.patient_id = fup.patient_id

left join(SELECT et.patient_id, 
et.visit_date as viral_load_date,
et.test_result as viral_load,
et.urgency as urgency
FROM kenyaemr_datatools.laboratory_extract et
inner join (SELECT patient_id,max(visit_date) as date1 FROM kenyaemr_datatools.laboratory_extract 
where lab_test= 'HIV VIRAL LOAD' group by patient_id
)lab1 on lab1.patient_id=et.patient_id and lab1.date1=et.visit_date
where lab_test= 'HIV VIRAL LOAD' 
group by et.patient_id) lab on lab.patient_id = fup.patient_id

left join(
select e.patient_id,lv.last_date as last_attend,lv.last_tca as date_missed,v.latest_visit
 from (
select fup.visit_date,fup.patient_id,
max(fup.visit_date) as latest_vis_date,
mid(max(concat(fup.visit_date,fup.next_appointment_date)),11) as latest_tca,
max(d.visit_date) as date_discontinued,
d.patient_id as disc_patient
from kenyaemr_datatools.hiv_followup fup

 -- ensure those discontinued are catered for
left outer JOIN
(select patient_id, max(visit_date) as visit_date from kenyaemr_datatools.patient_program_discontinuation
where date(visit_date) <= date_sub('2022-05-31', INTERVAL 1 DAY)  and program_name='HIV' and discontinuation_reason !='Lost to Follow'
group by patient_id -- check if this line is necessary
) d on d.patient_id = fup.patient_id
where fup.visit_date <= date_sub('2022-05-31', INTERVAL 1 DAY)
group by patient_id
--  we may need to filter lost to follow-up using this
having (
(((date(latest_tca) < date_sub('2022-05-31', INTERVAL 1 DAY)) and (date(latest_vis_date) < date(latest_tca))) ) and ((date(latest_tca) > date(date_discontinued) and date(latest_vis_date) > date(date_discontinued)) or disc_patient is null ) and datediff(date_sub('2022-05-31', INTERVAL 1 DAY), date(latest_tca)) > 30)
-- drop missd completely
) e 

inner join kenyaemr_datatools.hiv_followup r on r.patient_id=e.patient_id and date_add(date(r.next_appointment_date), interval 30 DAY)>('2022-06-30') and date(r.visit_date)<=('2022-06-30')
left outer join(select 
patient_id,
max(next_appointment_date) as last_tca,
mid(max(concat(next_appointment_date,visit_date)),11) as last_date
from kenyaemr_datatools.hiv_followup
where next_appointment_date < date_sub('2022-05-31', INTERVAL 30 DAY)
group by patient_id
) lv on lv.patient_id=e.patient_id 
left outer join (
select patient_id,
max(visit_date) as latest_visit
from kenyaemr_datatools.hiv_followup
where visit_date <='2022-06-30'
group by patient_id
) v on v.patient_id =e.patient_id 
group by e.patient_id
) rtt on rtt.patient_id=fup.patient_id

left join(
SELECT patient_id,
max(visit_date) as visit_date,
max(anc_visit_number) as anc_visit 
FROM kenyaemr_datatools.mch_antenatal_visit 
where next_appointment_date > '2022-05-31' group by patient_id
)anc on anc.patient_id=fup.patient_id

left join(
select patient_id,
max(visit_date) as visit_date,
max(pnc_visit_no) as pnc_visit 
from kenyaemr_datatools.mch_postnatal_visit 
group by patient_id
)pnc on pnc.patient_id=fup.patient_id

left join(
select ipt_initiation.patient_id,min(visit_date) as ipt_start_date,ipt_outcome.ipt_outcome_date,ipt_outcome.ipt_outcome
  from kenyaemr_etl.etl_ipt_initiation ipt_initiation
left join (
   select patient_id,min(visit_date) as ipt_outcome_date,
   (case outcome when 159492 then "Transferred Out" when 160034 then "Died" when 5240 then "Lost to Follow" when 819 then "Cannot afford Treatment"  
  when 5622 then "Other" when 1067 then "Unknown" when 1267 then "Completed"  when 159836 then "discontinued" else "" end) as ipt_outcome
  from kenyaemr_etl.etl_ipt_outcome 
where voided=0
group by patient_id
  ) ipt_outcome on ipt_outcome.patient_id =ipt_initiation.patient_id
where voided=0
group by patient_id) ipt on ipt.patient_id=fup.patient_id

left join(
select patient_id,
visit_date,
mid(max(concat(visit_date,tb_status)),11) as presumed_tb,
tb_status
from kenyaemr_datatools.hiv_followup where visit_date between '2022-05-31' and '2022-06-30' and tb_status = 'Presumed TB'
group by patient_id
) tb on tb.patient_id=fup.patient_id

left outer JOIN
(select patient_id, max(visit_date) as visit_date from kenyaemr_datatools.patient_program_discontinuation
 where date(visit_date) <= date('2022-06-30') and program_name='HIV'
group by patient_id
) d on d.patient_id = fup.patient_id
where fup.visit_date <= date('2022-06-30') and date_add(date(next_appointment_date), interval 30 DAY)  >= date('2022-06-30') 
group by patient_id
 having 
 (disc_patient is not null and enroll_date>'2022-05-31')
            
        ) t;