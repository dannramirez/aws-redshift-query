WITH objprivs AS (
SELECT pg_get_userbyid(b.relowner)::text AS objowner, 
		trim(c.nspname)::text AS schemaname,  
		b.relname::text AS objname,
		CASE WHEN relkind='r' THEN 'table' ELSE 'view' END::text AS objtype, 
		TRIM(SPLIT_PART(array_to_string(b.relacl,','), ',', NS.n))::text AS aclstring, 
		NS.n as grantseq,
		null::text as colname
		FROM 
		(SELECT oid,generate_series(1,array_upper(relacl,1))  AS n FROM pg_catalog.pg_class) NS
		INNER JOIN pg_catalog.pg_class B ON b.oid = ns.oid AND  NS.n <= array_upper(b.relacl,1)
		INNER JOIN pg_catalog.pg_namespace c on b.relnamespace = c.oid
		where relkind in ('r','v')
UNION ALL
---- table and view column privileges
SELECT pg_get_userbyid(c.relowner)::text AS objowner, 
		trim(d.nspname)::text AS schemaname,  
		c.relname::text AS objname,
		'column'::text AS objtype, 
		TRIM(SPLIT_PART(array_to_string(b.attacl,','), ',', NS.n))::text AS aclstring, 
		NS.n as grantseq,
		b.attname::text as colname
		FROM 
		(SELECT attrelid,generate_series(1,array_upper(attacl,1))  AS n FROM pg_catalog.pg_attribute_info) NS
		INNER JOIN pg_catalog.pg_attribute_info B ON b.attrelid = ns.attrelid AND  NS.n <= array_upper(b.attacl,1)
		INNER JOIN pg_catalog.pg_class c on b.attrelid = c.oid
		INNER JOIN pg_catalog.pg_namespace d on c.relnamespace = d.oid
		where relkind in ('r','v')
UNION ALL
SELECT pg_get_userbyid(b.nspowner)::text AS objowner,
		null::text AS schemaname,
		b.nspname::text AS objname,
		'schema'::text AS objtype,
		TRIM(SPLIT_PART(array_to_string(b.nspacl,','), ',', NS.n))::text AS aclstring,
		NS.n as grantseq,
		null::text as colname
		FROM 
		(SELECT oid,generate_series(1,array_upper(nspacl,1)) AS n FROM pg_catalog.pg_namespace) NS
		INNER JOIN pg_catalog.pg_namespace B ON b.oid = ns.oid AND NS.n <= array_upper(b.nspacl,1)
)

SELECT * FROM objprivs
WHERE schemaname != 'pg_catalog' and schemaname != 'information_schema' order by schemaname,objname,objtype asc;