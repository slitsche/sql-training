explain WITH receiveblock as
(
select
  event_time gtatime
  ,workplace wp
  ,"scanData2" block
  ,"userId" ma
  ,right("scanData1",2) source
  ,case
      when lag(lower("scanData2")) over (partition by workplace,"userId" order by event_time) = 'start'
         then lag(event_time) over (partition by workplace,"userId" order by event_time)
      else null
   END as startblock
  ,case
      when lower("scanData2") = 'end' then event_time
      ELSE null
   END as endblock
From zel_event.e6810a_generic_time_allocation
inner Join zel_data.log_instance
   ON li_id = instance_id AND li_instance like '48%'
Where left(lower("scanData1"),17) = 'reloreplenishment'
  and event_time >= date_trunc('month', (CURRENT_DATE-15)::TIMESTAMP)
  and event_time < date_trunc('month', (CURRENT_DATE-15)::TIMESTAMP) + interval '1 month'
)
,SUMMARY as
(
select
    event_time
   ,"qualityLabel"
   ,sku
   ,ean
   ,workplace
   ,startblock
   ,endblock
   ,source
from receiveblock
inner join zel_event.e68004_receive_receive_item
   on "userId" = ma and wp = workplace
inner JOIN zel_data.log_instance
   ON li_id = instance_id AND li_instance like '48%'
where event_time >= date_trunc('month', (CURRENT_DATE-15)::TIMESTAMP)
  and event_time < date_trunc('month', (CURRENT_DATE-15)::TIMESTAMP) + interval '1 month'
  and event_time > startblock
  and event_time < endblock
)
select
   to_char(event_time,'YYYY-MM-DD HH24:MI:SS') event_time
  ,"qualityLabel"
  ,sku::varchar(100)
  ,ean
  ,"source"
from SUMMARY
;
