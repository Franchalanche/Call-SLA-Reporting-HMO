SELECT TOP (1000) [Group]
      ,[ENDDATE]
      ,[Client]
      ,[AcdCallsOffered]
      ,[AcdCallsHandled]
      ,[CallsAbandoned_Long]
      ,[AvgSpeedOfAnswer_hhmmss]
      ,[ACDHandlingTime]
      ,[AvgSpeedToAnswer_Seconds]
      ,[Abandoned_Pct]
      ,[TotalDuration]
      ,[AvgDuration]
      ,[SpeedCallsHandled]
      ,[Yr]
      ,[Mo]
      ,[MaxDateInTheMonth]
      ,[MTD_Days]
      ,[BOM_Days]
      ,[Adjustment]
      ,[ASA Threshold]
      ,[Abandon Threshold]
      ,[Min Calls Threshold]
      ,[Projected_Handled]
      ,[AvgSpeedToHitThreshold]
      ,[ProjectedOffered]
      ,[AbandonToHitThreshold]
      ,[CheckFlag]
  FROM [WorkBench].[dbo].[vw_SLA_Operations_Calls]

  select *
    FROM [WorkBench].[dbo].[vw_SLA_Operations_Calls]
where Client like '%%'

SELECT TOP 100 *
FROM dldb.DBO.dl_dw_ccm_win_custom_AgentInboundCallDetails
where DNISName like '%HMOI%'

select distinct DNISName
	, DateofCall
	, TimeToAnswer
FROM dldb.DBO.dl_dw_ccm_win_custom_AgentInboundCallDetails
where DNISName like '%HMOI%'


DROP TABLE IF EXISTS #Call_Compliance;
select distinct DNISName
	, DNISReporting
	, month(DateofCall) as Mth
	, year(DateOfCall) as YR
	, DateofCall
	, TimeToAnswer
	, case when TimeToAnswer <= 10 then 1 else TimeToAnswer-10 END as Adis_Time
	, case when TimeToAnswer <= 25 then 1 else TimeToAnswer-25 END as ARTs_Time
	, CASE WHEN TimeToAnswer <=30 then 1 else 0 end as Time_Compliance
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

DROP TABLE IF EXISTS #Monthly_Answered_Percent;
select DISTINCT
	DNISName
	, DNISReporting
	, Year(as_of_dt) as YR
	, Month(as_of_dt) as MTH
	, case when sum(CallsOffered)= 0 then 0 
		else sum(CallsHandled)*1.0/sum(CallsOffered)*1.0 
		end as Answer_Percentage
INTO #Monthly_Answered_Percent
FROM DLDB.dbo.Agg_Tbl_Telephone_status
where DNISName like '%HMOI%'
Group by DNISName
	, DNISReporting
	, Year(as_of_dt) --as YR
	, Month(as_of_dt) --as MTH
;

select '' '#Monthly_Answered_Percent';
select * from #Monthly_Answered_Percent
order by YR DESC
	, MTH
	, DNISReporting;


select 'Regular Compliance %' '#Call_Compliance';
select distinct
	DNISName
	, DNISReporting
	, YR
	, MTH
	, count(*) as Total_Calls
	--, sum(Time_Compliance) as Time_Compliance_Total
	, sum(Time_Compliance)*1.0/count(*)*1.0 as [Time Compliance %]
	--, sum(Adis_Time_Compliance) as Adis_Time_Compliance_Total
	, sum(Adis_Time_Compliance)*1.0/count(*)*1.0 as [Adis Time Compliance %]
	--, sum(ARTs_Time_Compliance) as ARTs_Time_Compliance_Total
	, sum(ARTs_Time_Compliance)*1.0/count(*)*1.0 as [ARTs Time Compliance %]
from #Call_Compliance
GROUP BY DNISName
	, DNISReporting
	, YR
	, MTH
order by YR DESC
	, mth
	, DNISReporting
;


select 'WEIGHTED BY ANSWER %' '#Call_Compliance';
select distinct
	  cc.DNISName
	, cc.DNISReporting
	, cc.YR
	, cc.MTH
	, count(*) as Total_Calls
	--, sum(Time_Compliance) as Time_Compliance_Total
	, (sum(Time_Compliance)*1.0/count(*)*1.0)*m.Answer_Percentage as [Time Compliance %]
	--, sum(Adis_Time_Compliance) as Adis_Time_Compliance_Total
	, (sum(Adis_Time_Compliance)*1.0/count(*)*1.0)*m.Answer_Percentage as [Adis Time Compliance %]
	--, sum(ARTs_Time_Compliance) as ARTs_Time_Compliance_Total
	, (sum(ARTs_Time_Compliance)*1.0/count(*)*1.0)*m.Answer_Percentage as [ARTs Time Compliance %]
from #Call_Compliance cc
JOIN #Monthly_Answered_Percent m
	on cc.DNISName = m.DNISName
		and cc.DNISReporting = m.DNISReporting
		and cc.YR= m.YR
		and cc.MTH = m.MTH
GROUP BY cc.DNISName
	, cc.DNISReporting
	, cc.YR
	, cc.MTH
	, m.Answer_Percentage
order by cc.YR DESC
	, cc.mth
	, cc.DNISReporting
;
