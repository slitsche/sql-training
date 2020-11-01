\timing on

select name, setting, unit
  from pg_settings
 where name like '%page_cost';

explain select * from customers;

explain select lastname from customers where country = 'South Africa';

explain (analyze)
select country from customers where country = 'South Africa' ;

explain (analyze)
select country from customers where country < 'Chile' ;

explain (analyze, buffers)

select lastname from customers order by country desc NULLS first limit 2;

explain-- (analyze, buffers)
select count(*) from customers where country = 'South Africa' group by country;

explain-- (analyze, buffers)
select country, count(*) from customers group by country;

select relname, relpages, reltuples, relkind
  from pg_class
 where oid = 'public.customers'::regclass;

select relname, relpages, reltuples, relkind
  from pg_class
 where oid = 'public.customer_country_idx'::regclass;

create index customer_country_idx on customers (country);

explain (analyze)
 select count(*) from customers
  where country = 'South Africa' ;

explain (analyze, buffers)
select lastname from customers where username = 'user1';

drop index customer_country_idx;

select distinct country from customers;

\d+ customers

select zip, count(*) from customers group by zip order by 2 desc limit 10;

create index zip_slow on customers (country, zip);

create index zip_fast on customers (zip, country);

drop index zip_fast;

explain (analyze, buffers, verbose, timing)
 select lastname from customers where zip = 36223;

drop index orders_orderdate_idx;

EXPLAIN
 SELECT firstname, lastname FROM CUSTOMERS
  ORDER BY country ASC, zip DESC;

create index multi_mixed ON customers (country ASC, zip DESC);

EXPLAIN
 SELECT lastname FROM customers ORDER BY country ASC;

create index orders_orderdate_idx on orders (orderdate);

--explain (analyze, buffers)
 select count(*) from orders where extract('month' from orderdate) = 1;

--explain (analyze, buffers)
 select count(*) from orders where orderdate >= '2004-01-01' and orderdate < '2004-02-01';

\d orders

---------------------- pipelined group by  ----------------------
select name, setting from pg_settings where category = 'Query Tuning / Planner Method Configuration';

set enable_bitmapscan=on;

explain analyze
select lastname, firstname, city
  from customers
 where lastname > 'Z'
 order by firstname desc;

explain analyze
select * from orders o
where customerid  in (
   select customerid from customers c where o.customerid = c.customerid and state = 'AZ');

explain analyze
select * from orders o
where exists (
   select customerid from customers c where o.customerid = c.customerid and state = 'AZ');

set enable_hashjoin to false;

explain analyze
select * from orders
where customerid in (
   select customerid from customers where state = 'AZ');


explain --(costs off) --analyze
select o.*
  from orders AS o
  natural join customers AS c
  where state = 'AZ';

explain analyze
select * from orders
where customerid in (
   select custmerid from customers where state = 'AZ')
 order by orderid;


SELECT am.amname AS index_method,
       opc.opcname AS opclass_name,
       opc.opcintype::regtype AS indexed_type,
       opc.opcdefault AS is_default
    FROM pg_am am, pg_opclass opc
    WHERE opc.opcmethod = am.oid
      --and opc.opcname = 'range_ops'
      and am.amname = 'hash'
    ORDER BY index_method, opclass_name;

select * from pg_opclass
 where opcname = 'text_ops'
limit 3;

prod_eventlog_db=# explain select * from zel_event.e96001_order_created where "customerNumber" in (select "customerNumber" from zel_event.e60006_return_order_received where "shipmentNumber" = '1041020079573759');
                                                                                        QUERY PLAN
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Nested Loop  (cost=38.71..207.00 rows=86 width=93)
   ->  HashAggregate  (cost=27.56..27.66 rows=2 width=11)
         Group Key: e60006_return_order_received."customerNumber"
         ->  Append  (cost=10.90..27.46 rows=2 width=11)
               ->  Index Scan using "e60006_return_order_received_shipmentNumber_idx" on e60006_return_order_received  (cost=10.90..13.50 rows=1 width=11)
                     Index Cond: ("shipmentNumber" = '1041020079573759'::text)
G               ->  Index Scan using "e60006_return_order_received_shipmentNumber_idx" on e60006_return_order_received e60006_return_order_received_1  (cost=11.35..13.96 rows=1 width=11)
                     Index Cond: ("shipmentNumber" = '1041020079573759'::text)
   ->  Append  (cost=11.15..87.37 rows=46 width=93)
         ->  Index Scan using "e96001_order_created_customerNumber_idx" on e96001_order_created  (cost=11.15..15.11 rows=2 width=94)
               Index Cond: ("customerNumber" = e60006_return_order_received."customerNumber")
         ->  Index Scan using "e96001_order_created_customerNumber_idx" on e96001_order_created e96001_order_created_1  (cost=11.40..72.26 rows=44 width=93)
               Index Cond: ("customerNumber" = e60006_return_order_received."customerNumber")
(13 rows)

prod_eventlog_db=# \e
explain select * from zel_event.e96001_order_created c where "customerNumber" in (
   select "customerNumber" from zel_event.e60006_return_order_received r where c."customerNumber" = r."customerNumber" and "shipmentNumber" = '1041020079573759');                                                                           QUERY PLAN
