use mavenfuzzyfactory;
SET sql_mode=(SELECT REPLACE(@@sql_mode,'ONLY_FULL_GROUP_BY',''));
/*yêu cầu 1*/
select STR_TO_DATE('12/04/2012', '%d/%m/%Y');
select
        utm_source,utm_campaign,http_referer,
		count(distinct website_session_id) as number_session
from website_sessions
where created_at < STR_TO_DATE('12/04/2012', '%d/%m/%Y')
group by utm_campaign
order by number_session desc;

/*yêu cầu 2*/ 
select STR_TO_DATE('14/04/2012', '%d/%m/%Y');
select
        utm_source,utm_campaign,
		count( distinct w.website_session_id) as number_session,
        count(distinct o.order_id) as orders,
        count(distinct o.order_id)/count(distinct w.website_session_id) as CVR
from website_sessions as w left join orders as o on w.website_session_id=o.website_session_id
where w.created_at < STR_TO_DATE('14/04/2012', '%d/%m/%Y')
and utm_source ='gsearch'
and utm_campaign='nonbrand';

/*yêu cầu 3*/ 
select STR_TO_DATE('15/05/2012', '%d/%m/%Y');
select		
        /*created_at,
        week(created_at),*/
        min(date(created_at)) as start_of_week,
        count(website_session_id) as number_session
from website_sessions
where created_at < STR_TO_DATE('15/05/2012','%d/%m/%Y')
and utm_source ='gsearch'
and utm_campaign='nonbrand'
group by week(created_at);

/*yêu cầu 4*/ 
select STR_TO_DATE('11/05/2012', '%d/%m/%Y');
 select
		w.device_type,
		count( w.website_session_id) as number_session,
        count( o.order_id) as orders,
        count(o.order_id)/count(w.website_session_id) as CVR
from website_sessions as w left join orders as o 
on w.website_session_id=o.website_session_id
where w.created_at < STR_TO_DATE('11/05/2012', '%d/%m/%Y')
and utm_source ='gsearch'
and utm_campaign='nonbrand'
group by 1 
order by 3 desc;

/*yêu cầu 5*/ 
select STR_TO_DATE('15/04/2012', '%d/%m/%Y');
select		
        min(date(created_at)) as start_of_week,
       /*week(created_at),
        device_type,*/
      count( website_session_id) as number_session,
       count( case when device_type = 'desktop' 
       then website_session_id else null end) as Desktop,
        count( case when device_type = 'mobile' 
        then website_session_id else null end) as Mobile
from website_sessions
where created_at > STR_TO_DATE('15/04/2012','%d/%m/%Y')
and utm_source ='gsearch'
and utm_campaign='nonbrand'
group by week(created_at),
		year(created_at)
order by 1 asc;