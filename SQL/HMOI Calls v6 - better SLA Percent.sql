select '' 'Breakdown by Phone/DNIS';

DROP TABLE IF EXISTS #CALL_BASE;

select 
	a.YR
	, a.MTH
	, a.DNISName
	, a.DNISReporting
--	, a.YR_Month
	, a.TotalCallsOffered
	, a.TotalCallsHandled
	, a.TotalAbandoned
	, a.TotalInterflowed
	, b.ShortAbandoned
	, a.TotalAbandoned - b.ShortAbandoned as LongAbandoned
	, b.TotalCallsRequeued
	, b.AnsweredbyGroup1
	, b.AnsweredbyGroup2
	, b.AnsweredbyGroup3
	, b.AnsweredbyGroup4
	, a.AvgTimetoAnswerMinutes
	--, b.AvgDelayToAbandon
	, b.Formatted_AvgDelayToAbandon
	--, b.AvgDelaytoInterflow
	, b.Formatted_AvgDelaytoInterflow
	, a.ACDHandlingTime
	, a.AvgACDHandlingTime
	, case when A.TotalCallsOffered = 0 then 0 else A.TotalCallsHandled*1.0/A.TotalCallsOffered end as [ANSWER_Percentage]
	, cast(0 as float) as SERVICE_LEVEL
	, cast(0 as float) as Adis_Service_Level
	, cast(0 as float) as Arts_Service_Level
into #Call_Base
from (
		SELECT
			year(as_of_dt) as YR
			, month(AS_OF_DT) as MTH
			, DNISName
			, DNISReporting
			--, concat(year(as_of_dt),case when len(month(AS_OF_DT))=1 then concat('0',month(as_of_dt)) else month(as_of_dt) end)
			--	as YR_MONTH
			, sum(CallsOffered) as TotalCallsOffered
			, sum(CallsHandled) as TotalCallsHandled
			, sum(CallsAbandoned) as TotalAbandoned
			, sum(CallsInterflowed) as TotalInterflowed
			--, CASE WHEN sum(CallsHandled) <> 0 then sum(TotalTimeToAnswer)/sum(CallsHandled) 
			--		else 0 end
			--	as AvgTimetoAnswer
			, CASE WHEN sum(CallsHandled) <> 0 then concat(sum(TotalTimeToAnswer)/sum(CallsHandled)/60,':',format(sum(TotalTimeToAnswer)/sum(CallsHandled)%60,'00')) 
					else '0' end
				as AvgTimetoAnswerMinutes
			----, CASE WHEN sum(CallsHandled) <> 0 then sum(TotalTalkTime)/sum(CallsHandled) 
			----		else '0' end
			----	as AvgTalkTime
			, CASE WHEN sum(CallsHandled) <> 0 then concat(sum(TotalTalkTime)/sum(CallsHandled)/60,':',format(sum(TotalTalkTime)/sum(CallsHandled)%60,'00')) 
					else '0' end as AvgACDHandlingTime--AvgTalkTime_Formatted
			--, sum(TotalTalkTime) as TotalTalkTime
			, concat(sum(TotalTalkTime)/3600
						,':'
						,format(
								(
									sum(TotalTalkTime)-((sum(TotalTalkTime)/3600)*3600)
								) / 60
								,'00')
						,':'
						,format(sum(TotalTalkTime)%60,'00')) as ACDHandlingTime --TotalTalkTime_Formatted
			----, sum(TotalTimetoAnswer) as TimetoAnswer_NEW
			--, concat(sum(TotalTimetoAnswer)/3600
			--			,':'
			--			,format(
			--					(
			--						sum(TotalTimetoAnswer)-((sum(TotalTimetoAnswer)/3600)*3600)
			--					) / 60
			--					,'00')
			--			,':'
			--			,format(sum(TotalTimetoAnswer)%60,'00')) as ACDHandlingTime --TotalAnswerTime_Formatted
		from  DLDB.dbo.Agg_Tbl_Telephone_status 
			where --DNISReporting in ('9146145160','9146145493','9146145162')
				DNISName like '%BCBSIL%' or DNISName like '%HMOI%'
		group by year(as_of_dt) 
			, month(AS_OF_DT)
			, DNISName
			, DNISReporting
		--order by year(as_of_dt) DESC
		--	, month(AS_OF_DT) ASC
		--	, DNISName ASC
		--	, DNISReporting
		) A
