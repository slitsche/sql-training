/*
Oleg Bartunov

*/

CREATE TABLE test_jsonb_nesting AS
SELECT id / 10 size, id % 10 AS level,
 (repeat('{"obj": ', id % 10) ||
 jsonb_build_object('key', id, 'long_str', str) ||
 repeat('}', id % 10))::jsonb jb
FROM
 generate_series(0, 100) id,
 repeat('a', pow(10, id / 200.0)::int) str;


\d test_jsonb_nesting

explain analyze
select jb -> 'obj' -> 'key' from test_jsonb_nesting;

explain analyze
select jb #> '{obj,key}' from test_jsonb_nesting;



--CREATE TABLE test_jsonb_array AS
SELECT id, size::int size,
 (SELECT jsonb_agg(i) FROM generate_series(0, size::int - 1) I) jb
FROM generate_series(0, 1/*6 * 4*/) id,
     pow(10, id / 4) size;

select      pow(10, 4 / 4) size;

select *
FROM generate_series(0, 4/*6 * 4*/) id,
     pow(10, id / 4) size;


SELECT jsonb_agg(h)
FROM generate_series(0, 10::int - 1) H;

select h from (values (1),(2)) H(h);


/*
Curse of toast
*/

drop table toasttest;

CREATE TABLE toasttest (jb jsonb);
ALTER TABLE toasttest ALTER COLUMN jb SET STORAGE EXTERNAL;
INSERT INTO toasttest
SELECT
 jsonb_build_object(
 'id', i,
 'foo', (select jsonb_agg(0) from generate_series(1, 1960/12)) -- [0,0,0, ...]
 ) jb
FROM
 generate_series(1, 10000) i;

SELECT pg_column_size(jb) compressed_size,
       pg_column_size(jb::text::jsonb) orig_size
       ,pg_column_size(jb::text) text_size
  FROM toasttest LIMIT 5 offset 500;

select * from toasttest limit 10;

analyze toasttest;

EXPLAIN(ANALYZE, BUFFERS) SELECT jb->'id' FROM toasttest;

UPDATE toasttest SET jb = jb || '{"bar": "baz"}';
VACUUM FULL toasttest; -- remove old versions
EXPLAIN (ANALYZE, BUFFERS) SELECT jb->'id' FROM toasttest;

/*
Line
   Buffers: shared hit=30064

64 (heap table) + 3*10.000 (2 toast index + 1 toast table blocks)
*/

create extension pageinspect;

-- length of tuple per block `0`
SELECT lp_len FROM heap_page_items(get_raw_page('toasttest', 0)) limit 10;

SELECT reltoastrelid::regclass toast_rel FROM pg_class
WHERE oid = 'toasttest'::regclass;

SELECT chunk_id, chunk_seq, length(chunk_data) FROM pg_toast.pg_toast_154224 limit 10;

-- does not work on toasttest, because it is not compressed column
SELECT pg_column_size(jb) compressed_size,
       pg_column_size(jb::text::jsonb) orig_size
  FROM toasttest LIMIT 1;

SELECT oid::regclass AS heap_rel,
 pg_size_pretty(pg_relation_size(oid)) AS heap_rel_size,
 reltoastrelid::regclass AS toast_rel,
 pg_size_pretty(pg_relation_size(reltoastrelid)) AS toast_rel_size
FROM pg_class WHERE relname = 'toasttest';

analyze toasttest;

SELECT relname, relpages, reltuples
  FROM pg_class
 WHERE oid IN (
        SELECT UNNEST(ARRAY[oid, reltoastrelid])
          FROM pg_class
         WHERE oid = 'toasttest'::regclass);

SELECT UNNEST(ARRAY[oid, reltoastrelid])
          FROM pg_class
         WHERE oid = 'toasttest'::regclass;


SELECT c1.relname table_name, c1.relpages heap_page,
       c2.relname toast_table, c2.relpages toast_page
FROM
    pg_class c1
    JOIN pg_class c2 ON c1.reltoastrelid = c2.oid
WHERE c1.relname = 'toasttest';

/*
jsonb as extended, with compression

impact of update on WAL
*/

CREATE TABLE t AS
SELECT i AS id, (SELECT jsonb_object_agg(j, j) FROM generate_series(1, 1000) j) js
FROM generate_series(1, 10000) i;

SELECT oid::regclass AS heap_rel,
 pg_size_pretty(pg_relation_size(oid)) AS heap_rel_size,
 reltoastrelid::regclass AS toast_rel,
 pg_size_pretty(pg_relation_size(reltoastrelid)) AS toast_rel_size
FROM pg_class WHERE relname = 't';

SELECT pg_column_size(js) compressed_size,
       pg_column_size(js::text::jsonb) orig_size
       ,pg_column_size(js::text) text_size
  FROM t LIMIT 1;

SELECT chunk_id, count(chunk_seq)
  FROM pg_toast.pg_toast_104175
 GROUP BY chunk_id LIMIT 1;

select '{"1":1}'::jsonb - '1' from t where id = 1;
