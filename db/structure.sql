--
-- PostgreSQL database dump
--

-- Dumped from database version 9.6.13
-- Dumped by pg_dump version 9.6.13

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: audit; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA audit;


--
-- Name: SCHEMA audit; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA audit IS 'Out-of-table audit/history logging tables and trigger functions';


--
-- Name: mapper; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA mapper;


--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: hstore; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS hstore WITH SCHEMA public;


--
-- Name: EXTENSION hstore; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION hstore IS 'data type for storing sets of (key, value) pairs';


--
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


--
-- Name: unaccent; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS unaccent WITH SCHEMA public;


--
-- Name: EXTENSION unaccent; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION unaccent IS 'text search dictionary that removes accents';


--
-- Name: audit_table(regclass); Type: FUNCTION; Schema: audit; Owner: -
--

CREATE FUNCTION audit.audit_table(target_table regclass) RETURNS void
    LANGUAGE sql
    AS $_$
SELECT audit.audit_table($1, BOOLEAN 't', BOOLEAN 't');
$_$;


--
-- Name: FUNCTION audit_table(target_table regclass); Type: COMMENT; Schema: audit; Owner: -
--

COMMENT ON FUNCTION audit.audit_table(target_table regclass) IS '
Add auditing support to the given table. Row-level changes will be logged with full client query text. No cols are ignored.
';


--
-- Name: audit_table(regclass, boolean, boolean); Type: FUNCTION; Schema: audit; Owner: -
--

CREATE FUNCTION audit.audit_table(target_table regclass, audit_rows boolean, audit_query_text boolean) RETURNS void
    LANGUAGE sql
    AS $_$
SELECT audit.audit_table($1, $2, $3, ARRAY[]::text[]);
$_$;


--
-- Name: audit_table(regclass, boolean, boolean, text[]); Type: FUNCTION; Schema: audit; Owner: -
--

CREATE FUNCTION audit.audit_table(target_table regclass, audit_rows boolean, audit_query_text boolean, ignored_cols text[]) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
  stm_targets text = 'INSERT OR UPDATE OR DELETE OR TRUNCATE';
  _q_txt text;
  _ignored_cols_snip text = '';
BEGIN
    EXECUTE 'DROP TRIGGER IF EXISTS audit_trigger_row ON ' || target_table;
    EXECUTE 'DROP TRIGGER IF EXISTS audit_trigger_stm ON ' || target_table;

    IF audit_rows THEN
        IF array_length(ignored_cols,1) > 0 THEN
            _ignored_cols_snip = ', ' || quote_literal(ignored_cols);
        END IF;
        _q_txt = 'CREATE TRIGGER audit_trigger_row AFTER INSERT OR UPDATE OR DELETE ON ' ||
                 target_table ||
                 ' FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func(' ||
                 quote_literal(audit_query_text) || _ignored_cols_snip || ');';
        RAISE NOTICE '%',_q_txt;
        EXECUTE _q_txt;
        stm_targets = 'TRUNCATE';
    ELSE
    END IF;

    _q_txt = 'CREATE TRIGGER audit_trigger_stm AFTER ' || stm_targets || ' ON ' ||
             target_table ||
             ' FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('||
             quote_literal(audit_query_text) || ');';
    RAISE NOTICE '%',_q_txt;
    EXECUTE _q_txt;

END;
$$;


--
-- Name: FUNCTION audit_table(target_table regclass, audit_rows boolean, audit_query_text boolean, ignored_cols text[]); Type: COMMENT; Schema: audit; Owner: -
--

COMMENT ON FUNCTION audit.audit_table(target_table regclass, audit_rows boolean, audit_query_text boolean, ignored_cols text[]) IS '
Add auditing support to a table.

Arguments:
   target_table:     Table name, schema qualified if not on search_path
   audit_rows:       Record each row change, or only audit at a statement level
   audit_query_text: Record the text of the client query that triggered the audit event?
   ignored_cols:     Columns to exclude from update diffs, ignore updates that change only ignored cols.
';


--
-- Name: if_modified_func(); Type: FUNCTION; Schema: audit; Owner: -
--

CREATE FUNCTION audit.if_modified_func() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
    AS $$
DECLARE
    audit_row audit.logged_actions;
    include_values boolean;
    log_diffs boolean;
    h_old hstore;
    h_new hstore;
    excluded_cols text[] = ARRAY[]::text[];
BEGIN
    IF TG_WHEN <> 'AFTER' THEN
        RAISE EXCEPTION 'audit.if_modified_func() may only run as an AFTER trigger';
    END IF;

    audit_row = ROW(
        nextval('audit.logged_actions_event_id_seq'), -- event_id
        TG_TABLE_SCHEMA::text,                        -- schema_name
        TG_TABLE_NAME::text,                          -- table_name
        TG_RELID,                                     -- relation OID for much quicker searches
        session_user::text,                           -- session_user_name
        current_timestamp,                            -- action_tstamp_tx
        statement_timestamp(),                        -- action_tstamp_stm
        clock_timestamp(),                            -- action_tstamp_clk
        txid_current(),                               -- transaction ID
        current_setting('application_name'),          -- client application
        inet_client_addr(),                           -- client_addr
        inet_client_port(),                           -- client_port
        current_query(),                              -- top-level query or queries (if multistatement) from client
        substring(TG_OP,1,1),                         -- action
        NULL, NULL,                                   -- row_data, changed_fields
        'f'                                           -- statement_only
        );

    IF NOT TG_ARGV[0]::boolean IS DISTINCT FROM 'f'::boolean THEN
        audit_row.client_query = NULL;
    END IF;

    IF TG_ARGV[1] IS NOT NULL THEN
        excluded_cols = TG_ARGV[1]::text[];
    END IF;

    IF (TG_OP = 'UPDATE' AND TG_LEVEL = 'ROW') THEN
        audit_row.row_data = hstore(OLD.*);
        audit_row.changed_fields =  (hstore(NEW.*) - audit_row.row_data) - excluded_cols;
        IF audit_row.changed_fields = hstore('') THEN
            -- All changed fields are ignored. Skip this update.
            RETURN NULL;
        END IF;
    ELSIF (TG_OP = 'DELETE' AND TG_LEVEL = 'ROW') THEN
        audit_row.row_data = hstore(OLD.*) - excluded_cols;
    ELSIF (TG_OP = 'INSERT' AND TG_LEVEL = 'ROW') THEN
        audit_row.row_data = hstore(NEW.*) - excluded_cols;
    ELSIF (TG_LEVEL = 'STATEMENT' AND TG_OP IN ('INSERT','UPDATE','DELETE','TRUNCATE')) THEN
        audit_row.statement_only = 't';
    ELSE
        RAISE EXCEPTION '[audit.if_modified_func] - Trigger func added as trigger for unhandled case: %, %',TG_OP, TG_LEVEL;
        RETURN NULL;
    END IF;
    INSERT INTO audit.logged_actions VALUES (audit_row.*);
    RETURN NULL;
END;
$$;


--
-- Name: FUNCTION if_modified_func(); Type: COMMENT; Schema: audit; Owner: -
--

COMMENT ON FUNCTION audit.if_modified_func() IS '
Track changes to a table at the statement and/or row level.

Optional parameters to trigger in CREATE TRIGGER call:

param 0: boolean, whether to log the query text. Default ''t''.

param 1: text[], columns to ignore in updates. Default [].

         Updates to ignored cols are omitted from changed_fields.

         Updates with only ignored cols changed are not inserted
         into the audit log.

         Almost all the processing work is still done for updates
         that ignored. If you need to save the load, you need to use
         WHEN clause on the trigger instead.

         No warning or error is issued if ignored_cols contains columns
         that do not exist in the target table. This lets you specify
         a standard set of ignored columns.

There is no parameter to disable logging of values. Add this trigger as
a ''FOR EACH STATEMENT'' rather than ''FOR EACH ROW'' trigger if you do not
want to log row values.

Note that the user name logged is the login role for the session. The audit trigger
cannot obtain the active role because it is reset by the SECURITY DEFINER invocation
of the audit trigger its self.
';