LEFT join (
		SELECT 
			  year(MidnightStartDate) AS YR
			, MONTH(MidnightStartDate) MTH
			, DNISName
			, DNISReporting
			, sum(DNISShortAbandoned) as ShortAbandoned
			, sum(DNISRequeued) as TotalCallsRequeued
			, sum(AnswerBy1) as AnsweredbyGroup1
			, sum(AnswerBy2) as AnsweredbyGroup2
			, sum(AnswerBy3) as AnsweredbyGroup3
			, sum(AnswerBy4) as AnsweredbyGroup4
			, case when sum(DNISAbandoned)=0 then '0' else concat(
																		(sum(DNISTimeToAbandonTotal)/sum(DNISAbandoned)
																	)/60
																	,':'
																	--,(sum(DNISTimeToAbandonTotal)-(
																	--							(sum(DNISTimeToAbandonTotal)/3600)
																	--							*3600)
																	--)/60
																	--,':'
																	,format((sum(DNISTimeToAbandonTOtal)/sum(DNISAbandoned)
																	)%60,'00')
																)
																end as	Formatted_AvgDelayToAbandon
			, case when sum(DNISInterflowed)=0 then '0' else concat(
																	(sum(DNISTimeToInterflowTotal)/sum(DNISInterflowed)
																		)/3600
																	,':'
																	,format((
																		(sum(DNISTimeToInterflowTotal)/sum(DNISInterflowed))-
																			((sum(DNISTimeToInterflowTotal)/sum(DNISInterflowed))/3600)*3600
																		)/60,'00')
																	,':'
																	,format((sum(DNISTimeToInterflowTotal)/sum(DNISInterflowed)
																			)%60,'00')	
																	)
														end as Formatted_AvgDelayToInterflow
				, case when sum(DNISAbandoned)=0 
					then 0 else sum(DNISTimeToAbandonTotal)*1.0/sum(DNISAbandoned)*1.0 
						end as AvgDelayToAbandon
			, case when sum(DNISInterflowed)=0 then 0 
				else sum(DNISTimeToInterflowTotal)*1.0/sum(DNISInterflowed)*1.0 
					end as AvgDelayToInterflow		--, 
		FROM DLDB..dl_dw_ccm_DNISPerformanceByPeriodStats
			where --DNISReporting in ('9146145160','9146145493','9146145162')
		DNISName like '%BCBSIL%' or DNISName like '%HMOI%'

		group by 
		 year(MidnightStartDate) 
			, MONTH(MidnightStartDate) 
			, DNISName
			, DNISReporting
	) B
	ON A.YR = B.YR
		and A.MTH = B.MTH
		and a.DNISName = b.DNISName
		and a.DNISReporting = b.DNISReporting
ORDER BY A.YR DESC
, A.MTH ASC
, A.DNISNAME
, A.DNISrEPORtING
;


SElect '' '#call_base';
select * from #call_base
order by YR DESC
, mth asc
, DNISName ASC
, DNISReporting ASC;


/*Historically, Adi's files were generated with the 10 second logic below.  In Q2 2026, Art updated it 
from 10 seconds to 25.  The regular "Time_Compliance" field best mirrors Mitel.*/

DROP TABLE IF EXISTS #Call_Compliance;
select distinct DNISName
	, DNISReporting
	, month(DateofCall) as Mth
	, year(DateOfCall) as YR
	, DateofCall
	, TimeToAnswer
	, case when TimeToAnswer <= 10 then 1 else TimeToAnswer-10 END as Adis_Time
	, case when TimeToAnswer <= 25 then 1 else TimeToAnswer-25 END as ARTs_Time
	, CASE WHEN TimeToAnswer <= 30 then 1 else 0 end as Time_Compliance
	, cast(0 as int) as Adis_Time_Compliance
	, cast(0 as int) as ARTs_Time_Compliance
INTO #Call_COmpliance
FROM dldb.DBO.dl_dw_ccm_win_custom_AgentInboundCallDetails
where DNISName like '%HMOI%'
ORDER BY DNISName
	, year(DateOfCall) desc --as YR
	, month(DateofCall) --as Mth
	, DateofCall
;

select '' '#Call_Compliance';
select * from #Call_Compliance
;

