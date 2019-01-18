select 1
union
select 1;

create table x as
select * from (values (1), (2), (3)) as f(x);

create table y as
select * from (values (1), (2), (4)) as f(y);

create table z as
select * from (values (1), (2), (2)) as f(z);

select * from y;

select *
  from x
  full join y on x.x = y.y;

select * from x
  except all
select * from y;





select case when 2 = 1
            then 'A'
            when 2 != 2
            then 'B'
            else 'default' 
       end;


set search_path to sql101, public;

select c_name, upper(c_name), c_population
  from sql101.city
 order by c_name DESC
 limit 2;


In der Stadt Zwolle leben 104000 Einwohner.


select c_name, upper(c_name), c_population
  from sql101.city
 where 1 = 1 and c_name = 'Zwolle'
 order by c_name DESC
;

select distinct c_name, c_country_code3
  from city
 where c_name = 'Berlin';

select s.meinname from (
select c_name as meinname
  from city
 where c_name like 'Y__'
 ) as s;


select * from z;

select c_code3
  from country
  join city 
  limit 3;

select * from y
join x on x = y;

select * from x join z on z.z = x.x;

select *
from x
left join z on x.x = z.z;

select * from x
right join y on x.x = y.y;

select * from x
FULL outer join y on x.x = y.y;


select * from x
right join y on x = y
where x is null;


select country.c_name, c_local_name, country.c_name
  from country 
  join city as ci on country.c_code3 = ci.c_country_code3  and c_is_capital = True;


set search_path to sql101, public;

-- find the countries without a capital: LEFT JOIN -> explain JOIN types
SELECT country.c_name, c_code3
FROM country LEFT JOIN city ON c_code3 = c_country_code3 AND c_is_capital
WHERE city.c_id IS NULL
ORDER BY c_code3; -- LEFT JOIN


SELECT country.c_name, c_code3, c_is_capital
FROM country LEFT JOIN city ON c_code3 = c_country_code3 AND c_is_capital --is not null
WHERE c_is_capital is null
ORDER BY c_code3; -- LEFT JOIN






select y from y
  UNION ALL
select x from x;
