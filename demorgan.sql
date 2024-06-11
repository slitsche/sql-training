
select
orderdate,
count(*)
from orders
where orderdate < '2004-02-01'
group by orderdate;


explain
select orderdate, count(*)
from orders
where not (orderdate > '2004-02-01'
  and orderdate < '2004-12-01')
group by 1;

¬ (a & b) = ¬a || ¬b

explain
select orderdate, count(*)
from orders
where not orderdate > '2004-02-01'
  or not orderdate < '2004-12-01'
group by 1;
