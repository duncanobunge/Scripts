use openmrs;
set @endDate ='2021-12-31';
select 
                    -- fup.visit_date,
                    fup.patient_id, 
                    p.unique_patient_no,
                    p.Gender,
                    p.DOB,
                    max(e.visit_date) as enroll_date,
                    greatest(max(e.visit_date), ifnull(max(date(e.transfer_in_date)),'0000-00-00')) as latest_enrolment_date,
                    mid(min(concat(de.date_started, de.regimen_name)), 11)as 'Initial ART Regimen',
                    mid(max(concat(de.date_started, de.regimen_name)), 11) as 'Current ART regimen',
                    mid(max(concat(fup.visit_date, fup.who_stage)), 11) as 'Current_WHO_Stage',
                    greatest(max(fup.visit_date), ifnull(max(d.visit_date),'0000-00-00')) as latest_vis_date,
                    greatest(mid(max(concat(fup.visit_date,fup.next_appointment_date)),11), ifnull(max(d.visit_date),'0000-00-00')) as latest_tca,
                    datediff(@endDate,greatest(mid(max(concat(fup.visit_date,fup.next_appointment_date)),11), ifnull(max(d.visit_date),'0000-00-00'))) as DaysMissedAppointment,
                    d.patient_id as disc_patient,
                    d.effective_disc_date as effective_disc_date,
                    max(d.visit_date) as date_discontinued,
                    d.discontinuation_reason,
                    de.patient_id as started_on_drugs
		        from kenyaemr_etl.etl_patient_hiv_followup fup
		        join kenyaemr_etl.etl_patient_demographics p on p.patient_id=fup.patient_id
		        join kenyaemr_etl.etl_hiv_enrollment e on fup.patient_id=e.patient_id
		        left outer join kenyaemr_etl.etl_drug_event de on e.patient_id = de.patient_id and de.program='HIV' and date(date_started) <= date(curdate())
		        left outer join(
                           select 
                              patient_id, 
                              coalesce(date(effective_discontinuation_date),visit_date) visit_date,max(date(effective_discontinuation_date)) as effective_disc_date,
                              discontinuation_reason 
                            from kenyaemr_etl.etl_patient_program_discontinuation
		                    where date(visit_date) <= date(@endDate) and program_name='HIV'
		                    group by patient_id
		        ) d on d.patient_id = fup.patient_id
		        where fup.visit_date <= date(@endDate)
		        group by patient_id
		        having (
		        (datediff(@endDate, date(latest_tca)) between 31 and 37)
		        and ((date(d.effective_disc_date) > date(@endDate) or date(enroll_date) > date(d.effective_disc_date)) or d.effective_disc_date is null)
		        and (date(latest_vis_date) > date(date_discontinued) and date(latest_tca) > date(date_discontinued) or disc_patient is null));