-----------------------------------------------------------------------------------------------------------------------------------------------------------------
 Append  (cost=0.00..3871477127.01 rows=109969592 width=93)
   ->  Seq Scan on e96001_order_created c  (cost=0.00..78039581.72 rows=2212272 width=94)
         Filter: (SubPlan 1)
         SubPlan 1
           ->  Append  (cost=8.40..26.46 rows=2 width=11)
                 ->  Index Scan using "e60006_return_order_received_customerNumber_idx" on e60006_return_order_received r  (cost=8.40..12.46 rows=1 width=11)
                       Index Cond: (c."customerNumber" = "customerNumber")
                       Filter: ("shipmentNumber" = '1041020079573759'::text)
                 ->  Index Scan using "e60006_return_order_received_shipmentNumber_idx" on e60006_return_order_received r_1  (cost=11.35..14.01 rows=1 width=11)
                       Index Cond: ("shipmentNumber" = '1041020079573759'::text)
                       Filter: (c."customerNumber" = "customerNumber")
   ->  Seq Scan on e96001_order_created c_1  (cost=0.00..3793437545.29 rows=107757320 width=93)
         Filter: (SubPlan 1)
(13 rows)


-------------------------------------
-- improve query with a date verify the index only scan in subquery

DROP table t2colpk;

create table t2colpk (a , b ) as
select * from
generate_series(1,100000) as a
cross join
generate_series('2019-05-01'::timestamptz,'2019-05-03'::timestamptz, '1 day'::interval) as b;

ALTER table t2colpk add primary key (a,b);

explain analyze
select *
  from t2colpk o
 where a = 1
   and b = (select max(b) from t2colpk i where o.a = i.a);

explain analyze
select *
  from t2colpk o
 where a = 1
   and b = (select max(b) from t2colpk i where i.a = 1);

create table tdoublet (
       a, b)
    as select * from (values
    (1,2),
    (1,2),
    (2,3),
    (3,4)
) as x;

explain (analyze on, costs on, buffers on)
select a,b
  from tdoublet
 where a in (
       select a
         from tdoublet
        group by a
        having count(1) > 1);

EXPLAIN (analyze on, costs on, buffers on)
WITH cand AS (
    SELECT lastname,
        count(1) OVER
            (PARTITION BY lastname RANGE CURRENT ROW) as c
    FROM customers)
SELECT lastname FROM cand
 WHERE c > 1;

--explain (analyze, buffers, verbose)
explain (analyze on, costs off)
select a,b from (
select a,b,
       count(1) over (partition by a range current row) as c
  from tdoublet) as x
 where c = 2;

explain analyze
with cand as (
select a,b,
       count(1) over (partition by a range current row) as c
  from tdoublet)
select a, b from cand
 where c > 1;

\d customers

explain (costs off, analyze on, buffers on)
select lastname
  from customers
 where lastname in (
       select lastname
         from customers
        group by lastname
        having count(1) > 1);

explain (costs off, analyze on, buffers on)
with cand as (
select lastname,
       count(1) over (partition by lastname range current row) as c
  from customers)
select lastname from cand
 where c > 1;

/*  introduce a real duplicate
*/

select customerid, lastname from customers limit 2;

begin;
update customers set lastname = 'UNUKXHJVXB' where customerid = 1;

abort;

-----------------------------
/*
Multi-column index use in an setup with multiple rows per key
*/

\d sli_stat_testdata

create index slow_index on sli_stat_testdata (log1_fewval, log2_fewval);

create index fast_index on sli_stat_testdata (log2_fewval, log1_fewval);

drop index fast_index;

explain (analyze, verbose, buffers)
select id from sli_stat_testdata where log2_fewval = 0;



---------------------------  Functions

\d orders


explain select * from orders where orderdate = '2014-01-01';

explain select * from orders where orderdate = clock_timestamp();

explain select * from orders where orderdate = date_trunc('day',clock_timestamp()) - '1day'::interval;

explain select * from orders where orderdate = date_trunc('day',clock_timestamp() - '1day'::interval);

explain select * from orders where orderdate = 'yesterday';




----- --------- --------- -------- Dependencies

CREATE TABLE t1 (
    a   int,
    b   int
);

INSERT INTO t1 SELECT i/100, i/500
                 FROM generate_series(1,1000000) s(i);

ANALYZE t1;

-- the number of matching rows will be drastically underestimated:
EXPLAIN ANALYZE SELECT * FROM t1 WHERE (a = 1) AND (b = 0);

CREATE STATISTICS s1 (dependencies) ON a, b FROM t1;

ANALYZE t1;

-- now the row count estimate is more accurate:
EXPLAIN ANALYZE SELECT * FROM t1 WHERE (a = 1) AND (b = 0);

PREPARE ts1 AS
  SELECT * FROM t1 WHERE (a = $1) AND (b = $2);

explain execute ts1 (1,0);

deallocate ts1;

DROP STATISTICS s1;


select name, setting from pg_settings
 where name like '%enable%';


explain select * from t1 where a in (1, 2);

explain select * from t1 where a between 1 and 2;


/*
pagination
*/

explain (analyze, buffers)
select *
  from customers
  order by customerid
  limit 5
  offset 100;

\d customers

explain (analyze, buffers)
select *
  from customers
 where customerid > 100
   and customerid < 106
 order by customerid;
 
