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


    SELECT country,
           count(*) AS aggregate
      FROM customers
     GROUP BY country;


    SELECT country as realm,
           count(*) AS customers
      FROM customers
     GROUP BY realm
     ORDER BY customers DESC;
-------------



-- Local Variables:
-- sql-product: postgres
-- End:
