use mavenfuzzyfactory;
/*Yêu cầu 1 */ Find the sites with the most views
select STR_TO_DATE('09/06/2012', '%d/%m/%Y');
SET sql_mode=(SELECT REPLACE(@@sql_mode,'ONLY_FULL_GROUP_BY',''));
select 
		pageview_url,
        count(distinct website_pageview_id) as pvs
from website_pageviews
where created_at <  str_to_date('09/06/2012','%d/%m/%y')
group by 1
order by 2 desc;


/*yêu cầu 2 */ Find the total number of sessions accessing each website for the first time
select STR_TO_DATE('12/06/2012', '%d/%m/%Y');
create temporary table first_pv_per_session
select
website_session_id,
 min(website_pageview_id) as first_pv
from website_pageviews
where created_at < STR_TO_DATE('12/06/2012', '%d/%m/%Y')
group by website_session_id;


SET sql_mode=(SELECT REPLACE(@@sql_mode,'ONLY_FULL_GROUP_BY',''));
select 
        w.pageview_url as landing_page_url,
        count(w.website_session_id) as sessions_hitting_page
from first_pv_per_session as f left join website_pageviews as w on f.first_pv=w.website_pageview_id
group by 1;
--------------------------------------------------------------------------------------------- 
/*yêu cầu 3 */ Landing page analysis
-- Bảng first_pageviews để tìm ra các website_id được truy cập đầu tiên
select STR_TO_DATE('14/06/2012', '%d/%m/%Y');
create temporary table first_pageviews
select
website_session_id,
 min(website_pageview_id) as min_pageview_id
from website_pageviews
where created_at < STR_TO_DATE('14/06/2012', '%d/%m/%Y')
group by website_session_id;
create temporary table session_w_home_landing_page
select 
first_pageviews.website_session_id,
website_pageviews.pageview_url as landing_page
from first_pageviews
left join website_pageviews
on website_pageviews.website_pageview_id = 
first_pageviews.min_pageview_id
where website_pageviews.pageview_url = '/home';
/* bảng bounced_sessions để tìm ra các session chỉ chứa 1 một trang web là /home, 
nếu session chỉ truy cập duy nhất 1 trang là /home thì cũng đồng nghĩa session này đã xảy 
ra tình trạng thoát phiên*/
create temporary table bounced_sessions
select 
session_w_home_landing_page.website_session_id,
 session_w_home_landing_page.landing_page,
 count(website_pageviews.website_pageview_id) as count_of_pages_viewed
from session_w_home_landing_page
left join website_pageviews
on website_pageviews.website_session_id = 
session_w_home_landing_page.website_session_id
group by 
session_w_home_landing_page.website_session_id,
 session_w_home_landing_page.landing_page
having
count(website_pageviews.website_pageview_id) = 1;
/*truy vấn này để tìm ra những phiên có trong bảng session_w_home_landing_page 
nhưng không có trong bảng bounced_sessions, những phiên không có trong bảng 
bounced_sessions chính là những phiên xảy ra tình trạng thoát phiên*/
SET sql_mode=(SELECT REPLACE(@@sql_mode,'ONLY_FULL_GROUP_BY',''));
select 
count(session_w_home_landing_page.website_session_id),
count(distinct bounced_sessions.website_session_id) as bounced_website_session_id,
count(bounced_sessions.website_session_id)/count(session_w_home_landing_page.website_session_id) as bounced_rate
from session_w_home_landing_page
left join bounced_sessions
on session_w_home_landing_page.website_session_id = 
bounced_sessions.website_session_id
order by 1;
--------------------------------------------------------------------------------------------------------
/*yêu cầu 4*/ A/B testing
-- Bước 1: Viết câu truy vấn để tìm ra ngày đầu tiên mà ‘/lander-1’ được thêm vào:
select
min(created_at) as first_created_at,
 min(website_pageview_id) as first_pageview_id
from website_pageviews
where pageview_url = '/lander-1' and created_at is not null;
-- Bước 2: lọc ra các web_pageview_id trong khoảng thời gian '/lander-1' đã được thêm
SET sql_mode=(SELECT REPLACE(@@sql_mode,'ONLY_FULL_GROUP_BY',''));
select STR_TO_DATE('28/07/2012', '%d/%m/%Y');
create temporary table first_test_pageviews
select
website_pageviews.website_session_id,
 min(website_pageviews.website_pageview_id) as min_pageview_id
from website_pageviews
inner join website_sessions
on website_sessions.website_session_id = 
website_pageviews.website_session_id
and website_sessions.created_at < STR_TO_DATE('28/07/2012', '%d/%m/%Y')
and website_pageviews.website_pageview_id > 23504
 and utm_source = 'gsearch'
and utm_campaign = 'nonbrand'
group by 1;

