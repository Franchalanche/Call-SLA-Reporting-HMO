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
	, cast(0 as float) as Handled_Under_30_Seconds
	, cast(0 as float) as Handled_Under_30_Seconds_Weighted_by_Answer_Percent
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
join (
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

drop table if exists #service_level;

with monthly_Base AS
(
	SELECT year(as_of_DT) as YR
		, MONTH(AS_OF_DT) as MTH
		, dnisnAME
		, DNISReporting
		, sum(CallsHandled) as Total_Monthly_Handled
	FROM DLDB.dbo.Agg_Tbl_Telephone_status
	where --DNISReporting in ('9146145160','9146145493','9146145162')
		DNISName like '%BCBSIL%' or DNISName like '%HMOI%'		
	GROUP BY year(as_of_DT) 
		, MONTH(AS_OF_DT) --as MTH
		, dnisnAME
		, DNISReporting
)
	select 
		year(ag.as_of_DT) as YR
		, MONTH(ag.AS_OF_DT) as MTH
		, ag.dnisnAME
		, ag.DNISReporting
		, ag.as_of_dt
		, ag.CallsHandled
		, mb.Total_Monthly_Handled
		, case when mb.Total_Monthly_Handled = 0 then 0
			else ag.CallsHandled*1.0/mb.Total_Monthly_Handled*1.0
			end	as Monthly_Weight
		, case when mb.Total_Monthly_Handled = 0 then 0
			else (ag.CallsHandled*1.0/mb.Total_Monthly_Handled*1.0)*ServiceLevel
			end as Score_to_Add
	into #service_level
	FROM DLDB.dbo.Agg_Tbl_Telephone_status ag
	JOIN monthly_Base mb
		on ag.DNISName = mb.DNISName
			and ag.DNISReporting = mb.DNISReporting
			and year(ag.as_of_dt)=mb.YR
			and month(ag.as_of_dt) = mb.MTH
;


SElect '' '#call_base';
select * from #call_base
order by YR DESC
, mth asc
, DNISName ASC
, DNISReporting ASC;

select '' '#service_level';
select * from #service_level;

select distinct 
	yr
	, mth
	, DNISName
	, DNISReporting
	, sum(Score_to_Add) as ServiceLevel
FROM #service_level
GROUP BY 	yr 
	, mth
	, DNISName
	, DNISReporting
ORDER BY 	yr DESC
	, mth
	, DNISName
	, DNISReporting
;

with new_monthly_Score as
(
	select distinct 
	yr
	, mth
	, DNISName
	, DNISReporting
	, sum(Score_to_Add) as ServiceLevel
FROM #service_level
GROUP BY 	yr 
	, mth
	, DNISName
	, DNISReporting
)
update cb
SET SERVICE_LEVEL = sl.ServiceLEvel*1.0*Answer_Percentage*1.0
FROM #call_base cb
JOIN new_monthly_Score sl
ON cb.DNISReporting = sl.DNISReporting
	and cb.DNISName = sl.DNISName
	and cb.YR = sl.YR
	and cb.MTH = sl.MTH
;

SElect '' '#call_base';
select *
from #call_base
order by YR DESC
, mth asc
, DNISName ASC
, DNISReporting ASC;

--select '' '#service_level plus #Call_base';
--select distinct 
--	sl.yr
--	, sl.mth
--	, sl.DNISName
--	, sl.DNISReporting
--	, sum(sl.Score_to_Add) as ServiceLevel
--	, sum(sl.Score_to_Add)*1.0*cb.Answer_Percentage as Weighted_ServiceLevel
--FROM #service_level sl
--JOIN #call_base cb
--	on sl.DNISName = cb.DNISName
--		and sl.DNISReporting = cb.DNISReporting
--		and sl.yr = cb.yr
--		and sl.mth = cb.mth
--GROUP BY 	sl.yr 
--	, sl.mth
--	, sl.DNISName
--	, sl.DNISReporting
--	, cb.Answer_Percentage
--ORDER BY 	sl.yr DESC
--	, sl.mth
--	, sl.DNISName
--	, sl.DNISReporting
--;

/*
	VERSION 2 OF SERVICE LEVELS
	NOT RELYING ON SERVICELEVEL FIELD IN DLDB.DBO.Agg_Tbl_Telephone_status
-	The weighted average ServiceLevel in DLDB.dbo.Agg_Tbl_Telephone_status per month 
		is lower than Mitel’s.  
o	Average speed to answer must have custom calculations from Art, because many 
	under a certain threshold are reduced to a 1 second answer time

*/

select '' 'Other Service Level Calculations';
with monthly_weight_Base AS
(
	SELECT year(as_of_DT) as YR
		, MONTH(AS_OF_DT) as MTH
		, dnisnAME
		, DNISReporting
		, sum(CallsHandled) as Total_Monthly_Handled
	FROM DLDB.dbo.Agg_Tbl_Telephone_status
	where --DNISReporting in ('9146145160','9146145493','9146145162')
		DNISName like '%BCBSIL%' or DNISName like '%HMOI%'		
	GROUP BY year(as_of_DT) 
		, MONTH(AS_OF_DT) --as MTH
		, dnisnAME
		, DNISReporting
)
, daily_service as
(
	SELECT distinct
		ag.DNISName
		, ag.DNISReporting
		, year(ag.as_of_dt) as YR
		, month(ag.as_of_dt) as MTH
		, ag.as_of_dt
		, ag.callsHandled
		, ag.TotalTimeToAnswer
		, case when CallsHandled = 0 then 0
				else TotalTimeToAnswer*1.0/CallsHandled*1.0
			end as Avg_Answer_Time
		, case when CallsHandled = 0 then 0
			when  TotalTimeToAnswer*1.0/CallsHandled*1.0 <= 30
				then 1
			else 0
			end as Service_Level
		, mb.Total_Monthly_Handled
		, case when mb.Total_Monthly_Handled = 0 then 0 
				else ag.CallsHandled*1.0/(mb.Total_Monthly_Handled*1.0) 
			end as Call_Weight
		--, case when mb.Total_Monthly_Handled = 0 then 0 
		--		else (ag.CallsHandled*1.0/(mb.Total_Monthly_Handled*1.0))*ServiceLevel
		--	end as Service_Level_to_Sum
		, case when CallsOffered = 0 then 0 else CallsHandled*1.0/CallsOffered*1.0 
			end as	Answer_Percentage
		--, case when mb.Total_Monthly_Handled = 0 or CallsOffered = 0  then 0
		--	else ((ag.CallsHandled*1.0/(mb.Total_Monthly_Handled*1.0))*ServiceLevel)*(CallsHandled*1.0/CallsOffered*1.0)
		--	end as Service_Level_to_Sum_Answer_Weighted
	FROM DLDB.dbo.Agg_Tbl_Telephone_status ag
	JOIN monthly_weight_Base mb
		on ag.DNISName = mb.DNISName
			and ag.DNISReporting = mb.DNISReporting
			and year(ag.as_of_dt)=mb.YR
			and month(ag.as_of_dt) = mb.MTH 
	group by ag.DNISName
		, ag.DNISReporting
		, year(ag.as_of_dt) 
		, month(ag.as_of_dt) 
		, ag.as_of_dt
		, ag.CallsOffered
		, ag.callsHandled
		, ag.TotalTimeToAnswer
		, mb.Total_Monthly_Handled
),
monthly_summary as
(
	select distinct
		mwb.DNISReporting
		, mwb.DNISName
		, mwb.Yr
		, mwb.Mth
		, sum(ds.Service_Level*ds.Call_Weight) as Handled_Under_30_Seconds
		, sum(ds.Service_Level*ds.Call_Weight*ds.Answer_Percentage) as Handled_Under_30_Seconds_Weighted_by_Answer_Percent 
	FROM monthly_weight_Base mwb
	join daily_service ds
		on mwb.DNISReporting = ds.DNISReporting
			and mwb.DNISName = ds.DNISName
			and mwb.Yr = ds.Yr
			and mwb.Mth = ds.Mth
	group by mwb.DNISReporting
		, mwb.DNISName
		, mwb.Yr
		, mwb.Mth
)
--select
--	--mb.*
--	--, ds.*
--	  cb.*--YR
--	--, cb.MTH
--	--, cb.DNISName
--	--, cb.DNISReporting
--	, sum(ds.Service_Level*ds.Call_Weight) as Handled_Under_30_Seconds
--	, sum(ds.Service_Level*ds.Call_Weight*ds.Answer_Percentage) as Handled_Under_30_Seconds_Weighted_by_Answer_Percent
UPDATE cb
SET Handled_Under_30_Seconds = ms.Handled_Under_30_Seconds
,  Handled_Under_30_Seconds_Weighted_by_Answer_Percent = ms.Handled_Under_30_Seconds_Weighted_by_Answer_Percent
from #call_Base cb
JOIN monthly_summary ms
	ON cb.DNISReporting = ms.DNISReporting
		and cb.DNISName = ms.DNISName
		and cb.YR = ms.YR
		and cb.MTH = ms.MTH
;



SElect 'with new sla calculations' '#call_base';
select * from #call_base
order by YR DESC
, mth asc
, DNISName ASC
, DNISReporting ASC;

SElect 'SLA Summary with Leis SLA Calc' '#call_base';
select --concat(YR,MTH) as YYYYM
  YR
, MTH
, DNISReporting
, DNISName
, case when (TotalCallsHandled+LongAbandoned)=0 then 0
	ELSE (TotalCallsHandled*1.0)/(TotalCallsHandled+LongAbandoned*1.0)
	end as Handled_OverLongAbandoned
, SERVICE_LEVEL
, Handled_under_30_Seconds
, Handled_Under_30_Seconds_Weighted_by_Answer_Percent
FROM #Call_Base
where DNISReporting NOT IN ('9146145161')
ORDER BY  YR DESC
	, MTH DESC
	, DNISName
	, DNISReporting;


select 
	yr
	, MTH
	, DNISNAME
	, DNISReporting
	, TotalCallsOFfered
	, TotalCallsHandled
	--, TotalAbandoned
	, AvgTimeToAnswerMinutes
	, AvgDelayToAbandon
	, Formatted_AvgDelayToAbandon
	, AvgDelaytoInterflow
	, Formatted_AvgDelayToInterflow
from #call_base
order by YR DESC
, mth asc
, DNISName ASC
, DNISReporting ASC
;

select '' 'Total (No Phone #)';

SELECT
	year(as_of_dt) as YR
	, month(AS_OF_DT) as MTH
	--, DNISName
	--, DNISReporting
	, concat(year(as_of_dt),case when len(month(AS_OF_DT))=1 then concat('0',month(as_of_dt)) else month(as_of_dt) end)
		as YR_MONTH
	, data_src
	, sum(CallsOffered) as TotalCallsOffered
	, sum(CallsHandled) as TotalCallsHandled
	, sum(CallsAbandoned) as TotalAbandoned
	, sum(CallsInterflowed) as TotalInterflowed
	, sum(TotalTimetoAnswer) as TimetoAnswer_NEW
	, CASE WHEN sum(CallsHandled) <> 0 then sum(TotalTimeToAnswer)/sum(CallsHandled) 
			else 0 end
		as AvgTimetoAnswer
	, CASE WHEN sum(CallsHandled) <> 0 then concat(sum(TotalTimeToAnswer)/sum(CallsHandled)/60,':',format(sum(TotalTimeToAnswer)/sum(CallsHandled)%60,'00')) 
			else '0' end
		as AvgTimetoAnswerMinutes
	, CASE WHEN sum(CallsHandled) <> 0 then sum(TotalTalkTime)/sum(CallsHandled) 
			else '0' end
		as AvgTalkTime
	, CASE WHEN sum(CallsHandled) <> 0 then concat(sum(TotalTalkTime)/sum(CallsHandled)/60,':',format(sum(TotalTalkTime)/sum(CallsHandled)%60,'00')) 
			else '0' end 
		as AvgTalkTime_Formatted
from  DLDB.dbo.Agg_Tbl_Telephone_status 
	where --DNISReporting in ('9146145160','9146145493','9146145162')
		DNISName like '%BCBSIL%' or DNISName like '%HMOI%'
group by year(as_of_dt) 
	, month(AS_OF_DT)
	, data_src
	--, DNISName
	--, DNISReporting
order by 
	year(as_of_dt) DESC
	, month(AS_OF_DT) ASC
	, data_src
	--, DNISName ASC
	--, DNISReporting




SELECT
	year(as_of_dt) as YR
	, month(AS_OF_DT) as MTH
	, data_src
	, sum(CallsOffered) as TotalCallsOffered
	, sum(CallsHandled) as TotalCallsHandled
	, sum(CallsAbandoned) as TotalAbandoned
	, sum(CallsInterflowed) as TotalInterflowed
from  DLDB.dbo.Agg_Tbl_Telephone_status 
	where --DNISReporting in ('9146145160','9146145493','9146145162')
		DNISName like '%BCBSIL%' or DNISName like '%HMOI%'
group by year(as_of_dt) 
	, month(AS_OF_DT)
	, data_src
order by 
	year(as_of_dt) DESC
	, month(AS_OF_DT) ASC
	, data_src
;