UPDATE #Call_Compliance
SET Adis_Time_Compliance = case when Adis_Time <=30 then 1 else 0 end
, ARTs_Time_Compliance = CASE WHEN ARTs_Time <=30 then 1 else 0 end
;

select '' '#Call_Compliance';
select * from #Call_Compliance

SElect '' '#call_base';
select * from #call_base
order by YR DESC
, mth asc
, DNISName ASC
, DNISReporting ASC;


/*WE HAVE TO USE COUNT(*) from dl_dw_ccm_win_custom_AgentInboundCallDetails
instead of TotalHandled or TotalOffered from Agg_Tbl_Telephone_status

Sasi stated that dl_dw_ccm_win_custom_AgentInboundCallDetails & dl_dw_ccm_DNISPerformanceByPeriodStats
DO NOT add up, and that Agg_tbl_Telephone_Status is derived from these tables Mitel gave us that do 
not fully match*/

with SLA_aggregates as
(
	SELECT distinct
	  cc.DNISName
	, cc.DNISReporting
	, cc.YR
	, cc.MTH
	, count(*) as Total_Calls
	----, cb.TotalCallsOffered
	----, cb.TotalCallsHandled
	--, case when cb.TotalCallsOffered = 0 then 0 
	--	else (sum(Time_Compliance)*1.0)--/cb.TotalCallsOffered*1.0)--*cb.Answer_Percentage*1.0 
	--	END AS Service_Level
	--, case when cb.TotalCallsOffered = 0 then 0 
	--	else (sum(Adis_Time_Compliance)*1.0)--/cb.TotalCallsOffered*1.0)--*cb.Answer_Percentage*1.0 
	--	END AS Adis_Service_Level
	--, case when cb.TotalCallsOffered = 0 then 0 
	--	else (sum(ARTs_Time_Compliance)*1.0)--/cb.TotalCallsOffered*1.0)--*cb.Answer_Percentage*1.0 
	--	END AS Arts_Service_Level
	--, cb.Answer_Percentage
	, case when cb.TotalCallsOffered = 0 then 0 
		else ((sum(Time_Compliance)*1.0)/count(*)*1.0)*cb.Answer_Percentage--)cb.TotalCallsOffered*1.0--)--*cb.Answer_Percentage*1.0 
		END AS Service_Level_Percent
	, case when cb.TotalCallsOffered = 0 then 0 
		else ((sum(Adis_Time_Compliance)*1.0)/count(*)*1.0)*cb.Answer_Percentage--)--cb.TotalCallsOffered*1.0--)--*cb.Answer_Percentage*1.0 
		END AS Adis_Service_Level_Percent
	, case when cb.TotalCallsOffered = 0 then 0 
		else ((sum(ARTs_Time_Compliance)*1.0)/count(*)*1.0)*cb.Answer_Percentage--)--cb.TotalCallsOffered*1.0--)--*cb.Answer_Percentage*1.0 
		END AS Arts_Service_Level_Percent
from #Call_Base cb 
LEFT JOIN #Call_Compliance cc 
	on cc.DNISReporting = cb.DNISReporting
		and cc.DNISName = cb.DNISName
		and cc.Yr = cb.Yr
		and cc.Mth = cb.Mth
GROUP BY cc.DNISName
	, cc.DNISReporting
	, cc.YR
	, cc.MTH
	, cb.TotalCallsOffered
	, cb.Answer_Percentage
	, cb.TotalCallsOffered
	, cb.TotalCallsHandled
--order by cc.YR DESC
--	, cc.mth
--	, cc.DNISReporting
)
UPDATE cb
set service_level = SLA.service_level_Percent
, Adis_Service_Level = sla.Adis_Service_Level_Percent
, Arts_Service_Level = sla.Arts_Service_Level_Percent
FROM #call_base cb
JOIN SLA_aggregates sla
on cb.DNISReporting = SLA.DNISReporting
	and cb.DNISName = SLA.DNISName
	and cb.YR = sla.YR
	and cb.MTH = sla.MTH
;

SElect '' '#call_base';
select * from #call_base
WHERE DNISReporting in ('+18773695703','+18774447299','+18774447271','+18774447286','9146145160','9146145493','9146145162'
						)
order by YR DESC
, mth asc
, DNISName ASC
, DNISReporting ASC;


