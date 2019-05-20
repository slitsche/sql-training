\timing on

select name, setting, unit
  from pg_settings
 where name like '%page_cost';

explain select * from orders;

explain (buffers, analyze) select * from orders where orderid = 42;

\d pg_class

select relname, relpages, reltuples, relkind
  from pg_class
 where oid = 'public.orders'::regclass;



\d+ customers

explain
select * from orders
where customerid in (
   select customerid from customers where state = 'AZ');

explain
select * from orders o
where customerid  in (
   select customerid from customers c where o.customerid = c.customerid and state = 'AZ');

explain
select * from orders
where customerid in (
   select customerid from customers where state = 'AZ')
 order by orderid;


SELECT am.amname AS index_method,
       opc.opcname AS opclass_name,
       opc.opcintype::regtype AS indexed_type,
       opc.opcdefault AS is_default
    FROM pg_am am, pg_opclass opc
    WHERE opc.opcmethod = am.oid
    ORDER BY index_method, opclass_name;
    
prod_eventlog_db=# explain select * from zel_event.e96001_order_created where "customerNumber" in (select "customerNumber" from zel_event.e60006_return_order_received where "shipmentNumber" = '1041020079573759');
                                                                                        QUERY PLAN                                                                                        
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Nested Loop  (cost=38.71..207.00 rows=86 width=93)
   ->  HashAggregate  (cost=27.56..27.66 rows=2 width=11)
         Group Key: e60006_return_order_received."customerNumber"
         ->  Append  (cost=10.90..27.46 rows=2 width=11)
               ->  Index Scan using "e60006_return_order_received_shipmentNumber_idx" on e60006_return_order_received  (cost=10.90..13.50 rows=1 width=11)
                     Index Cond: ("shipmentNumber" = '1041020079573759'::text)
               ->  Index Scan using "e60006_return_order_received_shipmentNumber_idx" on e60006_return_order_received e60006_return_order_received_1  (cost=11.35..13.96 rows=1 width=11)
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

explain (analyze on, costs off)
select a,b
  from tdoublet
 where a in (
       select a
         from tdoublet
        group by a
        having count(1) > 1);

--explain (analyze, buffers, verbose)
explain (analyze on, costs off)
select a,b from (
select a,b,
       count(1) over (partition by a range current row) as c
  from tdoublet) as x
 where c = 2;



-----------------------------

\dt
