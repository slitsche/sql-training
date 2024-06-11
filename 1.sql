
select last_analyze, last_autoanalyze from pg_stat_user_tables
 where relname = 'orders';

set max_parallel_workers_per_gather to 0;

create table tt (
   id serial,
   start_time timestamp,
   end_time timestamp
);

with ser as (
  select generate_series('2018-01-01', '2018-10-31', '1min'::interval) as s
)
insert into tt
  (start_time, end_time)
  select
ser.s, ser.s + '1h'::interval
  from ser;

explain analyze

select count(1)
 from tt
where start_time >= '2018-02-01'
  and end_time <= '2018-02-06'
 limit 1;

explain analyze
select count(1) from tt
where start_time >= '2018-02-01'
  and id <= 10;

create index on tt (start_time);

create index on tt (start_time, end_time);

analyze verbose tt;

\d tt

drop index tt_start_time_end_time_idx;


-- What about tsrange

alter table tt add column trange tsrange;

select tsrange(start_time, end_time) from tt limit 2;

update tt
   set trange = tsrange(start_time, end_time);

\timing

create index tt_gist_trange on tt using gist(trange);

create index on tt using gist(tsrange(start_time, end_time));

create index tt_btree_trange on tt using btree(trange);

explain analyze
select count(1) from tt
where '2018-02-02'::timestamp <@ trange;

select count(1)
 from tt
where tsrange('2018-02-01'::timestamp, '2018-02-06'::timestamp) @> trange
 limit 1;

drop index tt_btree_trange;

drop index tt_gist_trange;

select int4range(1,3) < int4range(2,3);

/*
with more than 400000 rows we switched from single to parallel execution

neither uses the indexes

We see the difference in order of magnitude for estimated and real rows.

->  Does this come from the dependency between attributes?
-> can we mitigate this with configuration?
*/

SELECT pg_relation_filepath('tt');

---------------------------------------------------------------------

create table func_usage(
   atime  timestamptz primary key
);


\d func_usage

with ser as (
  select generate_series('2018-01-01', '2018-10-31', '1min'::interval) as s
)
insert into func_usage
  (atime)
  select
ser.s
  from ser;


explain
select atime from func_usage where atime = '2018-10-19';

explain
select atime from func_usage where atime = clock_timestamp();

explain
select atime from func_usage where atime = current_timestamp;

create or replace function fnstable ()
returns timestamptz AS $$
  select clock_timestamp();

$$
language sql ;

explain
select atime from func_usage where atime = fnstable();

select proname, provolatile from pg_proc where proname = 'fnstable';

create or replace function fnstable ()
returns timestamptz AS $$
  select clock_timestamp();

$$
language sql
stable;


explain
select atime from func_usage where atime = fnstable();


----------------------------------------
-- top N pipelined
-- index used by order by clause

create index on orders (customerid);

explain analyze
select * from orders
where customerid = 123
order by orderdate desc
;

drop index orders_customerid_idx;

create index on orders (customerid, orderdate);

explain analyze
select * from orders
where customerid = 123
order by orderdate desc
;

drop index orders_customerid_orderdate_idx;

-- mind the min cost:  deliver first results faster
-- less execution steps!
-- lower costs


-------------------------------------------------------------------
--                 LIKE

explain
  select * from customers
   where username like 'Q%';

create index on customers (username varchar_pattern_ops);

\d customers

\di+ customers_username_idx


SELECT country,
       count(*) as customers,
       count(*)
FILTER (
 WHERE lastname like 'A%'
       ) AS withA
  FROM customers
 GROUP BY country;


SELECT customerid,  country, count(*) OVER(PARTITION BY country)
  FROM customers
 where customerid > 10
 ORDER BY customerid
 LIMIT 10;

\d customers

SELECT
    array_agg(zip ORDER BY zip)
  FROM (
    SELECT zip FROM customers
     LIMIT 5) AS a;


WITH data AS (
  SELECT 'some' AS description,
  '{1,2,3}'::int[] AS int_array
  UNION ALL
  SELECT 'numbers',
  '{4,5,7}'
  )
SELECT description, int_array, prime
FROM data, LATERAL UNNEST (int_array) as prime
;

/*
we can access previous lateral via select from base table
*/
WITH data AS (
  SELECT 'some' AS description,
  '{1,2,3}'::int[] AS int_array
  UNION ALL
  SELECT 'numbers',
  '{4,5,7}'
  )
SELECT description, int_array, AA.anum, a2n
FROM data
 LEFT JOIN LATERAL UNNEST (int_array) as AA (anum) ON true
 LEFT JOIN LATERAL (select anum * 2 a2n from data) AS a2num ON true
;

select percentile_disc(0.5) within group (order by x),
       percentile_cont(0.5) within group (order by x)
  from (values (1), (2), (3), (4)) a(x);

-------------------------------------------------
--  Side Effect in CTE
-------------------------------------------------

begin;

with get as (
select a,b from s),
ins1 as (
insert into s
select * from get)
insert into s
select * from get;


select count(1) from products;

\d products


select * from categories;

select category, count(1) from products
group by category;

select orderdate,
       date_trunc('week', orderdate) as week,
       netamount,
       avg(netamount) over ()
  from orders
 limit 20;

select orderdate,
       date_trunc('week', orderdate) as week,
       netamount,
       avg(netamount) over (partition by date_trunc('week', orderdate))
  from orders
 offset 200 limit 20;


select orderdate,
       date_trunc('week', orderdate) as week,
       netamount,
       avg(netamount) over (partition by date_trunc('week', orderdate) order by orderdate)
  from orders
 offset 20 limit 20;

with A as (
select 1 as x, '{2,3,4}'::int[] as b
union all
select 5, '{}'::int[])
select * from a, unnest(b);



with A as (
select 1 as x, '{2,3,4}'::int[] as b
union all
select 5, '{}'::int[])
select * from a left join lateral unnest(b) on true;

---

-- this does not work before Postgres 11
select bar,
  count(bar) over (order by bar RANGE between 0.7 preceding and current row)
from (values (0), (0.1), (0.3), (1), (0.3)) as foo(bar)
;

-- new is also frame_exclusion part of frame definition
select bar,
  count(bar) over (order by bar RANGE between 0.7 preceding and current row EXCLUDE GROUP)
from (values (0), (0.1), (0.3), (1), (0.3)) as foo(bar)
;



 SELECT
  country,
  count(distinct o.customerid) AS active,
  count(distinct
        CASE country
        WHEN 'Australia' THEN o.customerid
        END) AS AUS
   FROM customers c
   LEFT JOIN orders o
          on o.customerid = c.customerid
  GROUP BY country;


select count(*), count(distinct x)
  from (values(1),(NULL)) AS t(x);

select count(*), count(distinct x), count(x)
  from (values(1,2),(NULL,NULL)) AS t(x, y);


/*

ERROR:  window functions are not allowed in WHERE
LINE 4:  where rank() over (order by customerid) = 1

that's why the spark dataframe api is sometimes quite succint
*/
select customerid
 --, rank() over (order by customerid)
from customers
 where rank() over (order by customerid) = 1
limit 1000;



SELECT a, b, count(*)
  FROM s
 GROUP BY a,b
UNION ALL
SELECT null, null, count(*)
  FROM s;


SELECT
   customerid, city,
   count(orderid)
  FROM customers AS c
  NATURAL JOIN orders
 GROUP BY c.customerid
 LIMIT 10;


\d customers