--
-- Name: accepted_status(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.accepted_status(nameid bigint) RETURNS text
    LANGUAGE sql
AS
$$
select coalesce(excluded_status(nameId), inc_status(nameId), 'unplaced');
$$;


--
-- Name: apni_detail_jsonb(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.apni_detail_jsonb(nameid bigint) RETURNS jsonb
    LANGUAGE sql
    AS $$
select jsonb_agg(
         jsonb_build_object(
           'ref_citation_html', refs.citation_html,
           'ref_citation', refs.citation,
           'instance_id', refs.instance_id,
           'instance_uri', refs.instance_uri,
           'instance_type', refs.instance_type,
           'page', refs.page,
           'type_notes', coalesce(type_notes_jsonb(refs.instance_id), '{}' :: jsonb),
           'synonyms', coalesce(apni_ordered_synonymy_jsonb(refs.instance_id), apni_synonym_jsonb(refs.instance_id), '[]' :: jsonb),
           'non_type_notes', coalesce(non_type_notes_jsonb(refs.instance_id), '{}' :: jsonb),
           'profile', coalesce(latest_accepted_profile_jsonb(refs.instance_id), '{}' :: jsonb),
           'resources', coalesce(instance_resources_jsonb(refs.instance_id), '{}' :: jsonb),
           'tree', coalesce(instance_on_accepted_tree_jsonb(refs.instance_id), '{}' :: jsonb)
         )
       )
from apni_ordered_references(nameid) refs
$$;


--
-- Name: apni_detail_text(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.apni_detail_text(nameid bigint) RETURNS text
    LANGUAGE sql
    AS $$
select string_agg(' ' ||
                  refs.citation ||
                  ': ' ||
                  refs.page || E'
' ||
                  coalesce(type_notes_text(refs.instance_id), '') ||
                  coalesce(apni_ordered_synonymy_text(refs.instance_id), apni_synonym_text(refs.instance_id), '') ||
                  coalesce(non_type_notes_text(refs.instance_id), '') ||
                  coalesce(latest_accepted_profile_text(refs.instance_id), ''),
                  E'
')
from apni_ordered_references(nameid) refs
$$;


--
-- Name: apni_ordered_nom_synonymy(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.apni_ordered_nom_synonymy(instanceid bigint) RETURNS TABLE(instance_id bigint, instance_uri text, instance_type text, instance_type_id bigint, name_id bigint, name_uri text, full_name text, full_name_html text, name_status text, citation text, citation_html text, year integer, page text, sort_name text, misapplied boolean, ref_id bigint)
    LANGUAGE sql
    AS $$
select i.id,
       i.uri,
       it.has_label as instance_type,
       it.id        as instance_type_id,
       n.id         as name_id,
       n.uri,
       n.full_name,
       n.full_name_html,
       ns.name      as name_status,
       r.citation,
       r.citation_html,
       r.year,
       cites.page,
       n.sort_name,
       false,
       r.id
from instance i
       join instance_type it on i.instance_type_id = it.id and it.nomenclatural
       join name n on i.name_id = n.id
       join name_status ns on n.name_status_id = ns.id
       left outer join instance cites on i.cites_id = cites.id
       left outer join reference r on cites.reference_id = r.id
where i.cited_by_id = instanceid
order by (it.sort_order < 20) desc,
         it.nomenclatural desc,
         r.year,
         n.sort_name,
         it.pro_parte,
         it.doubtful,
         cites.page,
         cites.id;
$$;


--
-- Name: apni_ordered_other_synonymy(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.apni_ordered_other_synonymy(instanceid bigint) RETURNS TABLE(instance_id bigint, instance_uri text, instance_type text, instance_type_id bigint, name_id bigint, name_uri text, full_name text, full_name_html text, name_status text, citation text, citation_html text, year integer, page text, sort_name text, group_name text, group_head boolean, group_year integer, misapplied boolean, ref_id bigint, og_id bigint, og_head boolean, og_name text, og_year integer)
    LANGUAGE sql
    AS $$
select i.id                            as instance_id,
       i.uri                           as instance_uri,
       it.has_label                    as instance_type,
       it.id                           as instance_type_id,
       n.id                            as name_id,
       n.uri                           as name_uri,
       n.full_name,
       n.full_name_html,
       ns.name                         as name_status,
       r.citation,
       r.citation_html,
       r.year,
       cites.page,
       n.sort_name,
       ng.group_name                   as group_name,
       ng.group_id = n.id              as group_head,
       coalesce(ng.group_year, r.year) as group_year,
       it.misapplied,
       r.id                            as ref_id,
       og_id                           as og_id,
       og_id = n.id                    as og_head,
       coalesce(ogn.sort_name, n.sort_name) as og_name,
       coalesce(ogr.year,r.year)       as og_year
from instance i
       join instance_type it on i.instance_type_id = it.id and not it.nomenclatural and it.relationship
       join name n on i.name_id = n.id
       join name_type nt on n.name_type_id = nt.id
       join orth_or_alt_of(case when nt.autonym then n.parent_id else n.id end) og_id on true
       left outer join name ogn on ogn.id = og_id and not og_id = n.id
       left outer join instance ogi
       join reference ogr on ogr.id = ogi.reference_id
         on ogi.name_id = og_id and ogi.id = i.cited_by_id and not og_id = n.id
       left outer join first_ref(basionym(og_id)) ng on true
       join name_status ns on n.name_status_id = ns.id
       left outer join instance cites on i.cites_id = cites.id
       left outer join reference r on cites.reference_id = r.id
where i.cited_by_id = instanceid
order by (it.sort_order < 20) desc,
         it.taxonomic desc,
         group_year,
         group_name,
         group_head desc,
         og_year,
         og_name,
         og_head desc,
         r.year,
         n.sort_name,
         it.pro_parte,
         it.misapplied desc,
         it.doubtful,
         cites.page,
         cites.id;
$$;


--
-- Name: apni_ordered_references(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.apni_ordered_references(nameid bigint) RETURNS TABLE(instance_id bigint, instance_uri text, instance_type text, citation text, citation_html text, year integer, pages text, page text)
    LANGUAGE sql
    AS $$
select i.id, i.uri, it.name, r.citation, r.citation_html, r.year, r.pages, coalesce(i.page, citedby.page, '-')
from instance i
       join reference r on i.reference_id = r.id
       join instance_type it on i.instance_type_id = it.id
       left outer join instance citedby on i.cited_by_id = citedby.id
where i.name_id = nameid
group by r.id, i.id, it.id, citedby.id
order by r.year, it.protologue, it.primary_instance, r.citation, r.pages, i.page, r.id;
$$;


--
-- Name: apni_ordered_synonymy(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.apni_ordered_synonymy(instanceid bigint) RETURNS TABLE(instance_id bigint, instance_uri text, instance_type text, instance_type_id bigint, name_id bigint, name_uri text, full_name text, full_name_html text, name_status text, citation text, citation_html text, year integer, page text, sort_name text, misapplied boolean, ref_id bigint)
    LANGUAGE sql
    AS $$

select instance_id, instance_uri, instance_type, instance_type_id, name_id, name_uri, full_name, full_name_html,
       name_status, citation, citation_html, year, page, sort_name, misapplied, ref_id
from apni_ordered_nom_synonymy(instanceid)
union all
select instance_id, instance_uri, instance_type, instance_type_id, name_id, name_uri, full_name, full_name_html,
       name_status, citation, citation_html, year, page, sort_name, misapplied, ref_id
from apni_ordered_other_synonymy(instanceid)
$$;


--
-- Name: apni_ordered_synonymy_jsonb(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.apni_ordered_synonymy_jsonb(instanceid bigint) RETURNS jsonb
    LANGUAGE sql
    AS $$
select jsonb_agg(
         jsonb_build_object(
           'instance_id', syn.instance_id,
           'instance_uri', syn.instance_uri,
           'instance_type', syn.instance_type,
           'name_uri', syn.name_uri,
           'full_name_html', syn.full_name_html,
           'name_status', syn.name_status,
           'misapplied', syn.misapplied,
           'citation_html', syn.citation_html
             )
           )
from apni_ordered_synonymy(instanceid) syn;
$$;


--
-- Name: apni_ordered_synonymy_text(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.apni_ordered_synonymy_text(instanceid bigint) RETURNS text
    LANGUAGE sql
    AS $$
select string_agg('  ' ||
                  syn.instance_type ||
                  ': ' ||
                  syn.full_name ||
                  (case
                     when syn.name_status = 'legitimate' then ''
                     when syn.name_status = '[n/a]' then ''
                     else ' ' || syn.name_status end) ||
                  (case
                     when syn.misapplied then syn.citation
                     else '' end), E'
') || E'
'
from apni_ordered_synonymy(instanceid) syn;
$$;


--
-- Name: apni_synonym(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.apni_synonym(instanceid bigint) RETURNS TABLE(instance_id bigint, instance_uri text, instance_type text, instance_type_id bigint, name_id bigint, name_uri text, full_name text, full_name_html text, name_status text, citation text, citation_html text, year integer, page text, misapplied boolean, sort_name text)
    LANGUAGE sql
    AS $$
select i.id,
       i.uri,
       it.of_label as instance_type,
       it.id       as instance_type_id,
       n.id        as name_id,
       n.uri,
       n.full_name,
       n.full_name_html,
       ns.name,
       r.citation,
       r.citation_html,
       r.year,
       i.page,
       it.misapplied,
       n.sort_name
from instance i
       join instance_type it on i.instance_type_id = it.id
       join instance cites on i.cited_by_id = cites.id
       join name n on cites.name_id = n.id
       join name_status ns on n.name_status_id = ns.id
       join reference r on i.reference_id = r.id
where i.id = instanceid
  and it.relationship;
$$;


--
-- Name: apni_synonym_jsonb(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.apni_synonym_jsonb(instanceid bigint) RETURNS jsonb
    LANGUAGE sql
    AS $$
select jsonb_agg(
         jsonb_build_object(
           'instance_id', syn.instance_id,
           'instance_uri', syn.instance_uri,
           'instance_type', syn.instance_type,
           'name_uri', syn.name_uri,
           'full_name_html', syn.full_name_html,
           'name_status', syn.name_status,
           'misapplied', syn.misapplied,
           'citation_html', syn.citation_html
             )
           )
from apni_synonym(instanceid) syn;
$$;


--
-- Name: apni_synonym_text(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.apni_synonym_text(instanceid bigint) RETURNS text
    LANGUAGE sql
    AS $$
select string_agg('  ' ||
                  syn.instance_type ||
                  ': ' ||
                  syn.full_name ||
                  (case
                     when syn.name_status = 'legitimate' then ''
                     when syn.name_status = '[n/a]' then ''
                     else ' ' || syn.name_status end) ||
                  (case
                     when syn.misapplied
                             then 'by ' || syn.citation
                     else '' end), E'
') || E'
'
from apni_synonym(instanceid) syn;
$$;


--
-- Name: author_notification(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.author_notification() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF (TG_OP = 'DELETE')
  THEN
    INSERT INTO notification (id, version, message, object_id)
      SELECT
        nextval('hibernate_sequence'),
        0,
        'author deleted',
        OLD.id;
    RETURN OLD;
  ELSIF (TG_OP = 'UPDATE')
    THEN
      INSERT INTO notification (id, version, message, object_id)
        SELECT
          nextval('hibernate_sequence'),
          0,
          'author updated',
          NEW.id;
      RETURN NEW;
  ELSIF (TG_OP = 'INSERT')
    THEN
      INSERT INTO notification (id, version, message, object_id)
        SELECT
          nextval('hibernate_sequence'),
          0,
          'author created',
          NEW.id;
      RETURN NEW;
  END IF;
  RETURN NULL;
END;
$$;


--
-- Name: basionym(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.basionym(nameid bigint) RETURNS bigint
    LANGUAGE sql
    AS $$
select coalesce(
         (select coalesce(bas_name.id, primary_inst.name_id)
          from instance primary_inst
                 left join instance bas_inst
                 join name bas_name on bas_inst.name_id = bas_name.id
                 join instance_type bas_it on bas_inst.instance_type_id = bas_it.id and bas_it.name in ('basionym','replaced synonym')
                 join instance cit_inst on bas_inst.cites_id = cit_inst.id on bas_inst.cited_by_id = primary_inst.id
                 join instance_type primary_it on primary_inst.instance_type_id = primary_it.id and primary_it.primary_instance
          where primary_inst.name_id = nameid
          limit 1), nameid);
$$;


--
-- Name: daily_top_nodes(text, timestamp without time zone); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.daily_top_nodes(tree_label text, since timestamp without time zone) RETURNS TABLE(latest_node_id bigint, year double precision, month double precision, day double precision)
    LANGUAGE sql
    AS $$

WITH RECURSIVE treewalk AS (
  SELECT class_root.*
  FROM tree_node class_node
    JOIN tree_arrangement a ON class_node.id = a.node_id AND a.label = tree_label
    JOIN tree_link sublink ON class_node.id = sublink.supernode_id
    JOIN tree_node class_root ON sublink.subnode_id = class_root.id
  UNION ALL
  SELECT node.*
  FROM treewalk
    JOIN tree_node node ON treewalk.prev_node_id = node.id
)
SELECT
  max(tw.id) AS latest_node_id,
  year,
  month,
  day
FROM treewalk tw
  JOIN tree_event event ON tw.checked_in_at_id = event.id
  ,
      extract(YEAR FROM event.time_stamp) AS year,
      extract(MONTH FROM event.time_stamp) AS month,
      extract(DAY FROM event.time_stamp) AS day
WHERE event.time_stamp > since
GROUP BY year, month, day
ORDER BY latest_node_id ASC
$$;


--
-- Name: dist_entry_status(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.dist_entry_status(entry_id bigint) RETURNS text
    LANGUAGE sql
AS
$$
with status as (
    SELECT string_agg(ds.name, ' and ') status
    from (
             select ds.name
             FROM dist_entry de
                      join dist_region dr on de.region_id = dr.id
                      join dist_entry_dist_status deds on de.id = deds.dist_entry_status_id
                      join dist_status ds on deds.dist_status_id = ds.id
             where de.id = entry_id
             order by ds.sort_order) ds
)
select case
           when status.status = 'native' then
               ''
           else
               '(' || status.status || ')'
           end
from status;
$$;


--
-- Name: distribution(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.distribution(element_id bigint) RETURNS text
    LANGUAGE sql
AS
$$
select string_agg(e.display, ', ')
from (select entry.display display
      from dist_entry entry
               join dist_region dr on entry.region_id = dr.id
               join tree_element_distribution_entries tede
                    on tede.dist_entry_id = entry.id and tede.tree_element_id = element_id
      order by dr.sort_order) e
$$;


--
-- Name: excluded_status(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.excluded_status(nameid bigint) RETURNS text
    LANGUAGE sql
AS
$$
select case when te.excluded = true then 'excluded' else 'accepted' end
from tree_element te
         JOIN tree_version_element tve ON te.id = tve.tree_element_id
         JOIN tree ON tve.tree_version_id = tree.current_tree_version_id AND tree.accepted_tree = TRUE
where te.name_id = nameId
$$;


--
-- Name: f_unaccent(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.f_unaccent(text) RETURNS text
    LANGUAGE sql IMMUTABLE
    SET search_path TO 'public', 'pg_temp'
    AS $_$
SELECT unaccent('unaccent', $1)
$_$;


--
-- Name: find_family_name_id(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.find_family_name_id(target_element_link text) RETURNS bigint
    LANGUAGE sql
    AS $$
WITH RECURSIVE walk (name_id, rank, parent_id) AS (
  SELECT
    te.name_id,
    te.rank,
    tve.parent_id
  FROM tree_version_element tve
    JOIN tree_element te ON tve.tree_element_id = te.id
  WHERE element_link = target_element_link
  UNION ALL
  SELECT
    te.name_id,
    te.rank,
    tve.parent_id
  FROM walk, tree_version_element tve
    JOIN tree_element te ON tve.tree_element_id = te.id
  WHERE element_link = walk.parent_id
)
SELECT name_id
FROM walk
WHERE rank = 'Familia';
$$;


--
-- Name: find_rank(bigint, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.find_rank(name_id bigint, rank_sort_order integer) RETURNS TABLE(name_element text, rank text, sort_order integer)
    LANGUAGE sql
    AS $$
WITH RECURSIVE walk (parent_id, name_element, rank, sort_order) AS (
    SELECT parent_id,
           n.name_element,
           r.name,
           r.sort_order
    FROM name n
             JOIN name_rank r ON n.name_rank_id = r.id
    WHERE n.id = name_id
      AND r.sort_order >= rank_sort_order
    UNION ALL
    SELECT n.parent_id,
           n.name_element,
           r.name,
           r.sort_order
    FROM walk w,
         name n
             JOIN name_rank r ON n.name_rank_id = r.id
    WHERE n.id = w.parent_id
      AND r.sort_order >= rank_sort_order
)
SELECT w.name_element,
       w.rank,
       w.sort_order
FROM walk w
WHERE w.sort_order = rank_sort_order
limit 1
$$;


--
-- Name: find_tree_rank(text, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.find_tree_rank(tve_id text, rank_sort_order integer) RETURNS TABLE(name_element text, rank text, sort_order integer)
    LANGUAGE sql
    AS $$
WITH RECURSIVE walk (parent_id, name_element, rank, sort_order) AS (
    SELECT tve.parent_id,
           n.name_element,
           r.name,
           r.sort_order
    FROM tree_version_element tve
             JOIN tree_element te ON tve.tree_element_id = te.id
             JOIN name n ON te.name_id = n.id
             JOIN name_rank r ON n.name_rank_id = r.id
    WHERE tve.element_link = tve_id
      AND r.sort_order >= rank_sort_order
    UNION ALL
    SELECT tve.parent_id,
           n.name_element,
           r.name,
           r.sort_order
    FROM walk w,
         tree_version_element tve
             JOIN tree_element te ON tve.tree_element_id = te.id
             JOIN name n ON te.name_id = n.id
             JOIN name_rank r ON n.name_rank_id = r.id
    WHERE tve.element_link = w.parent_id
      AND r.sort_order >= rank_sort_order
)
SELECT w.name_element,
       w.rank,
       w.sort_order
FROM walk w
WHERE w.sort_order = rank_sort_order
limit 1
$$;


--
-- Name: first_ref(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.first_ref(nameid bigint) RETURNS TABLE(group_id bigint, group_name text, group_year integer)
    LANGUAGE sql
    AS $$
select n.id group_id, n.sort_name group_name, min(r.year)
from name n
       join instance i
       join reference r on i.reference_id = r.id
         on n.id  = i.name_id
where n.id = nameid
group by n.id, sort_name
$$;


--
-- Name: inc_status(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.inc_status(nameid bigint) RETURNS text
    LANGUAGE sql
AS
$$
select 'included' :: text
where exists(select 1
             from tree_element te2
             where synonyms @> (select '{"list":[{"name_id":' || nameId || ', "mis":false}]}') :: JSONB)
$$;


--
-- Name: instance_notification(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.instance_notification() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF (TG_OP = 'DELETE')
  THEN
    INSERT INTO notification (id, version, message, object_id)
      SELECT
        nextval('hibernate_sequence'),
        0,
        'instance deleted',
        OLD.id;
    RETURN OLD;
  ELSIF (TG_OP = 'UPDATE')
    THEN
      INSERT INTO notification (id, version, message, object_id)
        SELECT
          nextval('hibernate_sequence'),
          0,
          'instance updated',
          NEW.id;
      RETURN NEW;
  ELSIF (TG_OP = 'INSERT')
    THEN
      INSERT INTO notification (id, version, message, object_id)
        SELECT
          nextval('hibernate_sequence'),
          0,
          'instance created',
          NEW.id;
      RETURN NEW;
  END IF;
  RETURN NULL;
END;
$$;


--
-- Name: instance_on_accepted_tree(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.instance_on_accepted_tree(instanceid bigint) RETURNS TABLE(current boolean, excluded boolean, element_link text, tree_name text)
    LANGUAGE sql
    AS $$
select t.current_tree_version_id = tv.id, te.excluded, tve.element_link, t.name
from tree_element te
       join tree_version_element tve on te.id = tve.tree_element_id
       join tree_version tv on tve.tree_version_id = tv.id
       join tree t on tv.tree_id = t.id and t.accepted_tree
where te.instance_id = instanceId
  and tv.published
order by tve.tree_version_id desc
limit 1;
$$;


--
-- Name: instance_on_accepted_tree_jsonb(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.instance_on_accepted_tree_jsonb(instanceid bigint) RETURNS jsonb
    LANGUAGE sql
    AS $$
select jsonb_agg(
         jsonb_build_object(
             'current', tve.current,
             'excluded', tve.excluded,
             'element_link', tve.element_link,
             'tree_name', tve.tree_name
             )
           )
from instance_on_accepted_tree(instanceid) tve
$$;


--
-- Name: instance_resources(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.instance_resources(instanceid bigint) RETURNS TABLE(name text, description text, url text, css_icon text, media_icon text)
    LANGUAGE sql
    AS $$
select rd.name, rd.description, s.url || '/' || r.path, rd.css_icon, 'media/' || m.id
from instance_resources ir
       join resource r on ir.resource_id = r.id
       join site s on r.site_id = s.id
       join resource_type rd on r.resource_type_id = rd.id
      left outer join media m on m.id = rd.media_icon_id
    where ir.instance_id = instanceid
$$;


--
-- Name: instance_resources_jsonb(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.instance_resources_jsonb(instanceid bigint) RETURNS jsonb
    LANGUAGE sql
    AS $$
select jsonb_agg(
         jsonb_build_object(
           'type', ir.name,
           'description', ir.description,
           'url', ir.url,
           'css_icon', ir.css_icon,
           'media_icon', ir.media_icon
         )
       )
from instance_resources(instanceid) ir
$$;


--
-- Name: latest_accepted_profile(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.latest_accepted_profile(instanceid bigint) RETURNS TABLE(comment_key text, comment_value text, dist_key text, dist_value text)
    LANGUAGE sql
    AS $$
select config ->> 'comment_key'                                 as comment_key,
       (profile -> (config ->> 'comment_key')) ->> 'value'      as comment_value,
       config ->> 'distribution_key'                            as dist_key,
       (profile -> (config ->> 'distribution_key')) ->> 'value' as dist_value
from tree_version_element tve
       join tree_element te on tve.tree_element_id = te.id
       join tree_version tv on tve.tree_version_id = tv.id and tv.published
       join tree t on tv.tree_id = t.id and t.accepted_tree
where te.instance_id = instanceid
order by tv.id desc
limit 1
$$;


--
-- Name: latest_accepted_profile_jsonb(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.latest_accepted_profile_jsonb(instanceid bigint) RETURNS jsonb
    LANGUAGE sql
    AS $$
select jsonb_build_object(
         'comment_key', comment_key,
         'comment_value', comment_value,
         'dist_key', dist_key,
         'dist_value', dist_value
           )
from latest_accepted_profile(instanceid)
$$;


--
-- Name: latest_accepted_profile_text(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.latest_accepted_profile_text(instanceid bigint) RETURNS text
    LANGUAGE sql
    AS $$
select '  ' ||
       case
         when comment_value is not null
                 then comment_key || ': ' || comment_value
         else ''
           end ||
       case
         when dist_value is not null
                 then dist_key || ': ' || dist_value
         else ''
           end ||
       E'
'
from latest_accepted_profile(instanceid)
$$;


--
-- Name: name_name_path(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.name_name_path(target_name_id bigint) RETURNS TABLE(name_path text, family_id bigint)
    LANGUAGE sql
    AS $$
with pathElements (id, path_element, rank_name) as (
  WITH RECURSIVE walk (id, parent_id, path_element, pos, rank_name) AS (
    SELECT
      n.id,
      n.parent_id,
      n.name_element,
      1,
      rank.name
    FROM name n
      join name_rank rank on n.name_rank_id = rank.id
    WHERE n.id = target_name_id
    UNION ALL
    SELECT
      n.id,
      n.parent_id,
      n.name_element,
      walk.pos + 1,
      rank.name
    FROM walk, name n
      join name_rank rank on n.name_rank_id = rank.id
    WHERE n.id = walk.parent_id
  )
  SELECT
    id,
    path_element,
    rank_name
  FROM walk
  order by walk.pos desc)
select
  string_agg(path_element, '/'),
  (select id
   from pathElements p2
   where p2.rank_name = 'Familia'
   limit 1)
from pathElements;
$$;


--
-- Name: name_notification(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.name_notification() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF (TG_OP = 'DELETE')
  THEN
    INSERT INTO notification (id, version, message, object_id)
      SELECT
        nextval('hibernate_sequence'),
        0,
        'name deleted',
        OLD.id;
    RETURN OLD;
  ELSIF (TG_OP = 'UPDATE')
    THEN
      INSERT INTO notification (id, version, message, object_id)
        SELECT
          nextval('hibernate_sequence'),
          0,
          'name updated',
          NEW.id;
      RETURN NEW;
  ELSIF (TG_OP = 'INSERT')
    THEN
      INSERT INTO notification (id, version, message, object_id)
        SELECT
          nextval('hibernate_sequence'),
          0,
          'name created',
          NEW.id;
      RETURN NEW;
  END IF;
  RETURN NULL;
END;
$$;


--
-- Name: non_type_notes(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.non_type_notes(instanceid bigint) RETURNS TABLE(note_key text, note text)
    LANGUAGE sql
    AS $$
select k.name, nt.value
from instance_note nt
       join instance_note_key k on nt.instance_note_key_id = k.id
where nt.instance_id = instanceid
  and k.name not ilike '%type'
$$;


--
-- Name: non_type_notes_jsonb(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.non_type_notes_jsonb(instanceid bigint) RETURNS jsonb
    LANGUAGE sql
    AS $$
select jsonb_agg(
         jsonb_build_object(
           'note_key', nt.note_key,
           'note_value', nt.note
             )
           )
from non_type_notes(instanceid) as nt
$$;


--
-- Name: non_type_notes_text(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.non_type_notes_text(instanceid bigint) RETURNS text
    LANGUAGE sql
    AS $$
select string_agg('  ' || nt.note_key || ': ' || nt.note || E'
', E'
')
from non_type_notes(instanceid) as nt
$$;


--
-- Name: orth_or_alt_of(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.orth_or_alt_of(nameid bigint) RETURNS bigint
    LANGUAGE sql
    AS $$
select coalesce((select alt_of_inst.name_id
                 from name n
                        join name_status ns on n.name_status_id = ns.id
                        join instance alt_inst on n.id = alt_inst.name_id
                        join instance_type alt_it on alt_inst.instance_type_id = alt_it.id and
                                                     alt_it.name in ('orthographic variant', 'alternative name')
                        join instance alt_of_inst on alt_of_inst.id = alt_inst.cited_by_id
                 where n.id = nameid
                   and ns.name ~ '(orth. var.|nom. alt.)' limit 1), nameid) id
$$;


--
-- Name: pbool(boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pbool(bool boolean) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
begin
return case bool
       when true
        then 'true'
      else
        ''
      end;
end; $$;


--
-- Name: profile_as_jsonb(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.profile_as_jsonb(source_instance_id bigint) RETURNS jsonb
    LANGUAGE sql
    AS $$
SELECT jsonb_object_agg(key.name, jsonb_build_object(
    'value', note.value,
    'created_at', note.created_at,
    'created_by', note.created_by,
    'updated_at', note.updated_at,
    'updated_by', note.updated_by,
    'source_link', 'https://id.biodiversity.org.au' || '/instanceNote/apni/' || note.id
))
FROM instance i
  JOIN instance_note note ON i.id = note.instance_id
  JOIN instance_note_key key ON note.instance_note_key_id = key.id
WHERE i.id = source_instance_id;
$$;


--
-- Name: public_apc_distribution(text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.public_apc_distribution(status text, regions text)
    RETURNS TABLE
            (
                tree          text,
                element_link  text,
                simple_name   text,
                display_html  text,
                synonyms_html text,
                dist          text,
                rank          text,
                name_path     text
            )
    LANGUAGE sql
AS
$$
with nat_reg as (
    select te.id,
           te.simple_name,
           te.display_html,
           te.synonyms_html,
           te.profile -> 'APC Dist.' ->> 'value' as dist,
           te.rank,
           string_agg(de.display, ', ')
    from tree_element te
             join tree_element_distribution_entries tede on te.id = tede.tree_element_id
             join dist_entry de on tede.dist_entry_id = de.id
             join dist_region dr on de.region_id = dr.id and dr.name ~ regions
             join dist_entry_dist_status deds on de.id = deds.dist_entry_status_id
             join dist_status ds on deds.dist_status_id = ds.id and ds.name ~ status
    group by te.id
)
select t.name                          as tree,
       t.host_name || tve.element_link as element_link,
       simple_name,
       display_html,
       synonyms_html,
       dist,
       rank,
       name_path
from tree t
         join tree_version_element tve on t.current_tree_version_id = tve.tree_version_id
         join nat_reg e on e.id = tve.tree_element_id
where t.accepted_tree
order by tve.name_path
$$;


--
-- Name: reference_notification(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.reference_notification() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF (TG_OP = 'DELETE')
  THEN
    INSERT INTO notification (id, version, message, object_id)
      SELECT
        nextval('hibernate_sequence'),
        0,
        'reference deleted',
        OLD.id;
    RETURN OLD;
  ELSIF (TG_OP = 'UPDATE')
    THEN
      INSERT INTO notification (id, version, message, object_id)
        SELECT
          nextval('hibernate_sequence'),
          0,
          'reference updated',
          NEW.id;
      RETURN NEW;
  ELSIF (TG_OP = 'INSERT')
    THEN
      INSERT INTO notification (id, version, message, object_id)
        SELECT
          nextval('hibernate_sequence'),
          0,
          'reference created',
          NEW.id;
      RETURN NEW;
  END IF;
  RETURN NULL;
END;
$$;


--
-- Name: synonym_as_html(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.synonym_as_html(instanceid bigint) RETURNS TABLE(html text)
    LANGUAGE sql
    AS $$
SELECT CASE
         WHEN it.nomenclatural
             THEN '<nom>' || full_name_html || '<name-status class="' || name_status || '">, ' || name_status ||
                  '</name-status> <year>(' || year || ')<year> <type>' || instance_type || '</type></nom>'
         WHEN it.taxonomic
             THEN '<tax>' || full_name_html || '<name-status class="' || name_status || '">, ' || name_status ||
                  '</name-status> <year>(' || year || ')<year> <type>' || instance_type || '</type></tax>'
         WHEN it.misapplied
             THEN '<mis>' || full_name_html || '<name-status class="' || name_status || '">, ' || name_status ||
                  '</name-status><type>' || instance_type || '</type> by <citation>' ||
                  citation_html || '</citation></mis>'
         WHEN it.synonym
             THEN '<syn>' || full_name_html || '<name-status class="' || name_status || '">, ' || name_status ||
                  '</name-status> <year>(' || year || ')<year> <type>' || it.name || '</type></syn>'
         ELSE '<oth>' || full_name_html || '<name-status class="' || name_status || '">, ' || name_status ||
              '</name-status> <type>' || it.name || '</type></oth>'
           END
FROM apni_ordered_synonymy(instanceid)
       join instance_type it on instance_type_id = it.id
$$;


--
-- Name: synonyms_as_html(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.synonyms_as_html(instance_id bigint) RETURNS text
    LANGUAGE sql
    AS $$
SELECT '<synonyms>' || string_agg(html, '') || '</synonyms>'
FROM synonym_as_html(instance_id) AS html;
$$;


--
-- Name: synonyms_as_jsonb(bigint, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.synonyms_as_jsonb(instance_id bigint, host text) RETURNS jsonb
    LANGUAGE sql
    AS $$
SELECT jsonb_build_object('list',
                          coalesce(
                                  jsonb_agg(jsonb_build_object(
                                          'host', host,
                                          'instance_id', syn_inst.id,
                                          'instance_link', syn_inst.uri,
                                          'concept_link', coalesce(cites_inst.uri, syn_inst.uri),
                                          'simple_name', synonym.simple_name,
                                          'type', it.name,
                                          'name_id', synonym.id :: BIGINT,
                                          'name_link', synonym.uri,
                                          'full_name_html', synonym.full_name_html,
                                          'nom', it.nomenclatural,
                                          'tax', it.taxonomic,
                                          'mis', it.misapplied,
                                          'cites', coalesce(cites_ref.citation, syn_ref.citation),
                                          'cites_html', coalesce(cites_ref.citation_html, syn_ref.citation_html),
                                          'cites_link', '/reference/' || lower(conf.value) || '/' ||
                                                        (coalesce(cites_ref.id, syn_ref.id)),
                                          'year', cites_ref.year
                                      )), '[]' :: JSONB)
           )
FROM Instance i,
     Instance syn_inst
         JOIN instance_type it ON syn_inst.instance_type_id = it.id
         JOIN reference syn_ref on syn_inst.reference_id = syn_ref.id
         LEFT JOIN instance cites_inst ON syn_inst.cites_id = cites_inst.id
         LEFT JOIN reference cites_ref ON cites_inst.reference_id = cites_ref.id
    ,
     name synonym,
     shard_config conf
WHERE i.id = instance_id
  AND syn_inst.cited_by_id = i.id
  AND synonym.id = syn_inst.name_id
  AND conf.name = 'name space';
$$;


--
-- Name: tree_element_data_from_start_node(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.tree_element_data_from_start_node(root_node bigint) RETURNS TABLE(tree_id bigint, node_id bigint, excluded boolean, declared_bt boolean, instance_id bigint, name_id bigint, simple_name text, name_path text, instance_path text, parent_instance_path text, parent_excluded boolean, depth integer)
    LANGUAGE sql
    AS $$
WITH RECURSIVE treewalk (tree_id, node_id, excluded, declared_bt, instance_id, name_id, simple_name, name_path, instance_path,
    parent_instance_path, parent_excluded, depth) AS (
  SELECT
    tree.id                   AS tree_id,
    node.id                   AS node_id,
    (node.type_uri_id_part <>
     'ApcConcept') :: BOOLEAN AS excluded,
    (node.type_uri_id_part =
     'DeclaredBt') :: BOOLEAN AS declared_bt,
    node.instance_id          AS instance_id,
    node.name_id              AS name_id,
    n.simple_name :: TEXT     AS simple_name,
    coalesce(n.name_element,
             '?')             AS name_path,
    CASE
    WHEN (node.type_uri_id_part = 'ApcConcept')
      THEN
        node.instance_id :: TEXT
    WHEN (node.type_uri_id_part = 'DeclaredBt')
      THEN
        'b' || node.instance_id :: TEXT
    ELSE
      'x' || node.instance_id :: TEXT
    END                       AS instance_path,
    ''                        AS parent_instance_path,
    FALSE                     AS parent_excluded,
    1                         AS depth
  FROM tree_link link
    JOIN tree_node node ON link.subnode_id = node.id
    JOIN tree_arrangement tree ON node.tree_arrangement_id = tree.id
    JOIN name n ON node.name_id = n.id
    JOIN name_rank rank ON n.name_rank_id = rank.id
    JOIN instance inst ON node.instance_id = inst.id
    JOIN reference ref ON inst.reference_id = ref.id
  WHERE link.supernode_id = root_node
        AND node.internal_type = 'T'
  UNION ALL
  SELECT
    treewalk.tree_id                           AS tree_id,
    node.id                                    AS node_id,
    (node.type_uri_id_part <>
     'ApcConcept') :: BOOLEAN                  AS excluded,
    (node.type_uri_id_part =
     'DeclaredBt') :: BOOLEAN                  AS declared_bt,
    node.instance_id                           AS instance_id,
    node.name_id                               AS name_id,
    n.simple_name :: TEXT                      AS simple_name,
    treewalk.name_path || '/' || COALESCE(n.name_element,
                                          '?') AS name_path,
    CASE
    WHEN (node.type_uri_id_part = 'ApcConcept')
      THEN
        treewalk.instance_path || '/' || node.instance_id :: TEXT
    WHEN (node.type_uri_id_part = 'DeclaredBt')
      THEN
        treewalk.instance_path || '/b' || node.instance_id :: TEXT
    ELSE
      treewalk.instance_path || '/x' || node.instance_id :: TEXT
    END                                        AS instance_path,
    treewalk.instance_path                     AS parent_instance_path,
    treewalk.excluded                          AS parent_excluded,
    treewalk.depth + 1                         AS depth
  FROM treewalk
    JOIN tree_link link ON link.supernode_id = treewalk.node_id
    JOIN tree_node node ON link.subnode_id = node.id
    JOIN name n ON node.name_id = n.id
    JOIN name_rank rank ON n.name_rank_id = rank.id
    JOIN instance inst ON node.instance_id = inst.id
    JOIN reference REF ON inst.reference_id = REF.id
  WHERE node.internal_type = 'T'
        AND node.tree_arrangement_id = treewalk.tree_id
)
SELECT
  tree_id,
  node_id,
  excluded,
  declared_bt,
  instance_id,
  name_id,
  simple_name,
  name_path,
  instance_path,
  parent_instance_path,
  parent_excluded,
  depth
FROM treewalk
$$;


--
-- Name: type_notes(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.type_notes(instanceid bigint) RETURNS TABLE(note_key text, note text)
    LANGUAGE sql
    AS $$
select k.name, nt.value
from instance_note nt
       join instance_note_key k on nt.instance_note_key_id = k.id
where nt.instance_id = instanceid
  and k.name ilike '%type'
$$;


--
-- Name: type_notes_jsonb(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.type_notes_jsonb(instanceid bigint) RETURNS jsonb
    LANGUAGE sql
    AS $$
select jsonb_agg(
         jsonb_build_object(
           'note_key', nt.note_key,
           'note_value', nt.note
             )
           )
from type_notes(instanceid) as nt
$$;


--
-- Name: type_notes_text(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.type_notes_text(instanceid bigint) RETURNS text
    LANGUAGE sql
    AS $$
select string_agg('  ' || nt.note_key || ': ' || nt.note || E'
', E'
')
from type_notes(instanceid) as nt
$$;


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: logged_actions; Type: TABLE; Schema: audit; Owner: -
--

CREATE TABLE audit.logged_actions (
    event_id bigint NOT NULL,
    schema_name text NOT NULL,
    table_name text NOT NULL,
    relid oid NOT NULL,
    session_user_name text,
    action_tstamp_tx timestamp with time zone NOT NULL,
    action_tstamp_stm timestamp with time zone NOT NULL,
    action_tstamp_clk timestamp with time zone NOT NULL,
    transaction_id bigint,
    application_name text,
    client_addr inet,
    client_port integer,
    client_query text,
    action text NOT NULL,
    row_data public.hstore,
    changed_fields public.hstore,
    statement_only boolean NOT NULL,
    CONSTRAINT logged_actions_action_check CHECK ((action = ANY (ARRAY['I'::text, 'D'::text, 'U'::text, 'T'::text])))
);


--
-- Name: TABLE logged_actions; Type: COMMENT; Schema: audit; Owner: -
--

COMMENT ON TABLE audit.logged_actions IS 'History of auditable actions on audited tables, from audit.if_modified_func()';


--
-- Name: COLUMN logged_actions.event_id; Type: COMMENT; Schema: audit; Owner: -
--

COMMENT ON COLUMN audit.logged_actions.event_id IS 'Unique identifier for each auditable event';


--
-- Name: COLUMN logged_actions.schema_name; Type: COMMENT; Schema: audit; Owner: -
--

COMMENT ON COLUMN audit.logged_actions.schema_name IS 'Database schema audited table for this event is in';


--
-- Name: COLUMN logged_actions.table_name; Type: COMMENT; Schema: audit; Owner: -
--

COMMENT ON COLUMN audit.logged_actions.table_name IS 'Non-schema-qualified table name of table event occured in';


--
-- Name: COLUMN logged_actions.relid; Type: COMMENT; Schema: audit; Owner: -
--

COMMENT ON COLUMN audit.logged_actions.relid IS 'Table OID. Changes with drop/create. Get with ''tablename''::regclass';


--
-- Name: COLUMN logged_actions.session_user_name; Type: COMMENT; Schema: audit; Owner: -
--

COMMENT ON COLUMN audit.logged_actions.session_user_name IS 'Login / session user whose statement caused the audited event';


--
-- Name: COLUMN logged_actions.action_tstamp_tx; Type: COMMENT; Schema: audit; Owner: -
--

COMMENT ON COLUMN audit.logged_actions.action_tstamp_tx IS 'Transaction start timestamp for tx in which audited event occurred';


--
-- Name: COLUMN logged_actions.action_tstamp_stm; Type: COMMENT; Schema: audit; Owner: -
--

COMMENT ON COLUMN audit.logged_actions.action_tstamp_stm IS 'Statement start timestamp for tx in which audited event occurred';


--
-- Name: COLUMN logged_actions.action_tstamp_clk; Type: COMMENT; Schema: audit; Owner: -
--

COMMENT ON COLUMN audit.logged_actions.action_tstamp_clk IS 'Wall clock time at which audited event''s trigger call occurred';


--
-- Name: COLUMN logged_actions.transaction_id; Type: COMMENT; Schema: audit; Owner: -
--

COMMENT ON COLUMN audit.logged_actions.transaction_id IS 'Identifier of transaction that made the change. May wrap, but unique paired with action_tstamp_tx.';


--
-- Name: COLUMN logged_actions.application_name; Type: COMMENT; Schema: audit; Owner: -
--

COMMENT ON COLUMN audit.logged_actions.application_name IS 'Application name set when this audit event occurred. Can be changed in-session by client.';


--
-- Name: COLUMN logged_actions.client_addr; Type: COMMENT; Schema: audit; Owner: -
--

COMMENT ON COLUMN audit.logged_actions.client_addr IS 'IP address of client that issued query. Null for unix domain socket.';


--
-- Name: COLUMN logged_actions.client_port; Type: COMMENT; Schema: audit; Owner: -
--

COMMENT ON COLUMN audit.logged_actions.client_port IS 'Remote peer IP port address of client that issued query. Undefined for unix socket.';


--
-- Name: COLUMN logged_actions.client_query; Type: COMMENT; Schema: audit; Owner: -
--

COMMENT ON COLUMN audit.logged_actions.client_query IS 'Top-level query that caused this auditable event. May be more than one statement.';


--
-- Name: COLUMN logged_actions.action; Type: COMMENT; Schema: audit; Owner: -
--

COMMENT ON COLUMN audit.logged_actions.action IS 'Action type; I = insert, D = delete, U = update, T = truncate';


--
-- Name: COLUMN logged_actions.row_data; Type: COMMENT; Schema: audit; Owner: -
--

COMMENT ON COLUMN audit.logged_actions.row_data IS 'Record value. Null for statement-level trigger. For INSERT this is the new tuple. For DELETE and UPDATE it is the old tuple.';


--
-- Name: COLUMN logged_actions.changed_fields; Type: COMMENT; Schema: audit; Owner: -
--

COMMENT ON COLUMN audit.logged_actions.changed_fields IS 'New values of fields changed by UPDATE. Null except for row-level UPDATE events.';


--
-- Name: COLUMN logged_actions.statement_only; Type: COMMENT; Schema: audit; Owner: -
--

COMMENT ON COLUMN audit.logged_actions.statement_only IS '''t'' if audit event is from an FOR EACH STATEMENT trigger, ''f'' for FOR EACH ROW';


--
-- Name: logged_actions_event_id_seq; Type: SEQUENCE; Schema: audit; Owner: -
--

CREATE SEQUENCE audit.logged_actions_event_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: logged_actions_event_id_seq; Type: SEQUENCE OWNED BY; Schema: audit; Owner: -
--

ALTER SEQUENCE audit.logged_actions_event_id_seq OWNED BY audit.logged_actions.event_id;


--
-- Name: db_version; Type: TABLE; Schema: mapper; Owner: -
--

CREATE TABLE mapper.db_version (
    id bigint NOT NULL,
    version integer NOT NULL
);


--
-- Name: mapper_sequence; Type: SEQUENCE; Schema: mapper; Owner: -
--

CREATE SEQUENCE mapper.mapper_sequence
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: host; Type: TABLE; Schema: mapper; Owner: -
--

CREATE TABLE mapper.host (
    id bigint DEFAULT nextval('mapper.mapper_sequence'::regclass) NOT NULL,
    host_name character varying(512) NOT NULL,
    preferred boolean DEFAULT false NOT NULL
);


--
-- Name: identifier; Type: TABLE; Schema: mapper; Owner: -
--

CREATE TABLE mapper.identifier (
    id bigint DEFAULT nextval('mapper.mapper_sequence'::regclass) NOT NULL,
    id_number bigint NOT NULL,
    name_space character varying(255) NOT NULL,
    object_type character varying(255) NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    reason_deleted character varying(255),
    updated_at timestamp with time zone,
    updated_by character varying(255),
    preferred_uri_id bigint,
    version_number bigint
);


--
-- Name: identifier_identities; Type: TABLE; Schema: mapper; Owner: -
--

CREATE TABLE mapper.identifier_identities (
    match_id bigint NOT NULL,
    identifier_id bigint NOT NULL
);


--
-- Name: match; Type: TABLE; Schema: mapper; Owner: -
--

CREATE TABLE mapper.match (
    id bigint DEFAULT nextval('mapper.mapper_sequence'::regclass) NOT NULL,
    uri character varying(255) NOT NULL,
    deprecated boolean DEFAULT false NOT NULL,
    updated_at timestamp with time zone,
    updated_by character varying(255)
);


--
-- Name: match_host; Type: TABLE; Schema: mapper; Owner: -
--

CREATE TABLE mapper.match_host (
    match_hosts_id bigint,
    host_id bigint
);


--
-- Name: nsl_global_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.nsl_global_seq;
--     START WITH 50000001
--     INCREMENT BY 1
--     MINVALUE 50000001
--     MAXVALUE 60000000
--     CACHE 1;


--
-- Name: author; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.author (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    abbrev character varying(100),
    created_at timestamp with time zone NOT NULL,
    created_by character varying(255) NOT NULL,
    date_range character varying(50),
    duplicate_of_id bigint,
    full_name character varying(255),
    ipni_id character varying(50),
    name character varying(1000),
    namespace_id bigint NOT NULL,
    notes character varying(1000),
    source_id bigint,
    source_id_string character varying(100),
    source_system character varying(50),
    updated_at timestamp with time zone NOT NULL,
    updated_by character varying(255) NOT NULL,
    valid_record boolean DEFAULT false NOT NULL,
    uri text
);


--
-- Name: hibernate_sequence; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hibernate_sequence
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: comment; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.comment (
    id bigint DEFAULT nextval('public.hibernate_sequence'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    author_id bigint,
    created_at timestamp with time zone NOT NULL,
    created_by character varying(50) NOT NULL,
    instance_id bigint,
    name_id bigint,
    reference_id bigint,
    text text NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    updated_by character varying(50) NOT NULL
);


--
-- Name: instance; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.instance
(
    id                   bigint  DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    lock_version         bigint  DEFAULT 0                                          NOT NULL,
    bhl_url              character varying(4000),
    cited_by_id          bigint,
    cites_id             bigint,
    created_at           timestamp with time zone                                   NOT NULL,
    created_by           character varying(50)                                      NOT NULL,
    draft                boolean DEFAULT false                                      NOT NULL,
    instance_type_id     bigint                                                     NOT NULL,
    name_id              bigint                                                     NOT NULL,
    namespace_id         bigint                                                     NOT NULL,
    nomenclatural_status character varying(50),
    page                 character varying(255),
    page_qualifier       character varying(255),
    parent_id            bigint,
    reference_id         bigint                                                     NOT NULL,
    source_id            bigint,
    source_id_string     character varying(100),
    source_system        character varying(50),
    updated_at           timestamp with time zone                                   NOT NULL,
    updated_by           character varying(1000)                                    NOT NULL,
    valid_record         boolean DEFAULT false                                      NOT NULL,
    verbatim_name_string character varying(255),
    uri                  text,
    cached_synonymy_html text,
    CONSTRAINT citescheck CHECK (((cites_id IS NULL) OR (cited_by_id IS NOT NULL)))
);


--
-- Name: instance_type; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.instance_type
(
    id                 bigint                 DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    lock_version       bigint                 DEFAULT 0                                          NOT NULL,
    citing             boolean                DEFAULT false                                      NOT NULL,
    deprecated         boolean                DEFAULT false                                      NOT NULL,
    doubtful           boolean                DEFAULT false                                      NOT NULL,
    misapplied         boolean                DEFAULT false                                      NOT NULL,
    name               character varying(255)                                                    NOT NULL,
    nomenclatural      boolean                DEFAULT false                                      NOT NULL,
    primary_instance   boolean                DEFAULT false                                      NOT NULL,
    pro_parte          boolean                DEFAULT false                                      NOT NULL,
    protologue         boolean                DEFAULT false                                      NOT NULL,
    relationship       boolean                DEFAULT false                                      NOT NULL,
    secondary_instance boolean                DEFAULT false                                      NOT NULL,
    sort_order         integer                DEFAULT 0                                          NOT NULL,
    standalone         boolean                DEFAULT false                                      NOT NULL,
    synonym            boolean                DEFAULT false                                      NOT NULL,
    taxonomic          boolean                DEFAULT false                                      NOT NULL,
    unsourced          boolean                DEFAULT false                                      NOT NULL,
    description_html   text,
    rdf_id             character varying(50),
    has_label          character varying(255) DEFAULT 'not set'::character varying               NOT NULL,
    of_label           character varying(255) DEFAULT 'not set'::character varying               NOT NULL,
    bidirectional      boolean                DEFAULT false                                      NOT NULL
);


--
-- Name: name; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.name
(
    id                    bigint  DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    lock_version          bigint  DEFAULT 0                                          NOT NULL,
    author_id             bigint,
    base_author_id        bigint,
    created_at            timestamp with time zone                                   NOT NULL,
    created_by            character varying(50)                                      NOT NULL,
    duplicate_of_id       bigint,
    ex_author_id          bigint,
    ex_base_author_id     bigint,
    full_name             character varying(512),
    full_name_html        character varying(2048),
    name_element          character varying(255),
    name_rank_id          bigint                                                     NOT NULL,
    name_status_id        bigint                                                     NOT NULL,
    name_type_id          bigint                                                     NOT NULL,
    namespace_id          bigint                                                     NOT NULL,
    orth_var              boolean DEFAULT false                                      NOT NULL,
    parent_id             bigint,
    sanctioning_author_id bigint,
    second_parent_id      bigint,
    simple_name           character varying(250),
    simple_name_html      character varying(2048),
    source_dup_of_id      bigint,
    source_id             bigint,
    source_id_string      character varying(100),
    source_system         character varying(50),
    status_summary        character varying(50),
    updated_at            timestamp with time zone                                   NOT NULL,
    updated_by            character varying(50)                                      NOT NULL,
    valid_record          boolean DEFAULT false                                      NOT NULL,
    verbatim_rank         character varying(50),
    sort_name             character varying(250),
    family_id             bigint,
    name_path             text    DEFAULT ''::text                                   NOT NULL,
    uri                   text,
    changed_combination   boolean DEFAULT false                                      NOT NULL,
    published_year        integer,
    apni_json             jsonb,
    CONSTRAINT published_year_limits CHECK (((published_year > 0) AND (published_year < 2500)))
);


--
-- Name: reference; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reference
(
    id                 bigint  DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    lock_version       bigint  DEFAULT 0                                          NOT NULL,
    abbrev_title       character varying(2000),
    author_id          bigint                                                     NOT NULL,
    bhl_url            character varying(4000),
    citation           character varying(4000),
    citation_html      character varying(4000),
    created_at         timestamp with time zone                                   NOT NULL,
    created_by         character varying(255)                                     NOT NULL,
    display_title      character varying(2000)                                    NOT NULL,
    doi                character varying(255),
    duplicate_of_id    bigint,
    edition            character varying(100),
    isbn               character varying(16),
    issn               character varying(16),
    language_id        bigint                                                     NOT NULL,
    namespace_id       bigint                                                     NOT NULL,
    notes              character varying(1000),
    pages              character varying(1000),
    parent_id          bigint,
    publication_date   character varying(50),
    published          boolean DEFAULT false                                      NOT NULL,
    published_location character varying(1000),
    publisher          character varying(1000),
    ref_author_role_id bigint                                                     NOT NULL,
    ref_type_id        bigint                                                     NOT NULL,
    source_id          bigint,
    source_id_string   character varying(100),
    source_system      character varying(50),
    title              character varying(2000)                                    NOT NULL,
    tl2                character varying(30),
    updated_at         timestamp with time zone                                   NOT NULL,
    updated_by         character varying(1000)                                    NOT NULL,
    valid_record       boolean DEFAULT false                                      NOT NULL,
    verbatim_author    character varying(1000),
    verbatim_citation  character varying(2000),
    verbatim_reference character varying(1000),
    volume             character varying(100),
    year               integer,
    uri                text,
    iso_publication_date character varying(10)
);


--
-- Name: shard_config; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.shard_config
(
    id         bigint  DEFAULT nextval('public.hibernate_sequence'::regclass) NOT NULL,
    name       character varying(255)                                         NOT NULL,
    value      character varying(5000)                                        NOT NULL,
    deprecated boolean DEFAULT false                                          NOT NULL,
    use_notes  character varying(255)
);


--
-- Name: common_name_export; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.common_name_export AS
SELECT ((mapper_host.value)::text || cn.uri)               AS common_name_id,
       cn.full_name                                        AS common_name,
       ((mapper_host.value)::text || i.uri)                AS instance_id,
       r.citation,
       ((mapper_host.value)::text || n.uri)                AS scientific_name_id,
       n.full_name                                         AS scientific_name,
       dataset.value                                       AS "datasetName",
       'http://creativecommons.org/licenses/by/3.0/'::text AS license,
       ((mapper_host.value)::text || n.uri)                AS "ccAttributionIRI"
FROM (((((public.instance i
    JOIN public.instance_type it ON ((i.instance_type_id = it.id)))
    JOIN public.name cn ON ((i.name_id = cn.id)))
    JOIN public.reference r ON ((i.reference_id = r.id)))
    JOIN public.instance cbi ON ((i.cited_by_id = cbi.id)))
         JOIN public.name n ON ((cbi.name_id = n.id))),
     public.shard_config mapper_host,
     public.shard_config dataset
WHERE (((it.name)::text = 'common name'::text) AND ((mapper_host.name)::text = 'mapper host'::text) AND
       ((dataset.name)::text = 'name label'::text));


--
-- Name: tree; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tree
(
    id                            bigint  DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    lock_version                  bigint  DEFAULT 0                                          NOT NULL,
    accepted_tree                 boolean DEFAULT false                                      NOT NULL,
    config                        jsonb,
    current_tree_version_id       bigint,
    default_draft_tree_version_id bigint,
    description_html              text    DEFAULT 'Edit me'::text                            NOT NULL,
    group_name                    text                                                       NOT NULL,
    host_name                     text                                                       NOT NULL,
    link_to_home_page             text,
    name                          text                                                       NOT NULL,
    reference_id                  bigint,
    CONSTRAINT draft_not_current CHECK ((current_tree_version_id <> default_draft_tree_version_id))
);


--
-- Name: tree_element; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tree_element
(
    id                  bigint  DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    lock_version        bigint  DEFAULT 0                                          NOT NULL,
    display_html        text                                                       NOT NULL,
    excluded            boolean DEFAULT false                                      NOT NULL,
    instance_id         bigint                                                     NOT NULL,
    instance_link       text                                                       NOT NULL,
    name_element        character varying(255)                                     NOT NULL,
    name_id             bigint                                                     NOT NULL,
    name_link           text                                                       NOT NULL,
    previous_element_id bigint,
    profile             jsonb,
    rank                character varying(50)                                      NOT NULL,
    simple_name         text                                                       NOT NULL,
    source_element_link text,
    source_shard        text                                                       NOT NULL,
    synonyms            jsonb,
    synonyms_html       text                                                       NOT NULL,
    updated_at          timestamp with time zone                                   NOT NULL,
    updated_by          character varying(255)                                     NOT NULL
);


--
-- Name: tree_version; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tree_version
(
    id                  bigint  DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    lock_version        bigint  DEFAULT 0                                          NOT NULL,
    created_at          timestamp with time zone                                   NOT NULL,
    created_by          character varying(255)                                     NOT NULL,
    draft_name          text                                                       NOT NULL,
    log_entry           text,
    previous_version_id bigint,
    published           boolean DEFAULT false                                      NOT NULL,
    published_at        timestamp with time zone,
    published_by        character varying(100),
    tree_id             bigint                                                     NOT NULL
);


--
-- Name: tree_version_element; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tree_version_element
(
    element_link    text                     NOT NULL,
    depth           integer                  NOT NULL,
    name_path       text                     NOT NULL,
    parent_id       text,
    taxon_id        bigint                   NOT NULL,
    taxon_link      text                     NOT NULL,
    tree_element_id bigint                   NOT NULL,
    tree_path       text                     NOT NULL,
    tree_version_id bigint                   NOT NULL,
    updated_at      timestamp with time zone NOT NULL,
    updated_by      character varying(255)   NOT NULL,
    merge_conflict  boolean DEFAULT false    NOT NULL
);


--
-- Name: tree_vw; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.tree_vw AS
SELECT t.id                AS tree_id,
       t.accepted_tree,
       t.config,
       t.current_tree_version_id,
       t.default_draft_tree_version_id,
       t.description_html,
       t.group_name,
       t.host_name,
       t.link_to_home_page,
       t.name,
       t.reference_id,
       tv.id               AS tree_version_id,
       tv.draft_name,
       tv.log_entry,
       tv.previous_version_id,
       tv.published,
       tv.published_at,
       tv.published_by,
       tve.element_link,
       tve.depth,
       tve.name_path,
       tve.parent_id,
       tve.taxon_id,
       tve.taxon_link,
       tve.tree_element_id AS tree_element_id_fk,
       tve.tree_path,
       tve.tree_version_id AS tree_version_id_fk,
       tve.merge_conflict,
       te.id               AS tree_element_id,
       te.display_html,
       te.excluded,
       te.instance_id,
       te.instance_link,
       te.name_element,
       te.name_id,
       te.name_link,
       te.previous_element_id,
       te.profile,
       te.rank,
       te.simple_name,
       te.source_element_link,
       te.source_shard,
       te.synonyms,
       te.synonyms_html
FROM (((public.tree t
    JOIN public.tree_version tv ON ((t.id = tv.tree_id)))
    JOIN public.tree_version_element tve ON ((tv.id = tve.tree_version_id)))
         JOIN public.tree_element te ON ((tve.tree_element_id = te.id)));


--
-- Name: current_accepted_tree_version_vw; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.current_accepted_tree_version_vw AS
SELECT tree_vw.tree_id,
       tree_vw.accepted_tree,
       tree_vw.config,
       tree_vw.current_tree_version_id,
       tree_vw.default_draft_tree_version_id,
       tree_vw.description_html,
       tree_vw.group_name,
       tree_vw.host_name,
       tree_vw.link_to_home_page,
       tree_vw.name,
       tree_vw.reference_id,
       tree_vw.tree_version_id,
       tree_vw.draft_name,
       tree_vw.log_entry,
       tree_vw.previous_version_id,
       tree_vw.published,
       tree_vw.published_at,
       tree_vw.published_by,
       tree_vw.element_link,
       tree_vw.depth,
       tree_vw.name_path,
       tree_vw.parent_id,
       tree_vw.taxon_id,
       tree_vw.taxon_link,
       tree_vw.tree_element_id_fk,
       tree_vw.tree_path,
       tree_vw.tree_version_id_fk,
       tree_vw.merge_conflict,
       tree_vw.tree_element_id,
       tree_vw.display_html,
       tree_vw.excluded,
       tree_vw.instance_id,
       tree_vw.instance_link,
       tree_vw.name_element,
       tree_vw.name_id,
       tree_vw.name_link,
       tree_vw.previous_element_id,
       tree_vw.profile,
       tree_vw.rank,
       tree_vw.simple_name,
       tree_vw.source_element_link,
       tree_vw.source_shard,
       tree_vw.synonyms,
       tree_vw.synonyms_html
FROM public.tree_vw
WHERE ((tree_vw.tree_version_id = tree_vw.current_tree_version_id) AND tree_vw.accepted_tree);


--
-- Name: db_version; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.db_version (
    id bigint NOT NULL,
    version integer NOT NULL
);


--
-- Name: delayed_jobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.delayed_jobs (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    attempts numeric(19,2),
    created_at timestamp with time zone NOT NULL,
    failed_at timestamp with time zone,
    handler text,
    last_error text,
    locked_at timestamp with time zone,
    locked_by character varying(4000),
    priority numeric(19,2),
    queue character varying(4000),
    run_at timestamp with time zone,
    updated_at timestamp with time zone NOT NULL
);


--
-- Name: dist_entry; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dist_entry
(
    id           bigint  DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint  DEFAULT 0                                          NOT NULL,
    display      character varying(255)                                     NOT NULL,
    region_id    bigint                                                     NOT NULL,
    sort_order   integer DEFAULT 0                                          NOT NULL
);


--
-- Name: dist_entry_dist_status; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dist_entry_dist_status
(
    dist_entry_status_id bigint,
    dist_status_id       bigint
);


--
-- Name: dist_region; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dist_region
(
    id               bigint  DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    lock_version     bigint  DEFAULT 0                                          NOT NULL,
    deprecated       boolean DEFAULT false                                      NOT NULL,
    description_html text,
    def_link         character varying(255),
    name             character varying(255)                                     NOT NULL,
    sort_order       integer DEFAULT 0                                          NOT NULL
);


--
-- Name: dist_status; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dist_status
(
    id               bigint  DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    lock_version     bigint  DEFAULT 0                                          NOT NULL,
    deprecated       boolean DEFAULT false                                      NOT NULL,
    description_html text,
    def_link         character varying(255),
    name             character varying(255)                                     NOT NULL,
    sort_order       integer DEFAULT 0                                          NOT NULL
);


--
-- Name: dist_status_dist_status; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dist_status_dist_status
(
    dist_status_combining_status_id bigint,
    dist_status_id                  bigint
);


--
-- Name: event_record; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.event_record (
    id bigint NOT NULL,
    version bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    created_by character varying(50) NOT NULL,
    data jsonb,
    dealt_with boolean DEFAULT false NOT NULL,
    type text NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    updated_by character varying(50) NOT NULL
);


--
-- Name: id_mapper; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.id_mapper (
    id bigint NOT NULL,
    from_id bigint NOT NULL,
    namespace_id bigint NOT NULL,
    system character varying(20) NOT NULL,
    to_id bigint
);


--
-- Name: instance_note; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.instance_note (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    created_at timestamp with time zone NOT NULL,
    created_by character varying(50) NOT NULL,
    instance_id bigint NOT NULL,
    instance_note_key_id bigint NOT NULL,
    namespace_id bigint NOT NULL,
    source_id bigint,
    source_id_string character varying(100),
    source_system character varying(50),
    updated_at timestamp with time zone NOT NULL,
    updated_by character varying(50) NOT NULL,
    value character varying(4000) NOT NULL
);


--
-- Name: instance_note_key; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.instance_note_key (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    deprecated boolean DEFAULT false NOT NULL,
    name character varying(255) NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL,
    description_html text,
    rdf_id character varying(50)
);


--
-- Name: instance_resources; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.instance_resources (
    instance_id bigint NOT NULL,
    resource_id bigint NOT NULL
);


--
-- Name: resource; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.resource (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    created_at timestamp with time zone NOT NULL,
    created_by character varying(50) NOT NULL,
    path character varying(2400) NOT NULL,
    site_id bigint NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    updated_by character varying(50) NOT NULL,
    resource_type_id bigint NOT NULL
);


--
-- Name: site; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.site (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    created_at timestamp with time zone NOT NULL,
    created_by character varying(50) NOT NULL,
    description character varying(1000) NOT NULL,
    name character varying(100) NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    updated_by character varying(50) NOT NULL,
    url character varying(500) NOT NULL
);


--
-- Name: instance_resource_vw; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.instance_resource_vw AS
 SELECT site.name AS site_name,
    site.description AS site_description,
    site.url AS site_url,
    resource.path AS resource_path,
    ((site.url)::text || (resource.path)::text) AS url,
    instance_resources.instance_id
   FROM (((public.site
     JOIN public.resource ON ((site.id = resource.site_id)))
     JOIN public.instance_resources ON ((resource.id = instance_resources.resource_id)))
     JOIN public.instance ON ((instance_resources.instance_id = instance.id)));


--
-- Name: language; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.language (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    iso6391code character varying(2),
    iso6393code character varying(3) NOT NULL,
    name character varying(50) NOT NULL
);


--
-- Name: media; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.media (
    id bigint DEFAULT nextval('public.hibernate_sequence'::regclass) NOT NULL,
    version bigint NOT NULL,
    data bytea NOT NULL,
    description text NOT NULL,
    file_name text NOT NULL,
    mime_type text NOT NULL
);


--
-- Name: name_category; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.name_category (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    name character varying(50) NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL,
    description_html text,
    rdf_id character varying(50),
    max_parents_allowed integer DEFAULT 0 NOT NULL,
    min_parents_required integer DEFAULT 0 NOT NULL,
    parent_1_help_text text,
    parent_2_help_text text,
    requires_family boolean DEFAULT false NOT NULL,
    requires_higher_ranked_parent boolean DEFAULT false NOT NULL,
    requires_name_element boolean DEFAULT false NOT NULL,
    takes_author_only boolean DEFAULT false NOT NULL,
    takes_authors boolean DEFAULT false NOT NULL,
    takes_cultivar_scoped_parent boolean DEFAULT false NOT NULL,
    takes_hybrid_scoped_parent boolean DEFAULT false NOT NULL,
    takes_name_element boolean DEFAULT false NOT NULL,
    takes_verbatim_rank boolean DEFAULT false NOT NULL,
    takes_rank boolean DEFAULT false NOT NULL
);


--
-- Name: name_status; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.name_status (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    display boolean DEFAULT true NOT NULL,
    name character varying(50),
    name_group_id bigint NOT NULL,
    name_status_id bigint,
    nom_illeg boolean DEFAULT false NOT NULL,
    nom_inval boolean DEFAULT false NOT NULL,
    description_html text,
    rdf_id character varying(50),
    deprecated boolean DEFAULT false NOT NULL
);


--
-- Name: name_detail_commons_vw; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.name_detail_commons_vw AS
 SELECT instance.cited_by_id,
    ((((ity.name)::text || ':'::text) || (name.full_name_html)::text) || (
        CASE
            WHEN (ns.nom_illeg OR ns.nom_inval) THEN ns.name
            ELSE ''::character varying
        END)::text) AS entry,
    instance.id,
    instance.cites_id,
    ity.name AS instance_type_name,
    ity.sort_order AS instance_type_sort_order,
    name.full_name,
    name.full_name_html,
    ns.name,
    instance.name_id,
    instance.id AS instance_id,
    instance.cited_by_id AS name_detail_id
   FROM (((public.instance
     JOIN public.name ON ((instance.name_id = name.id)))
     JOIN public.instance_type ity ON ((ity.id = instance.instance_type_id)))
     JOIN public.name_status ns ON ((ns.id = name.name_status_id)))
  WHERE ((ity.name)::text = ANY (ARRAY[('common name'::character varying)::text, ('vernacular name'::character varying)::text]));


--
-- Name: name_detail_synonyms_vw; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.name_detail_synonyms_vw AS
 SELECT instance.cited_by_id,
    ((((ity.name)::text || ':'::text) || (name.full_name_html)::text) || (
        CASE
            WHEN (ns.nom_illeg OR ns.nom_inval) THEN ns.name
            ELSE ''::character varying
        END)::text) AS entry,
    instance.id,
    instance.cites_id,
    ity.name AS instance_type_name,
    ity.sort_order AS instance_type_sort_order,
    name.full_name,
    name.full_name_html,
    ns.name,
    instance.name_id,
    instance.id AS instance_id,
    instance.cited_by_id AS name_detail_id,
    instance.reference_id
   FROM (((public.instance
     JOIN public.name ON ((instance.name_id = name.id)))
     JOIN public.instance_type ity ON ((ity.id = instance.instance_type_id)))
     JOIN public.name_status ns ON ((ns.id = name.name_status_id)))
  WHERE ((ity.name)::text <> ALL (ARRAY[('common name'::character varying)::text, ('vernacular name'::character varying)::text]));


--
-- Name: name_rank; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.name_rank (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    abbrev character varying(20) NOT NULL,
    deprecated boolean DEFAULT false NOT NULL,
    has_parent boolean DEFAULT false NOT NULL,
    italicize boolean DEFAULT false NOT NULL,
    major boolean DEFAULT false NOT NULL,
    name character varying(50) NOT NULL,
    name_group_id bigint NOT NULL,
    parent_rank_id bigint,
    sort_order integer DEFAULT 0 NOT NULL,
    visible_in_name boolean DEFAULT true NOT NULL,
    description_html text,
    rdf_id character varying(50),
    use_verbatim_rank boolean DEFAULT false NOT NULL,
    display_name text NOT NULL
);


--
-- Name: name_type; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.name_type (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    autonym boolean DEFAULT false NOT NULL,
    connector character varying(1),
    cultivar boolean DEFAULT false NOT NULL,
    formula boolean DEFAULT false NOT NULL,
    hybrid boolean DEFAULT false NOT NULL,
    name character varying(255) NOT NULL,
    name_category_id bigint NOT NULL,
    name_group_id bigint NOT NULL,
    scientific boolean DEFAULT false NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL,
    description_html text,
    rdf_id character varying(50),
    deprecated boolean DEFAULT false NOT NULL
);


--
-- Name: name_details_vw; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.name_details_vw AS
 SELECT n.id,
    n.full_name,
    n.simple_name,
    s.name AS status_name,
    r.name AS rank_name,
    r.visible_in_name AS rank_visible_in_name,
    r.sort_order AS rank_sort_order,
    t.name AS type_name,
    t.scientific AS type_scientific,
    t.cultivar AS type_cultivar,
    i.id AS instance_id,
    ref.year AS reference_year,
    ref.id AS reference_id,
    ref.citation_html AS reference_citation_html,
    ity.name AS instance_type_name,
    ity.id AS instance_type_id,
    ity.primary_instance,
    ity.standalone AS instance_standalone,
    sty.standalone AS synonym_standalone,
    sty.name AS synonym_type_name,
    i.page,
    i.page_qualifier,
    i.cited_by_id,
    i.cites_id,
    i.bhl_url,
        CASE ity.primary_instance
            WHEN true THEN 'A'::text
            ELSE 'B'::text
        END AS primary_instance_first,
    sname.full_name AS synonym_full_name,
    author.name AS author_name,
    n.id AS name_id,
    n.sort_name,
    ((((ref.citation_html)::text || ': '::text) || (COALESCE(i.page, ''::character varying))::text) ||
        CASE ity.primary_instance
            WHEN true THEN ((' ['::text || (ity.name)::text) || ']'::text)
            ELSE ''::text
        END) AS entry
   FROM ((((((((((public.name n
     JOIN public.name_status s ON ((n.name_status_id = s.id)))
     JOIN public.name_rank r ON ((n.name_rank_id = r.id)))
     JOIN public.name_type t ON ((n.name_type_id = t.id)))
     JOIN public.instance i ON ((n.id = i.name_id)))
     JOIN public.instance_type ity ON ((i.instance_type_id = ity.id)))
     JOIN public.reference ref ON ((i.reference_id = ref.id)))
     LEFT JOIN public.author ON ((ref.author_id = author.id)))
     LEFT JOIN public.instance syn ON ((syn.cited_by_id = i.id)))
     LEFT JOIN public.instance_type sty ON ((syn.instance_type_id = sty.id)))
     LEFT JOIN public.name sname ON ((syn.name_id = sname.id)))
  WHERE (n.duplicate_of_id IS NULL);


--
-- Name: name_group; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.name_group (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    name character varying(50),
    description_html text,
    rdf_id character varying(50)
);


--
-- Name: name_tag; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.name_tag (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    name character varying(255) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL
);


--
-- Name: name_tag_name; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.name_tag_name (
    name_id bigint NOT NULL,
    tag_id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    created_by character varying(255) NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    updated_by character varying(255) NOT NULL
);


--
-- Name: name_view; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW public.name_view AS
SELECT n.full_name                                                                  AS "scientificName",
       n.full_name_html                                                             AS "scientificNameHTML",
       n.simple_name                                                                AS "canonicalName",
       n.simple_name_html                                                           AS "canonicalNameHTML",
       n.name_element                                                               AS "nameElement",
       ((mapper_host.value)::text || n.uri)                                         AS "scientificNameID",
       nt.name                                                                      AS "nameType",
       public.accepted_status(n.id)                                                 AS "taxonomicStatus",
       CASE
            WHEN ((ns.name)::text <> ALL (ARRAY[('legitimate'::character varying)::text, ('[default]'::character varying)::text])) THEN ns.name
            ELSE NULL::character varying
           END                                                                      AS "nomenclaturalStatus",
       CASE
            WHEN nt.autonym THEN NULL::text
            ELSE regexp_replace("substring"((n.full_name_html)::text, '<authors>(.*)</authors>'::text), '<[^>]*>'::text, ''::text, 'g'::text)
           END                                                                      AS "scientificNameAuthorship",
       CASE
            WHEN (nt.cultivar = true) THEN n.name_element
            ELSE NULL::character varying
           END                                                                      AS "cultivarEpithet",
       nt.autonym,
       nt.hybrid,
       nt.cultivar,
       nt.formula,
       nt.scientific,
       ns.nom_inval                                                                 AS "nomInval",
       ns.nom_illeg                                                                 AS "nomIlleg",
       COALESCE(primary_ref.citation, (SELECT r.citation
                                       FROM ((public.instance s
             JOIN public.instance_type it ON (((s.instance_type_id = it.id) AND it.secondary_instance)))
             JOIN public.reference r ON ((s.reference_id = r.id)))
                                       ORDER BY r.year
                                       LIMIT 1))                                    AS "namePublishedIn",
       COALESCE(primary_ref.year, (SELECT r.year
                                   FROM ((public.instance s
             JOIN public.instance_type it ON (((s.instance_type_id = it.id) AND it.secondary_instance)))
             JOIN public.reference r ON ((s.reference_id = r.id)))
                                   ORDER BY r.year
                                   LIMIT 1))                                        AS "namePublishedInYear",
       primary_it.name                                                              AS "nameInstanceType",
       basionym.full_name                                                           AS "originalNameUsage",
       CASE
           WHEN (basionym_inst.id IS NOT NULL) THEN ((mapper_host.value)::text || (SELECT instance.uri
                                                                                   FROM public.instance
                                                                                   WHERE (instance.id = basionym_inst.cites_id)))
           ELSE
            CASE
                WHEN (primary_inst.id IS NOT NULL) THEN ((mapper_host.value)::text || primary_inst.uri)
                ELSE NULL::text
            END
           END                                                                      AS "originalNameUsageID",
       CASE
            WHEN (nt.autonym = true) THEN (parent_name.full_name)::text
            ELSE ( SELECT string_agg(regexp_replace((note.value)::text, '[

 ]+'::text, ' '::text, 'g'::text), ' '::text) AS string_agg
               FROM (public.instance_note note
                 JOIN public.instance_note_key key1 ON (((key1.id = note.instance_note_key_id) AND ((key1.name)::text = 'Type'::text))))
              WHERE (note.instance_id = COALESCE(basionym_inst.cites_id, primary_inst.id)))
           END                                                                      AS "typeCitation",
       (SELECT find_rank.name_element
        FROM public.find_rank(n.id, 10) find_rank(name_element, rank, sort_order))  AS kingdom,
       family_name.name_element                                                     AS family,
       (SELECT find_rank.name_element
        FROM public.find_rank(n.id, 120) find_rank(name_element, rank, sort_order)) AS "genericName",
       (SELECT find_rank.name_element
        FROM public.find_rank(n.id, 190) find_rank(name_element, rank, sort_order)) AS "specificEpithet",
       (SELECT find_rank.name_element
        FROM public.find_rank(n.id, 191) find_rank(name_element, rank, sort_order)) AS "infraspecificEpithet",
       rank.name                                                                    AS "taxonRank",
       rank.sort_order                                                              AS "taxonRankSortOrder",
       rank.abbrev                                                                  AS "taxonRankAbbreviation",
       first_hybrid_parent.full_name                                                AS "firstHybridParentName",
       ((mapper_host.value)::text || first_hybrid_parent.uri)                       AS "firstHybridParentNameID",
       second_hybrid_parent.full_name                                               AS "secondHybridParentName",
       ((mapper_host.value)::text || second_hybrid_parent.uri)                      AS "secondHybridParentNameID",
       n.created_at                                                                 AS created,
       n.updated_at                                                                 AS modified,
       ((SELECT COALESCE((SELECT shard_config.value
                          FROM public.shard_config
                          WHERE ((shard_config.name)::text = 'nomenclatural code'::text)),
                         'ICN'::character varying) AS "coalesce"))::text            AS "nomenclaturalCode",
       dataset.value                                                                AS "datasetName",
       'http://creativecommons.org/licenses/by/3.0/'::text                          AS license,
       ((mapper_host.value)::text || n.uri)                                         AS "ccAttributionIRI"
FROM (((((((((((public.name n
     JOIN public.name_type nt ON ((n.name_type_id = nt.id)))
     JOIN public.name_status ns ON ((n.name_status_id = ns.id)))
     JOIN public.name_rank rank ON ((n.name_rank_id = rank.id)))
     LEFT JOIN public.name parent_name ON ((n.parent_id = parent_name.id)))
     LEFT JOIN public.name family_name ON ((n.family_id = family_name.id)))
     LEFT JOIN public.name first_hybrid_parent ON (((n.parent_id = first_hybrid_parent.id) AND nt.hybrid)))
     LEFT JOIN public.name second_hybrid_parent ON (((n.second_parent_id = second_hybrid_parent.id) AND nt.hybrid)))
     LEFT JOIN ((public.instance primary_inst
     JOIN public.instance_type primary_it ON (((primary_it.id = primary_inst.instance_type_id) AND (primary_it.primary_instance = true))))
     JOIN public.reference primary_ref ON ((primary_inst.reference_id = primary_ref.id))) ON ((primary_inst.name_id = n.id)))
     LEFT JOIN ((public.instance basionym_inst
     JOIN public.instance_type "bit" ON ((("bit".id = basionym_inst.instance_type_id) AND (("bit".name)::text = 'basionym'::text))))
        JOIN public.name basionym ON ((basionym.id = basionym_inst.name_id))) ON ((basionym_inst.cited_by_id = primary_inst.id)))
     LEFT JOIN public.shard_config mapper_host ON (((mapper_host.name)::text = 'mapper host'::text)))
         LEFT JOIN public.shard_config dataset ON (((dataset.name)::text = 'name label'::text)))
WHERE (EXISTS ( SELECT 1
           FROM public.instance
          WHERE (instance.name_id = n.id)))
ORDER BY n.sort_name
  WITH NO DATA;


--
-- Name: namespace; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.namespace (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    name character varying(255) NOT NULL,
    description_html text,
    rdf_id character varying(50)
);


--
-- Name: notification; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notification (
    id bigint NOT NULL,
    version bigint NOT NULL,
    message character varying(255) NOT NULL,
    object_id bigint
);


--
-- Name: nsl3164; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.nsl3164
(
    id            integer               NOT NULL,
    accepted_name character varying(120),
    orthvar1      character varying(120),
    orthvar2      character varying(120),
    orthvar3      character varying(120),
    orthvar4      character varying(120),
    done          boolean DEFAULT false NOT NULL
);


--
-- Name: nsl3164_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.nsl3164_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: nsl3164_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.nsl3164_id_seq OWNED BY public.nsl3164.id;


--
-- Name: nsl_simple_name_export; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.nsl_simple_name_export (
    id text,
    apc_comment character varying(4000),
    apc_distribution character varying(4000),
    apc_excluded boolean,
    apc_familia character varying(255),
    apc_instance_id text,
    apc_name character varying(512),
    apc_proparte boolean,
    apc_relationship_type character varying(255),
    apni boolean,
    author character varying(255),
    authority character varying(255),
    autonym boolean,
    basionym character varying(512),
    base_name_author character varying(255),
    classifications character varying(255),
    created_at timestamp without time zone,
    created_by character varying(255),
    cultivar boolean,
    cultivar_name character varying(255),
    ex_author character varying(255),
    ex_base_name_author character varying(255),
    familia character varying(255),
    family_nsl_id text,
    formula boolean,
    full_name_html character varying(2048),
    genus character varying(255),
    genus_nsl_id text,
    homonym boolean,
    hybrid boolean,
    infraspecies character varying(255),
    name character varying(255),
    classis character varying(255),
    name_element character varying(255),
    subclassis character varying(255),
    name_type_name character varying(255),
    nom_illeg boolean,
    nom_inval boolean,
    nom_stat character varying(255),
    parent_nsl_id text,
    proto_citation character varying(512),
    proto_instance_id text,
    proto_year smallint,
    rank character varying(255),
    rank_abbrev character varying(255),
    rank_sort_order integer,
    replaced_synonym character varying(512),
    sanctioning_author character varying(255),
    scientific boolean,
    second_parent_nsl_id text,
    simple_name_html character varying(2048),
    species character varying(255),
    species_nsl_id text,
    taxon_name character varying(512),
    updated_at timestamp without time zone,
    updated_by character varying(255)
);


--
-- Name: orchidaceae; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.orchidaceae (
    id integer,
    record_type text,
    parent_id integer,
    hybrid_id text,
    family text,
    hr_comment text,
    subfamily text,
    tribe text,
    subtribe text,
    rank text,
    nsl_rank text,
    taxon text,
    base_author text,
    ex_base_author text,
    comb_author text,
    ex_comb_author text,
    author_rank text,
    name_status text,
    name_comment text,
    partly text,
    auct_non text,
    synonym_type text,
    doubtful text,
    questionable text,
    hybrid_level text,
    publication text,
    note_and_publication text,
    warning text,
    footnote text,
    distribution text,
    comment text,
    original_text text
);


--
-- Name: ref_author_role; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ref_author_role (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    name character varying(255) NOT NULL,
    description_html text,
    rdf_id character varying(50)
);


--
-- Name: ref_type; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ref_type (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    name character varying(50) NOT NULL,
    parent_id bigint,
    parent_optional boolean DEFAULT false NOT NULL,
    description_html text,
    rdf_id character varying(50),
    use_parent_details boolean DEFAULT false NOT NULL
);


--
-- Name: resource_type; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.resource_type (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    css_icon text,
    deprecated boolean DEFAULT false NOT NULL,
    description text NOT NULL,
    display boolean DEFAULT true NOT NULL,
    media_icon_id bigint,
    name text NOT NULL,
    rdf_id character varying(50)
);


--
-- Name: taxon_view; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW public.taxon_view AS
    SELECT ((syn.value ->> 'host'::text) || (syn.value ->> 'concept_link'::text))         AS "taxonID",
           acc_nt.name                                                                    AS "nameType",
           (tree.host_name || tve.element_link)                                           AS "acceptedNameUsageID",
           acc_name.full_name                                                             AS "acceptedNameUsage",
           CASE
               WHEN ((acc_ns.name)::text <> ALL
                     ((ARRAY ['legitimate'::character varying, '[default]'::character varying])::text[]))
                   THEN acc_ns.name
               ELSE NULL::character varying
               END                                                                        AS "nomenclaturalStatus",
           (syn.value ->> 'type'::text)                                                   AS "taxonomicStatus",
           ((syn.value ->> 'type'::text) ~ 'parte'::text)                                 AS "proParte",
           syn_name.full_name                                                             AS "scientificName",
           ((syn.value ->> 'host'::text) || (syn.value ->> 'name_link'::text))            AS "scientificNameID",
           syn_name.simple_name                                                           AS "canonicalName",
           CASE
            WHEN syn_nt.autonym THEN NULL::text
            ELSE regexp_replace("substring"((syn_name.full_name_html)::text, '<authors>(.*)</authors>'::text), '<[^>]*>'::text, ''::text, 'g'::text)
               END                                                                        AS "scientificNameAuthorship",
           NULL::text                                                                     AS "parentNameUsageID",
           syn_rank.name                                                                  AS "taxonRank",
           syn_rank.sort_order                                                            AS "taxonRankSortOrder",
           (SELECT find_tree_rank.name_element
            FROM public.find_tree_rank(tve.element_link, 10) find_tree_rank(name_element, rank, sort_order)
            ORDER BY find_tree_rank.sort_order
            LIMIT 1)                                                                      AS kingdom,
    (SELECT find_tree_rank.name_element
     FROM public.find_tree_rank(tve.element_link, 30) find_tree_rank(name_element, rank, sort_order)
     ORDER BY find_tree_rank.sort_order
     LIMIT 1)                                                                             AS class,
    (SELECT find_tree_rank.name_element
     FROM public.find_tree_rank(tve.element_link, 40) find_tree_rank(name_element, rank, sort_order)
     ORDER BY find_tree_rank.sort_order
     LIMIT 1)                                                                             AS subclass,
    (SELECT find_tree_rank.name_element
     FROM public.find_tree_rank(tve.element_link, 80) find_tree_rank(name_element, rank, sort_order)
     ORDER BY find_tree_rank.sort_order
     LIMIT 1)                                                                             AS family,
           syn_name.created_at                                                            AS created,
           syn_name.updated_at                                                            AS modified,
           tree.name                                                                      AS "datasetName",
           ((syn.value ->> 'host'::text) || (syn.value ->> 'concept_link'::text))         AS "taxonConceptID",
           (syn.value ->> 'cites'::text)                                                  AS "nameAccordingTo",
           ((syn.value ->> 'host'::text) || (syn.value ->> 'cites_link'::text))           AS "nameAccordingToID",
           ((te.profile -> (tree.config ->> 'comment_key'::text)) ->> 'value'::text)      AS "taxonRemarks",
           ((te.profile -> (tree.config ->> 'distribution_key'::text)) ->> 'value'::text) AS "taxonDistribution",
           regexp_replace(tve.name_path, '/'::text, '|'::text, 'g'::text)                 AS "higherClassification",
           CASE
            WHEN (firsthybridparent.id IS NOT NULL) THEN firsthybridparent.full_name
            ELSE NULL::character varying
               END                                                                        AS "firstHybridParentName",
           CASE
               WHEN (firsthybridparent.id IS NOT NULL) THEN ((tree.host_name || '/'::text) || firsthybridparent.uri)
               ELSE NULL::text
               END                                                                        AS "firstHybridParentNameID",
           CASE
            WHEN (secondhybridparent.id IS NOT NULL) THEN secondhybridparent.full_name
            ELSE NULL::character varying
               END                                                                        AS "secondHybridParentName",
           CASE
               WHEN (secondhybridparent.id IS NOT NULL) THEN ((tree.host_name || '/'::text) || secondhybridparent.uri)
               ELSE NULL::text
               END                                                                        AS "secondHybridParentNameID",
           ((SELECT COALESCE((SELECT shard_config.value
                              FROM public.shard_config
                              WHERE ((shard_config.name)::text = 'nomenclatural code'::text)),
                             'ICN'::character varying) AS "coalesce"))::text              AS "nomenclaturalCode",
           'http://creativecommons.org/licenses/by/3.0/'::text                            AS license,
           ((syn.value ->> 'host'::text) || (syn.value ->> 'instance_link'::text))        AS "ccAttributionIRI"
    FROM ((((((((public.tree_version_element tve
     JOIN public.tree ON (((tve.tree_version_id = tree.current_tree_version_id) AND (tree.accepted_tree = true))))
     JOIN public.tree_element te ON ((tve.tree_element_id = te.id)))
     JOIN public.instance acc_inst ON ((te.instance_id = acc_inst.id)))
     JOIN public.instance_type acc_it ON ((acc_inst.instance_type_id = acc_it.id)))
     JOIN public.reference acc_ref ON ((acc_inst.reference_id = acc_ref.id)))
     JOIN public.name acc_name ON ((te.name_id = acc_name.id)))
     JOIN public.name_type acc_nt ON ((acc_name.name_type_id = acc_nt.id)))
     JOIN public.name_status acc_ns ON ((acc_name.name_status_id = acc_ns.id))),
    (((((LATERAL jsonb_array_elements((te.synonyms -> 'list'::text)) syn(value)
     JOIN public.name syn_name ON ((syn_name.id = (((syn.value ->> 'name_id'::text))::numeric)::bigint)))
     JOIN public.name_rank syn_rank ON ((syn_name.name_rank_id = syn_rank.id)))
     JOIN public.name_type syn_nt ON ((syn_name.name_type_id = syn_nt.id)))
     LEFT JOIN public.name firsthybridparent ON (((syn_name.parent_id = firsthybridparent.id) AND syn_nt.hybrid)))
        LEFT JOIN public.name secondhybridparent
                  ON (((syn_name.second_parent_id = secondhybridparent.id) AND syn_nt.hybrid)))
    UNION
    SELECT (tree.host_name || tve.element_link)                                           AS "taxonID",
           acc_nt.name                                                                    AS "nameType",
           (tree.host_name || tve.element_link)                                           AS "acceptedNameUsageID",
           acc_name.full_name                                                             AS "acceptedNameUsage",
           CASE
               WHEN ((acc_ns.name)::text <> ALL
                     ((ARRAY ['legitimate'::character varying, '[default]'::character varying])::text[]))
                   THEN acc_ns.name
               ELSE NULL::character varying
               END                                                                        AS "nomenclaturalStatus",
           CASE
            WHEN te.excluded THEN 'excluded'::text
            ELSE 'accepted'::text
               END                                                                        AS "taxonomicStatus",
           false                                                                          AS "proParte",
           acc_name.full_name                                                             AS "scientificName",
           te.name_link                                                                   AS "scientificNameID",
           acc_name.simple_name                                                           AS "canonicalName",
           CASE
            WHEN acc_nt.autonym THEN NULL::text
            ELSE regexp_replace("substring"((acc_name.full_name_html)::text, '<authors>(.*)</authors>'::text), '<[^>]*>'::text, ''::text, 'g'::text)
               END                                                                        AS "scientificNameAuthorship",
           (tree.host_name || tve.parent_id)                                              AS "parentNameUsageID",
           te.rank                                                                        AS "taxonRank",
           acc_rank.sort_order                                                            AS "taxonRankSortOrder",
           (SELECT find_tree_rank.name_element
            FROM public.find_tree_rank(tve.element_link, 10) find_tree_rank(name_element, rank, sort_order)
            ORDER BY find_tree_rank.sort_order
            LIMIT 1)                                                                      AS kingdom,
    (SELECT find_tree_rank.name_element
     FROM public.find_tree_rank(tve.element_link, 30) find_tree_rank(name_element, rank, sort_order)
     ORDER BY find_tree_rank.sort_order
     LIMIT 1)                                                                             AS class,
    (SELECT find_tree_rank.name_element
     FROM public.find_tree_rank(tve.element_link, 40) find_tree_rank(name_element, rank, sort_order)
     ORDER BY find_tree_rank.sort_order
     LIMIT 1)                                                                             AS subclass,
    (SELECT find_tree_rank.name_element
     FROM public.find_tree_rank(tve.element_link, 80) find_tree_rank(name_element, rank, sort_order)
     ORDER BY find_tree_rank.sort_order
     LIMIT 1)                                                                             AS family,
           acc_name.created_at                                                            AS created,
           acc_name.updated_at                                                            AS modified,
           tree.name                                                                      AS "datasetName",
           te.instance_link                                                               AS "taxonConceptID",
           acc_ref.citation                                                               AS "nameAccordingTo",
           ((((tree.host_name || '/reference/'::text) || lower((name_space.value)::text)) || '/'::text) ||
            acc_ref.id)                                                                   AS "nameAccordingToID",
           ((te.profile -> (tree.config ->> 'comment_key'::text)) ->> 'value'::text)      AS "taxonRemarks",
           ((te.profile -> (tree.config ->> 'distribution_key'::text)) ->> 'value'::text) AS "taxonDistribution",
           regexp_replace(tve.name_path, '/'::text, '|'::text, 'g'::text)                 AS "higherClassification",
           CASE
            WHEN (firsthybridparent.id IS NOT NULL) THEN firsthybridparent.full_name
            ELSE NULL::character varying
               END                                                                        AS "firstHybridParentName",
           CASE
               WHEN (firsthybridparent.id IS NOT NULL) THEN ((tree.host_name || '/'::text) || firsthybridparent.uri)
               ELSE NULL::text
               END                                                                        AS "firstHybridParentNameID",
           CASE
            WHEN (secondhybridparent.id IS NOT NULL) THEN secondhybridparent.full_name
            ELSE NULL::character varying
               END                                                                        AS "secondHybridParentName",
           CASE
               WHEN (secondhybridparent.id IS NOT NULL) THEN ((tree.host_name || '/'::text) || secondhybridparent.uri)
               ELSE NULL::text
               END                                                                        AS "secondHybridParentNameID",
           ((SELECT COALESCE((SELECT shard_config.value
                              FROM public.shard_config
                              WHERE ((shard_config.name)::text = 'nomenclatural code'::text)),
                             'ICN'::character varying) AS "coalesce"))::text              AS "nomenclaturalCode",
           'http://creativecommons.org/licenses/by/3.0/'::text                            AS license,
           (tree.host_name || tve.element_link)                                           AS "ccAttributionIRI"
    FROM ((((((((((((public.tree_version_element tve
     JOIN public.tree ON (((tve.tree_version_id = tree.current_tree_version_id) AND (tree.accepted_tree = true))))
     JOIN public.tree_element te ON ((tve.tree_element_id = te.id)))
     JOIN public.instance acc_inst ON ((te.instance_id = acc_inst.id)))
     JOIN public.instance_type acc_it ON ((acc_inst.instance_type_id = acc_it.id)))
     JOIN public.reference acc_ref ON ((acc_inst.reference_id = acc_ref.id)))
     JOIN public.name acc_name ON ((te.name_id = acc_name.id)))
     JOIN public.name_type acc_nt ON ((acc_name.name_type_id = acc_nt.id)))
     JOIN public.name_status acc_ns ON ((acc_name.name_status_id = acc_ns.id)))
     JOIN public.name_rank acc_rank ON ((acc_name.name_rank_id = acc_rank.id)))
     LEFT JOIN public.name firsthybridparent ON (((acc_name.parent_id = firsthybridparent.id) AND acc_nt.hybrid)))
        LEFT JOIN public.name secondhybridparent ON (((acc_name.second_parent_id = secondhybridparent.id) AND acc_nt.hybrid)))
             LEFT JOIN public.shard_config name_space ON (((name_space.name)::text = 'name space'::text)))
    ORDER BY 27
  WITH NO DATA;


--
-- Name: MATERIALIZED VIEW taxon_view; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON MATERIALIZED VIEW public.taxon_view IS 'The Taxon View provides a complete list of Names and their synonyms accepted by CHAH in Australia.';


--
-- Name: COLUMN taxon_view."taxonID"; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_view."taxonID" IS 'The identifying URI of the taxon concept used here. For an accepted name it identifies the taxon concept and what it encloses (subtaxa). For a synonym it identifies the relationship.';


--
-- Name: COLUMN taxon_view."nameType"; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_view."nameType" IS 'A categorisation of the name, e.g. scientific, hybrid, cultivar';


--
-- Name: COLUMN taxon_view."acceptedNameUsageID"; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_view."acceptedNameUsageID" IS 'The identifying URI of the accepted name concept.';


--
-- Name: COLUMN taxon_view."acceptedNameUsage"; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_view."acceptedNameUsage" IS 'The accepted name for this concept in this classification.';


--
-- Name: COLUMN taxon_view."nomenclaturalStatus"; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_view."nomenclaturalStatus" IS 'The nomencultural status of this name. http://rs.gbif.org/vocabulary/gbif/nomenclatural_status.xml';


--
-- Name: COLUMN taxon_view."taxonomicStatus"; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_view."taxonomicStatus" IS 'Is this name accepted, excluded or a synonym of an accepted name.';


--
-- Name: COLUMN taxon_view."proParte"; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_view."proParte" IS 'A flag that indicates this name is applied to this accepted name in part. If a name is ''pro parte'' then the name will have more than 1 accepted name.';


--
-- Name: COLUMN taxon_view."scientificName"; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_view."scientificName" IS 'The full scientific name including authority.';


--
-- Name: COLUMN taxon_view."scientificNameID"; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_view."scientificNameID" IS 'The identifying URI of the scientific name in this dataset.';


--
-- Name: COLUMN taxon_view."canonicalName"; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_view."canonicalName" IS 'The name without authorship.';


--
-- Name: COLUMN taxon_view."scientificNameAuthorship"; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_view."scientificNameAuthorship" IS 'Authorship of the name.';


--
-- Name: COLUMN taxon_view."parentNameUsageID"; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_view."parentNameUsageID" IS 'The identifying URI of the parent taxon for accepted names in the classification.';


--
-- Name: COLUMN taxon_view."taxonRank"; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_view."taxonRank" IS 'The taxonomic rank of the scientificName.';


--
-- Name: COLUMN taxon_view."taxonRankSortOrder"; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_view."taxonRankSortOrder" IS 'A sort order that can be applied to the rank.';


--
-- Name: COLUMN taxon_view.kingdom; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_view.kingdom IS 'The canonical name of the kingdom based on this classification.';


--
-- Name: COLUMN taxon_view.class; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_view.class IS 'The canonical name of the class based on this classification.';


--
-- Name: COLUMN taxon_view.subclass; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_view.subclass IS 'The canonical name of the subclass based on this classification.';


--
-- Name: COLUMN taxon_view.family; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_view.family IS 'The canonical name of the family based on this classification.';


--
-- Name: COLUMN taxon_view.created; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_view.created IS 'Date the record for this concept was created. Format ISO:86 01';


--
-- Name: COLUMN taxon_view.modified; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_view.modified IS 'Date the record for this concept was modified. Format ISO:86 01';


--
-- Name: COLUMN taxon_view."datasetName"; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_view."datasetName" IS 'Name of the taxonomy (tree) that contains this concept. e.g. APC, AusMoss';


--
-- Name: COLUMN taxon_view."taxonConceptID"; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_view."taxonConceptID" IS 'The identifying URI taxanomic concept this record refers to.';


--
-- Name: COLUMN taxon_view."nameAccordingTo"; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_view."nameAccordingTo" IS 'The reference citation for this name.';


--
-- Name: COLUMN taxon_view."nameAccordingToID"; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_view."nameAccordingToID" IS 'The identifying URI for the reference citation for this name.';


--
-- Name: COLUMN taxon_view."taxonRemarks"; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_view."taxonRemarks" IS 'Comments made specifically about this name in this classification.';


--
-- Name: COLUMN taxon_view."taxonDistribution"; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_view."taxonDistribution" IS 'The State or Territory distribution of the accepted name.';


--
-- Name: COLUMN taxon_view."higherClassification"; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_view."higherClassification" IS 'A list of names representing the branch down to (and including) this name separated by a "|".';


--
-- Name: COLUMN taxon_view."firstHybridParentName"; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_view."firstHybridParentName" IS 'The scientificName for the first hybrid parent. For hybrids.';


--
-- Name: COLUMN taxon_view."firstHybridParentNameID"; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_view."firstHybridParentNameID" IS 'The identifying URI the scientificName for the first hybrid parent.';


--
-- Name: COLUMN taxon_view."secondHybridParentName"; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_view."secondHybridParentName" IS 'The scientificName for the second hybrid parent. For hybrids.';


--
-- Name: COLUMN taxon_view."secondHybridParentNameID"; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_view."secondHybridParentNameID" IS 'The identifying URI the scientificName for the second hybrid parent.';


--
-- Name: COLUMN taxon_view."nomenclaturalCode"; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_view."nomenclaturalCode" IS 'The nomenclatural code under which this name is constructed.';


--
-- Name: COLUMN taxon_view.license; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_view.license IS 'The license by which this data is being made available.';


--
-- Name: COLUMN taxon_view."ccAttributionIRI"; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_view."ccAttributionIRI" IS 'The attribution to be used when citing this concept.';


--
-- Name: tmp_distribution; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tmp_distribution
(
    dist      text,
    apc_te_id bigint,
    wa        text,
    coi       text,
    chi       text,
    ar        text,
    cai       text,
    nt        text,
    sa        text,
    qld       text,
    csi       text,
    nsw       text,
    lhi       text,
    ni        text,
    act       text,
    vic       text,
    tas       text,
    hi        text,
    mdi       text,
    mi        text
);


--
-- Name: tree_element_distribution_entries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tree_element_distribution_entries
(
    dist_entry_id   bigint NOT NULL,
    tree_element_id bigint NOT NULL
);


--
-- Name: logged_actions event_id; Type: DEFAULT; Schema: audit; Owner: -
--

ALTER TABLE ONLY audit.logged_actions ALTER COLUMN event_id SET DEFAULT nextval('audit.logged_actions_event_id_seq'::regclass);


--
-- Name: nsl3164 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nsl3164
    ALTER COLUMN id SET DEFAULT nextval('public.nsl3164_id_seq'::regclass);


--
-- Name: logged_actions logged_actions_pkey; Type: CONSTRAINT; Schema: audit; Owner: -
--

ALTER TABLE ONLY audit.logged_actions
    ADD CONSTRAINT logged_actions_pkey PRIMARY KEY (event_id);


--
-- Name: db_version db_version_pkey; Type: CONSTRAINT; Schema: mapper; Owner: -
--

ALTER TABLE ONLY mapper.db_version
    ADD CONSTRAINT db_version_pkey PRIMARY KEY (id);


--
-- Name: host host_pkey; Type: CONSTRAINT; Schema: mapper; Owner: -
--

ALTER TABLE ONLY mapper.host
    ADD CONSTRAINT host_pkey PRIMARY KEY (id);


--
-- Name: identifier_identities identifier_identities_pkey; Type: CONSTRAINT; Schema: mapper; Owner: -
--

ALTER TABLE ONLY mapper.identifier_identities
    ADD CONSTRAINT identifier_identities_pkey PRIMARY KEY (identifier_id, match_id);


--
-- Name: identifier identifier_pkey; Type: CONSTRAINT; Schema: mapper; Owner: -
--

ALTER TABLE ONLY mapper.identifier
    ADD CONSTRAINT identifier_pkey PRIMARY KEY (id);


--
-- Name: match match_pkey; Type: CONSTRAINT; Schema: mapper; Owner: -
--

ALTER TABLE ONLY mapper.match
    ADD CONSTRAINT match_pkey PRIMARY KEY (id);


--
-- Name: match uk_2u4bey0rox6ubtvqevg3wasp9; Type: CONSTRAINT; Schema: mapper; Owner: -
--

ALTER TABLE ONLY mapper.match
    ADD CONSTRAINT uk_2u4bey0rox6ubtvqevg3wasp9 UNIQUE (uri);


--
-- Name: identifier unique_name_space; Type: CONSTRAINT; Schema: mapper; Owner: -
--

ALTER TABLE ONLY mapper.identifier
    ADD CONSTRAINT unique_name_space UNIQUE (version_number, id_number, object_type, name_space);


--
-- Name: author author_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.author
    ADD CONSTRAINT author_pkey PRIMARY KEY (id);


--
-- Name: comment comment_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comment
    ADD CONSTRAINT comment_pkey PRIMARY KEY (id);


--
-- Name: db_version db_version_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.db_version
    ADD CONSTRAINT db_version_pkey PRIMARY KEY (id);


--
-- Name: delayed_jobs delayed_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.delayed_jobs
    ADD CONSTRAINT delayed_jobs_pkey PRIMARY KEY (id);


--
-- Name: dist_entry dist_entry_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dist_entry
    ADD CONSTRAINT dist_entry_pkey PRIMARY KEY (id);


--
-- Name: dist_region dist_region_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dist_region
    ADD CONSTRAINT dist_region_pkey PRIMARY KEY (id);


--
-- Name: dist_status dist_status_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dist_status
    ADD CONSTRAINT dist_status_pkey PRIMARY KEY (id);


--
-- Name: event_record event_record_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.event_record
    ADD CONSTRAINT event_record_pkey PRIMARY KEY (id);


--
-- Name: id_mapper id_mapper_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.id_mapper
    ADD CONSTRAINT id_mapper_pkey PRIMARY KEY (id);


--
-- Name: instance_note_key instance_note_key_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance_note_key
    ADD CONSTRAINT instance_note_key_pkey PRIMARY KEY (id);


--
-- Name: instance_note instance_note_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance_note
    ADD CONSTRAINT instance_note_pkey PRIMARY KEY (id);


--
-- Name: instance instance_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance
    ADD CONSTRAINT instance_pkey PRIMARY KEY (id);


--
-- Name: instance_resources instance_resources_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance_resources
    ADD CONSTRAINT instance_resources_pkey PRIMARY KEY (instance_id, resource_id);


--
-- Name: instance_type instance_type_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance_type
    ADD CONSTRAINT instance_type_pkey PRIMARY KEY (id);


--
-- Name: language language_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.language
    ADD CONSTRAINT language_pkey PRIMARY KEY (id);


--
-- Name: media media_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.media
    ADD CONSTRAINT media_pkey PRIMARY KEY (id);


--
-- Name: name_category name_category_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name_category
    ADD CONSTRAINT name_category_pkey PRIMARY KEY (id);


--
-- Name: name_group name_group_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name_group
    ADD CONSTRAINT name_group_pkey PRIMARY KEY (id);


--
-- Name: name name_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name
    ADD CONSTRAINT name_pkey PRIMARY KEY (id);


--
-- Name: name_rank name_rank_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name_rank
    ADD CONSTRAINT name_rank_pkey PRIMARY KEY (id);


--
-- Name: name_status name_status_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name_status
    ADD CONSTRAINT name_status_pkey PRIMARY KEY (id);


--
-- Name: name_tag_name name_tag_name_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name_tag_name
    ADD CONSTRAINT name_tag_name_pkey PRIMARY KEY (name_id, tag_id);


--
-- Name: name_tag name_tag_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name_tag
    ADD CONSTRAINT name_tag_pkey PRIMARY KEY (id);


--
-- Name: name_type name_type_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name_type
    ADD CONSTRAINT name_type_pkey PRIMARY KEY (id);


--
-- Name: namespace namespace_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.namespace
    ADD CONSTRAINT namespace_pkey PRIMARY KEY (id);


--
-- Name: instance no_duplicate_synonyms; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance
    ADD CONSTRAINT no_duplicate_synonyms UNIQUE (name_id, reference_id, instance_type_id, page, cites_id, cited_by_id);


--
-- Name: notification notification_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification
    ADD CONSTRAINT notification_pkey PRIMARY KEY (id);


--
-- Name: name_rank nr_unique_name; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name_rank
    ADD CONSTRAINT nr_unique_name UNIQUE (name_group_id, name);


--
-- Name: name_status ns_unique_name; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name_status
    ADD CONSTRAINT ns_unique_name UNIQUE (name_group_id, name);


--
-- Name: nsl3164 nsl3164_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nsl3164
    ADD CONSTRAINT nsl3164_pkey PRIMARY KEY (id);


--
-- Name: name_type nt_unique_name; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name_type
    ADD CONSTRAINT nt_unique_name UNIQUE (name_group_id, name);


--
-- Name: ref_author_role ref_author_role_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ref_author_role
    ADD CONSTRAINT ref_author_role_pkey PRIMARY KEY (id);


--
-- Name: ref_type ref_type_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ref_type
    ADD CONSTRAINT ref_type_pkey PRIMARY KEY (id);


--
-- Name: reference reference_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reference
    ADD CONSTRAINT reference_pkey PRIMARY KEY (id);


--
-- Name: resource resource_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.resource
    ADD CONSTRAINT resource_pkey PRIMARY KEY (id);


--
-- Name: resource_type resource_type_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.resource_type
    ADD CONSTRAINT resource_type_pkey PRIMARY KEY (id);


--
-- Name: shard_config shard_config_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shard_config
    ADD CONSTRAINT shard_config_pkey PRIMARY KEY (id);


--
-- Name: site site_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.site
    ADD CONSTRAINT site_pkey PRIMARY KEY (id);


--
-- Name: tree_element_distribution_entries tree_element_distribution_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tree_element_distribution_entries
    ADD CONSTRAINT tree_element_distribution_entries_pkey PRIMARY KEY (tree_element_id, dist_entry_id);


--
-- Name: tree_element tree_element_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tree_element
    ADD CONSTRAINT tree_element_pkey PRIMARY KEY (id);


--
-- Name: tree tree_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tree
    ADD CONSTRAINT tree_pkey PRIMARY KEY (id);


--
-- Name: tree_version_element tree_version_element_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tree_version_element
    ADD CONSTRAINT tree_version_element_pkey PRIMARY KEY (element_link);


--
-- Name: tree_version tree_version_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tree_version
    ADD CONSTRAINT tree_version_pkey PRIMARY KEY (id);


--
-- Name: ref_type uk_4fp66uflo7rgx59167ajs0ujv; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ref_type
    ADD CONSTRAINT uk_4fp66uflo7rgx59167ajs0ujv UNIQUE (name);


--
-- Name: name_group uk_5185nbyw5hkxqyyqgylfn2o6d; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name_group
    ADD CONSTRAINT uk_5185nbyw5hkxqyyqgylfn2o6d UNIQUE (name);


--
-- Name: name uk_66rbixlxv32riosi9ob62m8h5; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name
    ADD CONSTRAINT uk_66rbixlxv32riosi9ob62m8h5 UNIQUE (uri);


--
-- Name: author uk_9kovg6nyb11658j2tv2yv4bsi; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.author
    ADD CONSTRAINT uk_9kovg6nyb11658j2tv2yv4bsi UNIQUE (abbrev);


--
-- Name: instance_note_key uk_a0justk7c77bb64o6u1riyrlh; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance_note_key
    ADD CONSTRAINT uk_a0justk7c77bb64o6u1riyrlh UNIQUE (name);


--
-- Name: instance uk_bl9pesvdo9b3mp2qdna1koqc7; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance
    ADD CONSTRAINT uk_bl9pesvdo9b3mp2qdna1koqc7 UNIQUE (uri);


--
-- Name: namespace uk_eq2y9mghytirkcofquanv5frf; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.namespace
    ADD CONSTRAINT uk_eq2y9mghytirkcofquanv5frf UNIQUE (name);


--
-- Name: language uk_g8hr207ijpxlwu10pewyo65gv; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.language
    ADD CONSTRAINT uk_g8hr207ijpxlwu10pewyo65gv UNIQUE (name);


--
-- Name: language uk_hghw87nl0ho38f166atlpw2hy; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.language
    ADD CONSTRAINT uk_hghw87nl0ho38f166atlpw2hy UNIQUE (iso6391code);


--
-- Name: instance_type uk_j5337m9qdlirvd49v4h11t1lk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance_type
    ADD CONSTRAINT uk_j5337m9qdlirvd49v4h11t1lk UNIQUE (name);


--
-- Name: reference uk_kqwpm0crhcq4n9t9uiyfxo2df; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reference
    ADD CONSTRAINT uk_kqwpm0crhcq4n9t9uiyfxo2df UNIQUE (doi);


--
-- Name: ref_author_role uk_l95kedbafybjpp3h53x8o9fke; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ref_author_role
    ADD CONSTRAINT uk_l95kedbafybjpp3h53x8o9fke UNIQUE (name);


--
-- Name: reference uk_nivlrafbqdoj0yie46ixithd3; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reference
    ADD CONSTRAINT uk_nivlrafbqdoj0yie46ixithd3 UNIQUE (uri);


--
-- Name: name_tag uk_o4su6hi7vh0yqs4c1dw0fsf1e; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name_tag
    ADD CONSTRAINT uk_o4su6hi7vh0yqs4c1dw0fsf1e UNIQUE (name);


--
-- Name: author uk_rd7q78koyhufe1edfb2rgfrum; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.author
    ADD CONSTRAINT uk_rd7q78koyhufe1edfb2rgfrum UNIQUE (uri);


--
-- Name: language uk_rpsahneqboogcki6p1bpygsua; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.language
    ADD CONSTRAINT uk_rpsahneqboogcki6p1bpygsua UNIQUE (iso6393code);


--
-- Name: name_category uk_rxqxoenedjdjyd4x7c98s59io; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name_category
    ADD CONSTRAINT uk_rxqxoenedjdjyd4x7c98s59io UNIQUE (name);


--
-- Name: id_mapper unique_from_id; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.id_mapper
    ADD CONSTRAINT unique_from_id UNIQUE (to_id, from_id);


--
-- Name: logged_actions_action_idx; Type: INDEX; Schema: audit; Owner: -
--

CREATE INDEX logged_actions_action_idx ON audit.logged_actions USING btree (action);


--
-- Name: logged_actions_action_tstamp_tx_stm_idx; Type: INDEX; Schema: audit; Owner: -
--

CREATE INDEX logged_actions_action_tstamp_tx_stm_idx ON audit.logged_actions USING btree (action_tstamp_stm);


--
-- Name: logged_actions_relid_idx; Type: INDEX; Schema: audit; Owner: -
--

CREATE INDEX logged_actions_relid_idx ON audit.logged_actions USING btree (relid);


--
-- Name: identifier_index; Type: INDEX; Schema: mapper; Owner: -
--

CREATE INDEX identifier_index ON mapper.identifier USING btree (id_number, name_space, object_type);


--
-- Name: identifier_prefuri_index; Type: INDEX; Schema: mapper; Owner: -
--

CREATE INDEX identifier_prefuri_index ON mapper.identifier USING btree (preferred_uri_id);


--
-- Name: identifier_type_space_idx; Type: INDEX; Schema: mapper; Owner: -
--

CREATE INDEX identifier_type_space_idx ON mapper.identifier USING btree (object_type, name_space);


--
-- Name: identifier_version_index; Type: INDEX; Schema: mapper; Owner: -
--

CREATE INDEX identifier_version_index ON mapper.identifier USING btree (id_number, name_space, object_type, version_number);


--
-- Name: identity_uri_index; Type: INDEX; Schema: mapper; Owner: -
--

CREATE INDEX identity_uri_index ON mapper.match USING btree (uri);


--
-- Name: mapper_identifier_index; Type: INDEX; Schema: mapper; Owner: -
--

CREATE INDEX mapper_identifier_index ON mapper.identifier_identities USING btree (identifier_id);


--
-- Name: mapper_match_index; Type: INDEX; Schema: mapper; Owner: -
--

CREATE INDEX mapper_match_index ON mapper.identifier_identities USING btree (match_id);


--
-- Name: match_host_index; Type: INDEX; Schema: mapper; Owner: -
--

CREATE INDEX match_host_index ON mapper.match_host USING btree (match_hosts_id);


--
-- Name: auth_source_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auth_source_index ON public.author USING btree (namespace_id, source_id, source_system);


--
-- Name: auth_source_string_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auth_source_string_index ON public.author USING btree (source_id_string);


--
-- Name: auth_system_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auth_system_index ON public.author USING btree (source_system);


--
-- Name: author_abbrev_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX author_abbrev_index ON public.author USING btree (abbrev);


--
-- Name: author_name_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX author_name_index ON public.author USING btree (name);


--
-- Name: comment_author_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX comment_author_index ON public.comment USING btree (author_id);


--
-- Name: comment_instance_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX comment_instance_index ON public.comment USING btree (instance_id);


--
-- Name: comment_name_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX comment_name_index ON public.comment USING btree (name_id);


--
-- Name: comment_reference_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX comment_reference_index ON public.comment USING btree (reference_id);


--
-- Name: event_record_created_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX event_record_created_index ON public.event_record USING btree (created_at);


--
-- Name: event_record_dealt_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX event_record_dealt_index ON public.event_record USING btree (dealt_with);


--
-- Name: event_record_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX event_record_index ON public.event_record USING btree (created_at, dealt_with, type);


--
-- Name: event_record_type_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX event_record_type_index ON public.event_record USING btree (type);


--
-- Name: id_mapper_from_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX id_mapper_from_index ON public.id_mapper USING btree (from_id, namespace_id, system);


--
-- Name: instance_citedby_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX instance_citedby_index ON public.instance USING btree (cited_by_id);


--
-- Name: instance_cites_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX instance_cites_index ON public.instance USING btree (cites_id);


--
-- Name: instance_instancetype_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX instance_instancetype_index ON public.instance USING btree (instance_type_id);


--
-- Name: instance_name_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX instance_name_index ON public.instance USING btree (name_id);


--
-- Name: instance_note_key_rdfid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX instance_note_key_rdfid ON public.instance_note_key USING btree (rdf_id);


--
-- Name: instance_parent_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX instance_parent_index ON public.instance USING btree (parent_id);


--
-- Name: instance_reference_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX instance_reference_index ON public.instance USING btree (reference_id);


--
-- Name: instance_source_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX instance_source_index ON public.instance USING btree (namespace_id, source_id, source_system);


--
-- Name: instance_source_string_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX instance_source_string_index ON public.instance USING btree (source_id_string);


--
-- Name: instance_system_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX instance_system_index ON public.instance USING btree (source_system);


--
-- Name: instance_type_rdfid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX instance_type_rdfid ON public.instance_type USING btree (rdf_id);


--
-- Name: lower_full_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX lower_full_name ON public.name USING btree (lower((full_name)::text));


--
-- Name: name_author_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_author_index ON public.name USING btree (author_id);


--
-- Name: name_baseauthor_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_baseauthor_index ON public.name USING btree (base_author_id);


--
-- Name: name_category_rdfid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_category_rdfid ON public.name_category USING btree (rdf_id);


--
-- Name: name_duplicate_of_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_duplicate_of_id_index ON public.name USING btree (duplicate_of_id);


--
-- Name: name_exauthor_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_exauthor_index ON public.name USING btree (ex_author_id);


--
-- Name: name_exbaseauthor_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_exbaseauthor_index ON public.name USING btree (ex_base_author_id);


--
-- Name: name_full_name_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_full_name_index ON public.name USING btree (full_name);


--
-- Name: name_group_rdfid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_group_rdfid ON public.name_group USING btree (rdf_id);


--
-- Name: name_lower_f_unaccent_full_name_like; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_lower_f_unaccent_full_name_like ON public.name USING btree (lower(public.f_unaccent((full_name)::text)) varchar_pattern_ops);


--
-- Name: name_lower_full_name_gin_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_lower_full_name_gin_trgm ON public.name USING gin (lower((full_name)::text) public.gin_trgm_ops);


--
-- Name: name_lower_simple_name_gin_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_lower_simple_name_gin_trgm ON public.name USING gin (lower((simple_name)::text) public.gin_trgm_ops);


--
-- Name: name_lower_unacent_full_name_gin_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_lower_unacent_full_name_gin_trgm ON public.name USING gin (lower(public.f_unaccent((full_name)::text)) public.gin_trgm_ops);


--
-- Name: name_lower_unacent_simple_name_gin_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_lower_unacent_simple_name_gin_trgm ON public.name USING gin (lower(public.f_unaccent((simple_name)::text)) public.gin_trgm_ops);


--
-- Name: name_name_element_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_name_element_index ON public.name USING btree (name_element);


--
-- Name: name_parent_id_ndx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_parent_id_ndx ON public.name USING btree (parent_id);


--
-- Name: name_rank_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_rank_index ON public.name USING btree (name_rank_id);


--
-- Name: name_rank_rdfid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_rank_rdfid ON public.name_rank USING btree (rdf_id);


--
-- Name: name_sanctioningauthor_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_sanctioningauthor_index ON public.name USING btree (sanctioning_author_id);


--
-- Name: name_second_parent_id_ndx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_second_parent_id_ndx ON public.name USING btree (second_parent_id);


--
-- Name: name_simple_name_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_simple_name_index ON public.name USING btree (simple_name);


--
-- Name: name_source_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_source_index ON public.name USING btree (namespace_id, source_id, source_system);


--
-- Name: name_source_string_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_source_string_index ON public.name USING btree (source_id_string);


--
-- Name: name_status_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_status_index ON public.name USING btree (name_status_id);


--
-- Name: name_status_rdfid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_status_rdfid ON public.name_status USING btree (rdf_id);


--
-- Name: name_system_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_system_index ON public.name USING btree (source_system);


--
-- Name: name_tag_name_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_tag_name_index ON public.name_tag_name USING btree (name_id);


--
-- Name: name_tag_tag_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_tag_tag_index ON public.name_tag_name USING btree (tag_id);


--
-- Name: name_type_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_type_index ON public.name USING btree (name_type_id);


--
-- Name: name_type_rdfid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_type_rdfid ON public.name_type USING btree (rdf_id);


--
-- Name: namespace_rdfid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX namespace_rdfid ON public.namespace USING btree (rdf_id);


--
-- Name: note_instance_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX note_instance_index ON public.instance_note USING btree (instance_id);


--
-- Name: note_key_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX note_key_index ON public.instance_note USING btree (instance_note_key_id);


--
-- Name: note_source_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX note_source_index ON public.instance_note USING btree (namespace_id, source_id, source_system);


--
-- Name: note_source_string_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX note_source_string_index ON public.instance_note USING btree (source_id_string);


--
-- Name: note_system_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX note_system_index ON public.instance_note USING btree (source_system);


--
-- Name: ref_author_role_rdfid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ref_author_role_rdfid ON public.ref_author_role USING btree (rdf_id);


--
-- Name: ref_citation_text_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ref_citation_text_index ON public.reference USING gin (to_tsvector('english'::regconfig, public.f_unaccent(COALESCE((citation)::text, ''::text))));


--
-- Name: ref_source_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ref_source_index ON public.reference USING btree (namespace_id, source_id, source_system);


--
-- Name: ref_source_string_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ref_source_string_index ON public.reference USING btree (source_id_string);


--
-- Name: ref_system_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ref_system_index ON public.reference USING btree (source_system);


--
-- Name: ref_type_rdfid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ref_type_rdfid ON public.ref_type USING btree (rdf_id);


--
-- Name: reference_author_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX reference_author_index ON public.reference USING btree (author_id);


--
-- Name: reference_authorrole_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX reference_authorrole_index ON public.reference USING btree (ref_author_role_id);


--
-- Name: reference_parent_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX reference_parent_index ON public.reference USING btree (parent_id);


--
-- Name: reference_type_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX reference_type_index ON public.reference USING btree (ref_type_id);


--
-- Name: tree_element_instance_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tree_element_instance_index ON public.tree_element USING btree (instance_id);


--
-- Name: tree_element_name_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tree_element_name_index ON public.tree_element USING btree (name_id);


--
-- Name: tree_element_previous_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tree_element_previous_index ON public.tree_element USING btree (previous_element_id);


--
-- Name: tree_name_path_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tree_name_path_index ON public.tree_version_element USING btree (name_path);


--
-- Name: tree_path_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tree_path_index ON public.tree_version_element USING btree (tree_path);


--
-- Name: tree_simple_name_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tree_simple_name_index ON public.tree_element USING btree (simple_name);


--
-- Name: tree_synonyms_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tree_synonyms_index ON public.tree_element USING gin (synonyms);


--
-- Name: tree_version_element_element_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tree_version_element_element_index ON public.tree_version_element USING btree (tree_element_id);


--
-- Name: tree_version_element_link_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tree_version_element_link_index ON public.tree_version_element USING btree (element_link);


--
-- Name: tree_version_element_parent_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tree_version_element_parent_index ON public.tree_version_element USING btree (parent_id);


--
-- Name: tree_version_element_taxon_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tree_version_element_taxon_id_index ON public.tree_version_element USING btree (taxon_id);


--
-- Name: tree_version_element_taxon_link_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tree_version_element_taxon_link_index ON public.tree_version_element USING btree (taxon_link);


--
-- Name: tree_version_element_version_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tree_version_element_version_index ON public.tree_version_element USING btree (tree_version_id);


--
-- Name: comment audit_trigger_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_trigger_row
    AFTER INSERT OR DELETE OR UPDATE
    ON public.comment
    FOR EACH ROW
EXECUTE PROCEDURE audit.if_modified_func('true');


--
-- Name: author audit_trigger_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON public.author FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');


--
-- Name: instance_note audit_trigger_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_trigger_row
    AFTER INSERT OR DELETE OR UPDATE
    ON public.instance_note
    FOR EACH ROW
EXECUTE PROCEDURE audit.if_modified_func('true');


--
-- Name: reference audit_trigger_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_trigger_row
    AFTER INSERT OR DELETE OR UPDATE
    ON public.reference
    FOR EACH ROW
EXECUTE PROCEDURE audit.if_modified_func('true');


--
-- Name: name audit_trigger_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON public.name FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');


--
-- Name: instance audit_trigger_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_trigger_row
    AFTER INSERT OR DELETE OR UPDATE
    ON public.instance
    FOR EACH ROW
EXECUTE PROCEDURE audit.if_modified_func('true');


--
-- Name: comment audit_trigger_stm; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_trigger_stm
    AFTER TRUNCATE
    ON public.comment
    FOR EACH STATEMENT
EXECUTE PROCEDURE audit.if_modified_func('true');


--
-- Name: author audit_trigger_stm; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON public.author FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');


--
-- Name: instance_note audit_trigger_stm; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_trigger_stm
    AFTER TRUNCATE
    ON public.instance_note
    FOR EACH STATEMENT
EXECUTE PROCEDURE audit.if_modified_func('true');


--
-- Name: reference audit_trigger_stm; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON public.reference FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');


--
-- Name: name audit_trigger_stm; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_trigger_stm
    AFTER TRUNCATE
    ON public.name
    FOR EACH STATEMENT
EXECUTE PROCEDURE audit.if_modified_func('true');


--
-- Name: instance audit_trigger_stm; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_trigger_stm
    AFTER TRUNCATE
    ON public.instance
    FOR EACH STATEMENT
EXECUTE PROCEDURE audit.if_modified_func('true');


--
-- Name: author author_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER author_update AFTER INSERT OR DELETE OR UPDATE ON public.author FOR EACH ROW EXECUTE PROCEDURE public.author_notification();


--
-- Name: instance instance_insert_delete; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER instance_insert_delete
    AFTER INSERT OR DELETE
    ON public.instance
    FOR EACH ROW
EXECUTE PROCEDURE public.instance_notification();


--
-- Name: instance instance_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER instance_update
    AFTER UPDATE OF cited_by_id
    ON public.instance
    FOR EACH ROW
EXECUTE PROCEDURE public.instance_notification();


--
-- Name: name name_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER name_update AFTER INSERT OR DELETE OR UPDATE ON public.name FOR EACH ROW EXECUTE PROCEDURE public.name_notification();


--
-- Name: reference reference_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER reference_update AFTER INSERT OR DELETE OR UPDATE ON public.reference FOR EACH ROW EXECUTE PROCEDURE public.reference_notification();


--
-- Name: match_host fk_3unhnjvw9xhs9l3ney6tvnioq; Type: FK CONSTRAINT; Schema: mapper; Owner: -
--

ALTER TABLE ONLY mapper.match_host
    ADD CONSTRAINT fk_3unhnjvw9xhs9l3ney6tvnioq FOREIGN KEY (host_id) REFERENCES mapper.host(id);


--
-- Name: match_host fk_iw1fva74t5r4ehvmoy87n37yr; Type: FK CONSTRAINT; Schema: mapper; Owner: -
--

ALTER TABLE ONLY mapper.match_host
    ADD CONSTRAINT fk_iw1fva74t5r4ehvmoy87n37yr FOREIGN KEY (match_hosts_id) REFERENCES mapper.match(id);


--
-- Name: identifier fk_k2o53uoslf9gwqrd80cu2al4s; Type: FK CONSTRAINT; Schema: mapper; Owner: -
--

ALTER TABLE ONLY mapper.identifier
    ADD CONSTRAINT fk_k2o53uoslf9gwqrd80cu2al4s FOREIGN KEY (preferred_uri_id) REFERENCES mapper.match(id);


--
-- Name: identifier_identities fk_mf2dsc2dxvsa9mlximsct7uau; Type: FK CONSTRAINT; Schema: mapper; Owner: -
--

ALTER TABLE ONLY mapper.identifier_identities
    ADD CONSTRAINT fk_mf2dsc2dxvsa9mlximsct7uau FOREIGN KEY (match_id) REFERENCES mapper.match(id);


--
-- Name: identifier_identities fk_ojfilkcwskdvvbggwsnachry2; Type: FK CONSTRAINT; Schema: mapper; Owner: -
--

ALTER TABLE ONLY mapper.identifier_identities
    ADD CONSTRAINT fk_ojfilkcwskdvvbggwsnachry2 FOREIGN KEY (identifier_id) REFERENCES mapper.identifier(id);


--
-- Name: name_type fk_10d0jlulq2woht49j5ccpeehu; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name_type
    ADD CONSTRAINT fk_10d0jlulq2woht49j5ccpeehu FOREIGN KEY (name_category_id) REFERENCES public.name_category(id);


--
-- Name: name fk_156ncmx4599jcsmhh5k267cjv; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name
    ADD CONSTRAINT fk_156ncmx4599jcsmhh5k267cjv FOREIGN KEY (namespace_id) REFERENCES public.namespace(id);


--
-- Name: reference fk_1qx84m8tuk7vw2diyxfbj5r2n; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reference
    ADD CONSTRAINT fk_1qx84m8tuk7vw2diyxfbj5r2n FOREIGN KEY (language_id) REFERENCES public.language(id);


--
-- Name: name_tag_name fk_22wdc2pxaskytkgpdgpyok07n; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name_tag_name
    ADD CONSTRAINT fk_22wdc2pxaskytkgpdgpyok07n FOREIGN KEY (name_id) REFERENCES public.name(id);


--
-- Name: name_tag_name fk_2uiijd73snf6lh5s6a82yjfin; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name_tag_name
    ADD CONSTRAINT fk_2uiijd73snf6lh5s6a82yjfin FOREIGN KEY (tag_id) REFERENCES public.name_tag(id);


--
-- Name: instance fk_30enb6qoexhuk479t75apeuu5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance
    ADD CONSTRAINT fk_30enb6qoexhuk479t75apeuu5 FOREIGN KEY (cites_id) REFERENCES public.instance(id);


--
-- Name: reference fk_3min66ljijxavb0fjergx5dpm; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reference
    ADD CONSTRAINT fk_3min66ljijxavb0fjergx5dpm FOREIGN KEY (duplicate_of_id) REFERENCES public.reference(id);


--
-- Name: name fk_3pqdqa03w5c6h4yyrrvfuagos; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name
    ADD CONSTRAINT fk_3pqdqa03w5c6h4yyrrvfuagos FOREIGN KEY (duplicate_of_id) REFERENCES public.name(id);


--
-- Name: comment fk_3tfkdcmf6rg6hcyiu8t05er7x; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comment
    ADD CONSTRAINT fk_3tfkdcmf6rg6hcyiu8t05er7x FOREIGN KEY (reference_id) REFERENCES public.reference(id);


--
-- Name: tree fk_48skgw51tamg6ud4qa8oh0ycm; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tree
    ADD CONSTRAINT fk_48skgw51tamg6ud4qa8oh0ycm FOREIGN KEY (default_draft_tree_version_id) REFERENCES public.tree_version(id);


--
-- Name: instance_resources fk_49ic33s4xgbdoa4p5j107rtpf; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance_resources
    ADD CONSTRAINT fk_49ic33s4xgbdoa4p5j107rtpf FOREIGN KEY (instance_id) REFERENCES public.instance(id);


--
-- Name: tree_version fk_4q3huja5dv8t9xyvt5rg83a35; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tree_version
    ADD CONSTRAINT fk_4q3huja5dv8t9xyvt5rg83a35 FOREIGN KEY (tree_id) REFERENCES public.tree(id);


--
-- Name: ref_type fk_51alfoe7eobwh60yfx45y22ay; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ref_type
    ADD CONSTRAINT fk_51alfoe7eobwh60yfx45y22ay FOREIGN KEY (parent_id) REFERENCES public.ref_type(id);


--
-- Name: name fk_5fpm5u0ukiml9nvmq14bd7u51; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name
    ADD CONSTRAINT fk_5fpm5u0ukiml9nvmq14bd7u51 FOREIGN KEY (name_status_id) REFERENCES public.name_status(id);


--
-- Name: name fk_5gp2lfblqq94c4ud3340iml0l; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name
    ADD CONSTRAINT fk_5gp2lfblqq94c4ud3340iml0l FOREIGN KEY (second_parent_id) REFERENCES public.name(id);


--
-- Name: name_type fk_5r3o78sgdbxsf525hmm3t44gv; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name_type
    ADD CONSTRAINT fk_5r3o78sgdbxsf525hmm3t44gv FOREIGN KEY (name_group_id) REFERENCES public.name_group(id);


--
-- Name: tree_element fk_5sv181ivf7oybb6hud16ptmo5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tree_element
    ADD CONSTRAINT fk_5sv181ivf7oybb6hud16ptmo5 FOREIGN KEY (previous_element_id) REFERENCES public.tree_element(id);


--
-- Name: author fk_6a4p11f1bt171w09oo06m0wag; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.author
    ADD CONSTRAINT fk_6a4p11f1bt171w09oo06m0wag FOREIGN KEY (duplicate_of_id) REFERENCES public.author(id);


--
-- Name: resource_type fk_6nxjoae1hvplngbvpo0k57jjt; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.resource_type
    ADD CONSTRAINT fk_6nxjoae1hvplngbvpo0k57jjt FOREIGN KEY (media_icon_id) REFERENCES public.media(id);


--
-- Name: comment fk_6oqj6vquqc33cyawn853hfu5g; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comment
    ADD CONSTRAINT fk_6oqj6vquqc33cyawn853hfu5g FOREIGN KEY (instance_id) REFERENCES public.instance(id);


--
-- Name: tree_version_element fk_80khvm60q13xwqgpy43twlnoe; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tree_version_element
    ADD CONSTRAINT fk_80khvm60q13xwqgpy43twlnoe FOREIGN KEY (tree_version_id) REFERENCES public.tree_version(id);


--
-- Name: instance_resources fk_8mal9hru5u3ypaosfoju8ulpd; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance_resources
    ADD CONSTRAINT fk_8mal9hru5u3ypaosfoju8ulpd FOREIGN KEY (resource_id) REFERENCES public.resource(id);


--
-- Name: tree_version_element fk_8nnhwv8ldi9ppol6tg4uwn4qv; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tree_version_element
    ADD CONSTRAINT fk_8nnhwv8ldi9ppol6tg4uwn4qv FOREIGN KEY (parent_id) REFERENCES public.tree_version_element(element_link);


--
-- Name: comment fk_9aq5p2jgf17y6b38x5ayd90oc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comment
    ADD CONSTRAINT fk_9aq5p2jgf17y6b38x5ayd90oc FOREIGN KEY (author_id) REFERENCES public.author(id);


--
-- Name: reference fk_a98ei1lxn89madjihel3cvi90; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reference
    ADD CONSTRAINT fk_a98ei1lxn89madjihel3cvi90 FOREIGN KEY (ref_author_role_id) REFERENCES public.ref_author_role(id);


--
-- Name: name fk_ai81l07vh2yhmthr3582igo47; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name
    ADD CONSTRAINT fk_ai81l07vh2yhmthr3582igo47 FOREIGN KEY (sanctioning_author_id) REFERENCES public.author(id);


--
-- Name: name fk_airfjupm6ohehj1lj82yqkwdx; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name
    ADD CONSTRAINT fk_airfjupm6ohehj1lj82yqkwdx FOREIGN KEY (author_id) REFERENCES public.author(id);


--
-- Name: reference fk_am2j11kvuwl19gqewuu18gjjm; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reference
    ADD CONSTRAINT fk_am2j11kvuwl19gqewuu18gjjm FOREIGN KEY (namespace_id) REFERENCES public.namespace(id);


--
-- Name: name fk_bcef76k0ijrcquyoc0yxehxfp; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name
    ADD CONSTRAINT fk_bcef76k0ijrcquyoc0yxehxfp FOREIGN KEY (name_type_id) REFERENCES public.name_type(id);


--
-- Name: instance_note fk_bw41122jb5rcu8wfnog812s97; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance_note
    ADD CONSTRAINT fk_bw41122jb5rcu8wfnog812s97 FOREIGN KEY (instance_id) REFERENCES public.instance(id);


--
-- Name: name fk_coqxx3ewgiecsh3t78yc70b35; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name
    ADD CONSTRAINT fk_coqxx3ewgiecsh3t78yc70b35 FOREIGN KEY (base_author_id) REFERENCES public.author(id);


--
-- Name: dist_entry_dist_status fk_cpmfv1d7wlx26gjiyxrebjvxn; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dist_entry_dist_status
    ADD CONSTRAINT fk_cpmfv1d7wlx26gjiyxrebjvxn FOREIGN KEY (dist_entry_status_id) REFERENCES public.dist_entry (id);


--
-- Name: reference fk_cr9avt4miqikx4kk53aflnnkd; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reference
    ADD CONSTRAINT fk_cr9avt4miqikx4kk53aflnnkd FOREIGN KEY (parent_id) REFERENCES public.reference(id);


--
-- Name: name fk_dd33etb69v5w5iah1eeisy7yt; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name
    ADD CONSTRAINT fk_dd33etb69v5w5iah1eeisy7yt FOREIGN KEY (parent_id) REFERENCES public.name(id);


--
-- Name: reference fk_dm9y4p9xpsc8m7vljbohubl7x; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reference
    ADD CONSTRAINT fk_dm9y4p9xpsc8m7vljbohubl7x FOREIGN KEY (ref_type_id) REFERENCES public.ref_type(id);


--
-- Name: instance_note fk_f6s94njexmutjxjv8t5dy1ugt; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance_note
    ADD CONSTRAINT fk_f6s94njexmutjxjv8t5dy1ugt FOREIGN KEY (namespace_id) REFERENCES public.namespace(id);


--
-- Name: dist_entry fk_ffleu7615efcrsst8l64wvomw; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dist_entry
    ADD CONSTRAINT fk_ffleu7615efcrsst8l64wvomw FOREIGN KEY (region_id) REFERENCES public.dist_region (id);


--
-- Name: tree_element_distribution_entries fk_fmic32f9o0fplk3xdix1yu6ha; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tree_element_distribution_entries
    ADD CONSTRAINT fk_fmic32f9o0fplk3xdix1yu6ha FOREIGN KEY (tree_element_id) REFERENCES public.tree_element (id);


--
-- Name: dist_status_dist_status fk_g38me2w6f5ismhdjbj8je7nv0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dist_status_dist_status
    ADD CONSTRAINT fk_g38me2w6f5ismhdjbj8je7nv0 FOREIGN KEY (dist_status_id) REFERENCES public.dist_status (id);


--
-- Name: name_status fk_g4o6xditli5a0xrm6eqc6h9gw; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name_status
    ADD CONSTRAINT fk_g4o6xditli5a0xrm6eqc6h9gw FOREIGN KEY (name_status_id) REFERENCES public.name_status(id);


--
-- Name: instance fk_gdunt8xo68ct1vfec9c6x5889; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance
    ADD CONSTRAINT fk_gdunt8xo68ct1vfec9c6x5889 FOREIGN KEY (name_id) REFERENCES public.name(id);


--
-- Name: instance fk_gtkjmbvk6uk34fbfpy910e7t6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance
    ADD CONSTRAINT fk_gtkjmbvk6uk34fbfpy910e7t6 FOREIGN KEY (namespace_id) REFERENCES public.namespace(id);


--
-- Name: tree_element_distribution_entries fk_h7k45ugqa75w0860tysr4fgrt; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tree_element_distribution_entries
    ADD CONSTRAINT fk_h7k45ugqa75w0860tysr4fgrt FOREIGN KEY (dist_entry_id) REFERENCES public.dist_entry (id);


--
-- Name: comment fk_h9t5eaaqhnqwrc92rhryyvdcf; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comment
    ADD CONSTRAINT fk_h9t5eaaqhnqwrc92rhryyvdcf FOREIGN KEY (name_id) REFERENCES public.name(id);


--
-- Name: instance fk_hb0xb97midopfgrm2k5fpe3p1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance
    ADD CONSTRAINT fk_hb0xb97midopfgrm2k5fpe3p1 FOREIGN KEY (parent_id) REFERENCES public.instance(id);


--
-- Name: instance_note fk_he1t3ug0o7ollnk2jbqaouooa; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance_note
    ADD CONSTRAINT fk_he1t3ug0o7ollnk2jbqaouooa FOREIGN KEY (instance_note_key_id) REFERENCES public.instance_note_key(id);


--
-- Name: resource fk_i2tgkebwedao7dlbjcrnvvtrv; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.resource
    ADD CONSTRAINT fk_i2tgkebwedao7dlbjcrnvvtrv FOREIGN KEY (resource_type_id) REFERENCES public.resource_type(id);


--
-- Name: dist_entry_dist_status fk_jnh4hl7ev54cknuwm5juvb22i; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dist_entry_dist_status
    ADD CONSTRAINT fk_jnh4hl7ev54cknuwm5juvb22i FOREIGN KEY (dist_status_id) REFERENCES public.dist_status (id);


--
-- Name: resource fk_l76e0lo0edcngyyqwkmkgywj9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.resource
    ADD CONSTRAINT fk_l76e0lo0edcngyyqwkmkgywj9 FOREIGN KEY (site_id) REFERENCES public.site(id);


--
-- Name: instance fk_lumlr5avj305pmc4hkjwaqk45; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance
    ADD CONSTRAINT fk_lumlr5avj305pmc4hkjwaqk45 FOREIGN KEY (reference_id) REFERENCES public.reference(id);


--
-- Name: instance fk_o80rrtl8xwy4l3kqrt9qv0mnt; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance
    ADD CONSTRAINT fk_o80rrtl8xwy4l3kqrt9qv0mnt FOREIGN KEY (instance_type_id) REFERENCES public.instance_type(id);


--
-- Name: author fk_p0ysrub11cm08xnhrbrfrvudh; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.author
    ADD CONSTRAINT fk_p0ysrub11cm08xnhrbrfrvudh FOREIGN KEY (namespace_id) REFERENCES public.namespace(id);


--
-- Name: name_rank fk_p3lpayfbl9s3hshhoycfj82b9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name_rank
    ADD CONSTRAINT fk_p3lpayfbl9s3hshhoycfj82b9 FOREIGN KEY (name_group_id) REFERENCES public.name_group(id);


--
-- Name: reference fk_p8lhsoo01164dsvvwxob0w3sp; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reference
    ADD CONSTRAINT fk_p8lhsoo01164dsvvwxob0w3sp FOREIGN KEY (author_id) REFERENCES public.author(id);


--
-- Name: instance fk_pr2f6peqhnx9rjiwkr5jgc5be; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance
    ADD CONSTRAINT fk_pr2f6peqhnx9rjiwkr5jgc5be FOREIGN KEY (cited_by_id) REFERENCES public.instance(id);


--
-- Name: dist_status_dist_status fk_q0p6tn5peagvsl7xmqcy39yuh; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dist_status_dist_status
    ADD CONSTRAINT fk_q0p6tn5peagvsl7xmqcy39yuh FOREIGN KEY (dist_status_combining_status_id) REFERENCES public.dist_status (id);


--
-- Name: id_mapper fk_qiy281xsleyhjgr0eu1sboagm; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.id_mapper
    ADD CONSTRAINT fk_qiy281xsleyhjgr0eu1sboagm FOREIGN KEY (namespace_id) REFERENCES public.namespace(id);


--
-- Name: name_rank fk_r67um91pujyfrx7h1cifs3cmb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name_rank
    ADD CONSTRAINT fk_r67um91pujyfrx7h1cifs3cmb FOREIGN KEY (parent_rank_id) REFERENCES public.name_rank(id);


--
-- Name: name fk_rp659tjcxokf26j8551k6an2y; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name
    ADD CONSTRAINT fk_rp659tjcxokf26j8551k6an2y FOREIGN KEY (ex_base_author_id) REFERENCES public.author(id);


--
-- Name: name fk_sgvxmyj7r9g4wy9c4hd1yn4nu; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name
    ADD CONSTRAINT fk_sgvxmyj7r9g4wy9c4hd1yn4nu FOREIGN KEY (ex_author_id) REFERENCES public.author(id);


--
-- Name: name fk_sk2iikq8wla58jeypkw6h74hc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name
    ADD CONSTRAINT fk_sk2iikq8wla58jeypkw6h74hc FOREIGN KEY (name_rank_id) REFERENCES public.name_rank(id);


--
-- Name: tree fk_svg2ee45qvpomoer2otdc5oyc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tree
    ADD CONSTRAINT fk_svg2ee45qvpomoer2otdc5oyc FOREIGN KEY (current_tree_version_id) REFERENCES public.tree_version(id);


--
-- Name: name_status fk_swotu3c2gy1hp8f6ekvuo7s26; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name_status
    ADD CONSTRAINT fk_swotu3c2gy1hp8f6ekvuo7s26 FOREIGN KEY (name_group_id) REFERENCES public.name_group(id);


--
-- Name: tree_version fk_tiniptsqbb5fgygt1idm1isfy; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tree_version
    ADD CONSTRAINT fk_tiniptsqbb5fgygt1idm1isfy FOREIGN KEY (previous_version_id) REFERENCES public.tree_version(id);


--
-- Name: tree_version_element fk_ufme7yt6bqyf3uxvuvouowhh; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tree_version_element
    ADD CONSTRAINT fk_ufme7yt6bqyf3uxvuvouowhh FOREIGN KEY (tree_element_id) REFERENCES public.tree_element(id);


--
-- Name: name fk_whce6pgnqjtxgt67xy2lfo34; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name
    ADD CONSTRAINT fk_whce6pgnqjtxgt67xy2lfo34 FOREIGN KEY (family_id) REFERENCES public.name(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