-- Bước 3: map web_pageview_id và landing page (/home, /lander-1)
create temporary table nonbrand_test_session_w_landing_page
select
first_test_pageviews.website_session_id as session1,
 website_pageviews.pageview_url as landing_page
from first_test_pageviews
left join website_pageviews
on website_pageviews.website_pageview_id = 
first_test_pageviews.min_pageview_id
where website_pageviews.pageview_url in ('/home', '/lander-1');

-- Bước 4: Viết truy vấn lọc ra các web_session_id bị thoát phiên 
SET sql_mode=(SELECT REPLACE(@@sql_mode,'ONLY_FULL_GROUP_BY',''));
create temporary table bounced_session
select 
nonbrand_test_session_w_landing_page.session1 as session2,
nonbrand_test_session_w_landing_page.landing_page,
count(website_pageviews.website_pageview_id) as count_of_pageviews
from nonbrand_test_session_w_landing_page left join website_pageviews
on nonbrand_test_session_w_landing_page.session1 = website_pageviews.website_session_id
group by 1,2
having count(website_pageviews.website_pageview_id) =1 ;

-- Bước 5: Viết truy vấn tính tỷ lệ thoát phiên của trang '/home', '/lander-1' 
select
	nonbrand_test_session_w_landing_page.landing_page,
    count(distinct nonbrand_test_session_w_landing_page.session1) as sessions,
    count(distinct bounced_session.session2) as bounced_sessions,
    count(distinct bounced_session.session2)/count(distinct nonbrand_test_session_w_landing_page.session1)
    as bounced_rate
from nonbrand_test_session_w_landing_page left join bounced_session
		on nonbrand_test_session_w_landing_page.session1 = bounced_session.session2
group by 1;

------------------------------------------------------------------- 
/*yêu cầu 5*/ Show site-wide session bounce rate by week
SET sql_mode=(SELECT REPLACE(@@sql_mode,'ONLY_FULL_GROUP_BY',''));
select STR_TO_DATE('01/06/2012', '%d/%m/%Y') and str_to_date('31/08/2012', '%d/%m/%Y');
create temporary table sessions_w_min_pv_id_and_view_count
select
website_sessions.website_session_id,
 min(website_pageviews.website_pageview_id) as first_pageview_id,
 count(website_pageviews.website_pageview_id) as count_pageviews
from website_sessions
left join website_pageviews
on website_sessions.website_session_id = 
website_pageviews.website_session_id
where website_sessions.created_at > '2012-06-01'
and website_sessions.created_at < '2012-08-31'
 and website_sessions.utm_source = 'gsearch'
 and website_sessions.utm_campaign = 'nonbrand'
group by
website_sessions.website_session_id;

/* Bước 2: Tạo bảng tạm để đếm số lượng count_pageviews trong mỗi phiên => mục 
đích để lọc ra các phiên bị thoát ở bước sau */
create temporary table sessions_w_counts_lander_and_created_at
select
sessions_w_min_pv_id_and_view_count.website_session_id as session1,
 sessions_w_min_pv_id_and_view_count.first_pageview_id,
 sessions_w_min_pv_id_and_view_count.count_pageviews as pageviews,
 website_pageviews.pageview_url as landing_page,
 website_pageviews.created_at as session_created_at
from sessions_w_min_pv_id_and_view_count
left join website_pageviews
on sessions_w_min_pv_id_and_view_count.first_pageview_id = 
website_pageviews.website_pageview_id
having (sessions_w_min_pv_id_and_view_count.count_pageviews)=1;

/*Bước 3: Hiển thị tỷ lệ thoát phiên trên toàn trang web theo tuần, đồng thời hiển thị cả số 
phiên được phân vào /home và số phiên được phân vào /lander-1 */

select
min(date(sessions_w_counts_lander_and_created_at.session_created_at)) as week_start_date,
week(sessions_w_counts_lander_and_created_at.session_created_at) as weeks,
sessions_w_counts_lander_and_created_at.session1,
count(sessions_w_counts_lander_and_created_at.pageviews) as total_sessions,
count(sessions_w_counts_lander_and_created_at.pageviews)/sessions_w_counts_lander_and_created_at.session1 as bounce_sessions,
count(distinct case when sessions_w_counts_lander_and_created_at.landing_page = '/home' 
then sessions_w_counts_lander_and_created_at.session1 else null end ) as home_session,
count(distinct case when sessions_w_counts_lander_and_created_at.landing_page = '/lander-1' 
then sessions_w_counts_lander_and_created_at.session1 else null end ) as lander1_session
from sessions_w_counts_lander_and_created_at join website_pageviews
on sessions_w_counts_lander_and_created_at.session1 = website_pageviews.website_session_id
group by 2;

