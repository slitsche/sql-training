create table c as select generate_series(1,10) as a;

select * from c;

select a, sum(a) over() from c;

select a, sum(a) over w, count(*) over w
  from c
window w as ();

-- what are the defaults
select a, sum(a) over w,
          count(*) over w
 from c
window w as (RANGE BETWEEN
UNBOUNDED PRECEDING AND CURRENT ROW);

-- no partition, no order
-- current row has different meaning!!

select a, sum(a) over w,
          count(*) over w
 from c
window w as (rows BETWEEN
UNBOUNDED PRECEDING AND CURRENT ROW);


select a, sum(a) over(ROWS BETWEEN CURRENT ROW AND
UNBOUNDED FOLLOWING) from c;

-- what does current row mean
select a, sum(a) over w,
          count(*) over w
  from c
window w as (RANGE CURRENT ROW);

select a, sum(a) over w,
          count(*) over w
  from c
window w as (ROWS CURRENT ROW);


--example followin
select a, sum(a) over w,
          count(a) over w
  from c
window w as (ROWS between CURRENT ROW and 1 FOLLOWING);


-- CURRENT ROW peers are rows with equal values for ORDER BY columns,
-- or all partition rows if ORDER BY is not specified
select a, sum(a) over w,
          count(a) over w
  from c
window w as (order by a);

-- note: this default again with range mode as default frame

select a, sum(a) over w
  from c
window w as (order by a RANGE between UNBOUNDED PRECEDING and CURRENT ROW);

select a, sum(a) over w,
          count(*) over w
  from c
window w as (order by a RANGE CURRENT ROW);


--  Look at table with duplicates

CREATE TABLE d AS
SELECT ceil(a/2.0) AS a
FROM generate_series(1, 10) AS f(a);

select * from d;

-- compare empty window spec
select a, sum(a) over w,
          count(*) over w
  from d
window w as ();

-- order range
select a, sum(a) over w,
          count(*) over w
  from d
window w as (order by a);

-- with defaults explicitly given
select a, sum(a) over w,
          count(*) over w
  from d
window w as (ORDER BY a
             RANGE BETWEEN UNBOUNDED PRECEDING
                   AND CURRENT ROW);

-- Rows
select a, sum(a) over w,
          count(*) over w
  from d
window w as (ORDER BY a
             ROWS BETWEEN UNBOUNDED PRECEDING
                   AND CURRENT ROW);

-- range on current row
select a, sum(a) over w,
          count(*) over w
  from d
window w as (ORDER BY a
             RANGE CURRENT ROW);
-- the frame current rows in range mode contains all dublicates

-- rows on current row
select a, sum(a) over w,
          count(*) over w
  from d
window w as (order by a
             ROWS CURRENT ROW);

-- partitioning

select a, sum(a) over w,
          count(*) over w
  from d
window w as (PARTITION BY a);


select a, sum(a) over w,
          count(*) over w
  from d
window w as (PARTITION BY a < 3)
  order by a;

select a, sum(a) over w,
          count(*) over w
  from d
window w as (
       PARTITION BY a < 3
       ORDER BY a
       --range between unbounded preceding and unbounded following
)
  order by a;

select a, sum(a) over w,
          count(*) over w
  from d
window w as (
       PARTITION BY a < 3
       ORDER BY a
       RANGE between UNBOUNDED PRECEDING and CURRENT ROW
)
  order by a;

select  a, sum(a) over w,
          count(*) over w
  from d
window w as (
       PARTITION BY a < 3
       ORDER BY a
       ROWS between UNBOUNDED PRECEDING and CURRENT ROW
)
order by int4(a>=3), 3;


select a, a % 2, sum(a) over(partition by (a < 3) order by a) 
from d order by a;

SELECT customerid, country, netamount,
       --count(*)       OVER (cty),
       sum(netamount) over custcty,
       sum(netamount) OVER (cty)
  FROM customers
  JOIN orders USING (customerid)
WINDOW cty AS (PARTITION BY country),
       custcty AS (cty order by customerid range current row)
order by customerid
 LIMIT 10;


select distinct orderdate, sum(netamount) over w
from orders
window w as (partition by orderdate)
order by orderdate
limit 5;

--------------------  Group by
    SELECT country,
           count(*) AS aggregate
      FROM customers
     GROUP BY country;


    SELECT country as realm,
           count(*) AS customers
      FROM customers
     GROUP BY realm
     ORDER BY customers DESC;

     SELECT country,
            count(*)                     AS row_count,
            count(o.orderid)             AS orders,
            count(distinct c.customerid) AS customers,
            count(distinct o.customerid) AS active_customers
       FROM customers c
  LEFT JOIN orders o ON c.customerid = o.customerid
      GROUP BY country;

   SELECT country,
          count(distinct o.customerid) AS active,
          count(distinct c.customerid) filter (where o.orderid is null)
          as inactive
     FROM customers c
LEFT JOIN orders o on o.customerid = c.customerid
    GROUP BY country
    order by country;

   SELECT country,
          count(distinct o.customerid) AS active,
          count(distinct c.customerid) filter (where o.orderid is null)
          as inactive,
          count(distinct case when o.orderid is null
          then c.customerid end) as alternate
     FROM customers c
LEFT JOIN orders o on o.customerid = c.customerid
    GROUP BY country
    order by country;

    SELECT country,
           count(*) as customers,
           count(*)
             FILTER (WHERE substring (lastname from 1 for 1) = 'A') AS withA
      FROM customers
  GROUP BY country
  order by country;


SELECT country,
       mode() within group (order by prod_id) AS top_product
  FROM customers c
  LEFT JOIN orders AS o     ON c.customerid = o.customerid
       JOIN orderlines AS l ON l.orderid = o.orderid
      GROUP BY country
      order by country;

-------------
-- grouping sets
drop table s;

create table s as
select * from (
select generate_series(1,3) a
) a
cross join (
select  generate_series(1,2) b
) b
;

select * from s;

select a, count(*)
  from s
 group by a
 order by a;

select a,b,count(*)
  from s
 group by a,b
 order by a,b;

select a,b,count(*)
  from s
 group by
   grouping sets((a,b), ())
 order by a,b;


select a,b,count(*)
  from s
 group by
   grouping sets((a,b), a, b, ())
 order by a,b;

SELECT country, state,
       count(*) AS aggregate
  FROM customers
 GROUP BY GROUPING SETS(
                        (country, state),
                        country
 )
 ORDER BY country, state

-- HAVING

  SELECT country,
         count(*)
    FROM customers
GROUP BY country
  HAVING count(*) > 1000
  order by country;

 SELECT date_part('week', orderdate), count(*), sum(netamount)
   FROM orders
  GROUP BY 1
 HAVING count(*) <= 220 and sum(netamount) >= 42000
  ORDER BY 1

-- Local Variables:
-- sql-product: postgres
-- End:
