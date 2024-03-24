--Stage_1.
CREATE TABLE table_to_delete AS
SELECT 'veeeeeeery_long_string' || x AS col
FROM generate_series(1,(10^7)::int) x; -- generate_series() creates 10^7 rows of sequential numbers from 1 to 10000000 (10^7)   
      

--Stage_2.
SELECT *, pg_size_pretty(total_bytes) AS total,
                                    pg_size_pretty(index_bytes) AS INDEX,
                                    pg_size_pretty(toast_bytes) AS toast,
                                    pg_size_pretty(table_bytes) AS TABLE
               FROM ( SELECT *, total_bytes-index_bytes-COALESCE(toast_bytes,0) AS table_bytes
                               FROM (SELECT c.oid,nspname AS table_schema,
                                                               relname AS TABLE_NAME,
                                                              c.reltuples AS row_estimate,
                                                              pg_total_relation_size(c.oid) AS total_bytes,
                                                              pg_indexes_size(c.oid) AS index_bytes,
                                                              pg_total_relation_size(reltoastrelid) AS toast_bytes
                                              FROM pg_class c
                                              LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
                                              WHERE relkind = 'r'
                                              ) a
                                    ) a
               WHERE table_name LIKE '%table_to_delete%';
               

--Stage_3.               
DELETE FROM table_to_delete
WHERE REPLACE(col, 'veeeeeeery_long_string','')::int % 3 = 0; -- removes 1/3 of all rows

--Stage_4.
 VACUUM FULL VERBOSE table_to_delete;
 
--Stage_5.
TRUNCATE table_to_delete;
 
/*I created table "table_to_delete" with Stage_1 query. With the help of Stage_2 I determined that the table consumes 575 MB.
 * I performed DELETE FROM using Stage_3 query. Duration of this operation was 13298 ms. I repeated Stage_2 and it appeared that the table
 * consumed the same 575 Mb as we had before DELETE. After that Stage_4 (VACUUM) was performed. In its results we note the number of 
 * 1660896 removable row versions. Unsurprisingly, it is the number of rows which were removed with DELETE FROM operation, but were still
 * presented as "dead" tuples. As far as VACUUM reclaims storage occupied by dead tuples, when we repeat Stage_2 we discover that table size
 * decreased to 383 mb (exactly 2/3 of 575 mb). 
 * I recreated table "table_to_delete", and performed Stage_5 operation - TRUNCATE. Its duration was 1067 ms, which is about 13 times less than DELETE FROM.
 * As we know, DELETE is basically a row level operation. A DELETE statement marks every row matching the WHERE-clause as deleted.In the case of big amount of rows,
 * this takes a relatively long time. TRUNCATE is different: It’s basically a table operation. Instead of touching each row separately, it simply empties the entire table, 
 * which is significally faster. If we check space consumption of the table once again with Stage_2 query, we will see that it is roughly equal to 0. It is evidence 
 * of the fact that it reclaims disk space immediately and doesn't require subsequent VACUUM operation. 
 * To sum up, TRUNCATE is unbeatable if we need to delete all rows, it is considerably faster than DELETE and doen't require VACUUM afterwards. On the other hand, if we need 
 * to remove rows selectively, we have to use DELETE with its disadvantages (longer execution time, necessity to use VACUUM afterwards to reclaim disk space). 
 * 
 * 	                               DELETE 	TRUNCATE
space consumption before, Mb	    575	      575
space consumption after, Mb	        575	     appr.0
space consumption after VACUUM, Mb	383        -   
duration, ms	                    13298	  1067
  
 */  