CREATE OR REPLACE FUNCTION f_unaccent(text)
  RETURNS text AS
$func$
SELECT unaccent('unaccent', $1)
$func$  LANGUAGE sql IMMUTABLE SET search_path = public, pg_temp;


