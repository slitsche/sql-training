CREATE TABLE t2 (
    a   int,
    b   int
);

INSERT INTO t2 SELECT mod(i,100), mod(i,100)
                 FROM generate_series(1,1000000) s(i);

CREATE STATISTICS s2 (mcv) ON a, b FROM t2;

ANALYZE t2;

-- valid combination (found in MCV)
EXPLAIN ANALYZE SELECT * FROM t2 WHERE (a = 1) AND (b = 1);

-- invalid combination (not found in MCV)
EXPLAIN ANALYZE SELECT * FROM t2 WHERE (a = 1) AND (b = 2);



-------------------------------------
-- JSON


SELECT
  v AS raw,
  jsonb_path_query(v, '$.a') AS L1,
  jsonb_path_query(v, '$.b.c') AS L2,
  jsonb_path_query(v, '$.d[*] ? (@.e > 10)."e"') AS filtered,
  jsonb_path_exists(v, '$a') "aExists"
  FROM (VALUES ('{"a":1, "b": {"c": 42}, "d": [{"e":7}, {"e":23}]}'::jsonb)) AS j(v);


-----------------
create table task_requeue_attempts(
tra_id int,
tra_status int);

insert into task_requeue_attempts values(1,10), (2,10), (2,46);

select * from task_requeue_attempts;

with goodones(
select tra_id
from task_requeue_attempts
group by tra_id
having count(*) filter (where tra_status = 10) = 1
 and count(*) filter (where tra_status > 45) = 0
)
select * from
task_details d
join goodones AS g on g.tra_td_id = d.td_id
;


-----------------------------------------------

SELECT
  date_trunc('week', orderdate)
    AS week,
  count(*),
  sum(netamount)
   FROM orders
  GROUP BY 1
 HAVING count(*) <= 220
    and sum(netamount) >= 42000;

SELECT orderdate,
       netamount,
       SUM(netamount) OVER (ORDER BY orderdate)
       AS daily_revenue
  FROM orders
 LIMIT 5;

----------------------------------
/*
Effect of late joins with aggregates
*/


explain -- (analyze)
select customerid, country, count(*)
  from orders AS o
  join customers AS c USING (customerid)
 group by o.customerid, c.country
 order by 3,1 desc
 limit 5;


explain -- (analyze)
with ordered AS (
select customerid, count(*)
  from orders AS o
 group by o.customerid
 order by 2,1 desc
 limit 5)
select o.customerid, country, count
  from ordered AS o
  join customers AS c USING (customerid);
