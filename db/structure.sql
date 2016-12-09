--
-- PostgreSQL database dump
--

-- Dumped from database version 9.5.5
-- Dumped by pg_dump version 9.5.5

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
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


SET search_path = audit, pg_catalog;

--
-- Name: audit_table(regclass); Type: FUNCTION; Schema: audit; Owner: -
--

CREATE FUNCTION audit_table(target_table regclass) RETURNS void
    LANGUAGE sql
    AS $_$
SELECT audit.audit_table($1, BOOLEAN 't', BOOLEAN 't');
$_$;


--
-- Name: FUNCTION audit_table(target_table regclass); Type: COMMENT; Schema: audit; Owner: -
--

COMMENT ON FUNCTION audit_table(target_table regclass) IS '
Add auditing support to the given table. Row-level changes will be logged with full client query text. No cols are ignored.
';


--
-- Name: audit_table(regclass, boolean, boolean); Type: FUNCTION; Schema: audit; Owner: -
--

CREATE FUNCTION audit_table(target_table regclass, audit_rows boolean, audit_query_text boolean) RETURNS void
    LANGUAGE sql
    AS $_$
SELECT audit.audit_table($1, $2, $3, ARRAY[]::text[]);
$_$;


--
-- Name: audit_table(regclass, boolean, boolean, text[]); Type: FUNCTION; Schema: audit; Owner: -
--

CREATE FUNCTION audit_table(target_table regclass, audit_rows boolean, audit_query_text boolean, ignored_cols text[]) RETURNS void
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

COMMENT ON FUNCTION audit_table(target_table regclass, audit_rows boolean, audit_query_text boolean, ignored_cols text[]) IS '
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

CREATE FUNCTION if_modified_func() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO pg_catalog, public
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

COMMENT ON FUNCTION if_modified_func() IS '
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


SET search_path = public, pg_catalog;

--
-- Name: author_notification(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION author_notification() RETURNS trigger
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
-- Name: f_unaccent(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION f_unaccent(text) RETURNS text
    LANGUAGE sql IMMUTABLE
    SET search_path TO public, pg_temp
    AS $_$
SELECT unaccent('unaccent', $1)
$_$;


--
-- Name: find_name_in_tree(bigint, bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION find_name_in_tree(pname bigint, ptree bigint) RETURNS bigint
    LANGUAGE plpgsql
    AS $$
DECLARE
  -- declarations
  ct integer;
  base_id tree_arrangement.id%TYPE;
  link_id tree_link.id%TYPE;
BEGIN
  -- if this is a simple tree, then we can just look for the tree link directly.
  -- if it is a tree based on another tree, then we must do a treewalk

  select base_arrangement_id into base_id from tree_arrangement a where a.id = ptree;

  begin
    IF base_id is null then
      -- ok. look for the name as a current node in the tree, and find the link to its current parent.

      select l.id INTO STRICT link_id
      from tree_node c
        join tree_link l on c.id = l.subnode_id
        join tree_node p on l.supernode_id = p.id
      where c.name_id = pname
            and c.tree_arrangement_id = ptree
            and c.next_node_id is null
            and p.tree_arrangement_id = ptree
            and p.next_node_id is null;
    ELSE
      -- ok. we need to do a treewalk. As always, this gets nasty.

      with RECURSIVE walk as (
        select l.id as stem_link, l.id as leaf_link, p.tree_arrangement_id = ptree as foundit
        from tree_node c
          join tree_link l on c.id = l.subnode_id
          join tree_node p on l.supernode_id = p.id
        where
          c.name_id = pname
          and (c.tree_arrangement_id = ptree or c.tree_arrangement_id = base_id)
          and c.next_node_id is null
          and (p.tree_arrangement_id = ptree or p.tree_arrangement_id = base_id)
          and p.next_node_id is null
        UNION ALL
        SELECT
          superlink.id as stem_link, walk.leaf_link, p.tree_arrangement_id = ptree as foundit
        FROM walk
          JOIN tree_link sublink on walk.stem_link = sublink.id
          join tree_link superlink on sublink.supernode_id = superlink.subnode_id
          join tree_node p on superlink.supernode_id = p.id
        where not walk.foundit -- clip the search
              and (p.tree_arrangement_id = ptree or p.tree_arrangement_id = base_id)
              and p.next_node_id is null
      )
      select leaf_link INTO STRICT link_id from walk where foundit;

    END IF;

    return link_id;

    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      raise notice 'no data found';
      return null;
    WHEN TOO_MANY_ROWS THEN
      raise notice 'too many rows';
      RAISE 'Multiple placements of name % in tree %', pname, ptree USING ERRCODE = 'unique_violation';
  end;
END;
$$;


--
-- Name: is_instance_in_tree(bigint, bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION is_instance_in_tree(pinstance bigint, ptree bigint) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
  -- declarations
  ct integer;
  base_id tree_arrangement.id%TYPE;
BEGIN
  -- OK. Is this instance directly in the tree as a current node?

  select count(*) into ct
  from tree_node n
  where n.instance_id = pinstance
        and n.tree_arrangement_id = ptree
        and n.next_node_id is null;

  if ct <> 0 then
    return true;
  end if;

  -- is the tree derived from some other tree?

  select base_arrangement_id into base_id from tree_arrangement a where a.id = ptree;

  if base_id is null then
    return false;
  end if;

  -- right. This tree is derived from another tree. That means that the instance might be in that
  -- other tree and adopted to this one. here's where we need to do a treewalk.
  -- this code assumes that the tree will have at least one node belonging to it at the root, which currently
  -- is the case.

  with recursive treewalk as (
    select n.id as node_id, n.tree_arrangement_id
    from tree_node n
    where n.instance_id = pinstance
          and n.tree_arrangement_id = base_id
          and n.next_node_id is null
    union all
    select n.id as node_id, n.tree_arrangement_id
    from treewalk
      join tree_link l on treewalk.node_id = l.subnode_id
      join tree_node n on l.supernode_id = n.id
    where treewalk.tree_arrangement_id <> ptree -- clip search here
          and n.next_node_id is null
          and n.tree_arrangement_id in (ptree, base_id)
  )
  select count(node_id) into ct from treewalk where treewalk.tree_arrangement_id = ptree;

  return ct <> 0;
END;
$$;


--
-- Name: name_notification(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION name_notification() RETURNS trigger
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
-- Name: reference_notification(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION reference_notification() RETURNS trigger
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


SET search_path = audit, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: logged_actions; Type: TABLE; Schema: audit; Owner: -
--

CREATE TABLE logged_actions (
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

COMMENT ON TABLE logged_actions IS 'History of auditable actions on audited tables, from audit.if_modified_func()';


--
-- Name: COLUMN logged_actions.event_id; Type: COMMENT; Schema: audit; Owner: -
--

COMMENT ON COLUMN logged_actions.event_id IS 'Unique identifier for each auditable event';


--
-- Name: COLUMN logged_actions.schema_name; Type: COMMENT; Schema: audit; Owner: -
--

COMMENT ON COLUMN logged_actions.schema_name IS 'Database schema audited table for this event is in';


--
-- Name: COLUMN logged_actions.table_name; Type: COMMENT; Schema: audit; Owner: -
--

COMMENT ON COLUMN logged_actions.table_name IS 'Non-schema-qualified table name of table event occured in';


--
-- Name: COLUMN logged_actions.relid; Type: COMMENT; Schema: audit; Owner: -
--

COMMENT ON COLUMN logged_actions.relid IS 'Table OID. Changes with drop/create. Get with ''tablename''::regclass';


--
-- Name: COLUMN logged_actions.session_user_name; Type: COMMENT; Schema: audit; Owner: -
--

COMMENT ON COLUMN logged_actions.session_user_name IS 'Login / session user whose statement caused the audited event';


--
-- Name: COLUMN logged_actions.action_tstamp_tx; Type: COMMENT; Schema: audit; Owner: -
--

COMMENT ON COLUMN logged_actions.action_tstamp_tx IS 'Transaction start timestamp for tx in which audited event occurred';


--
-- Name: COLUMN logged_actions.action_tstamp_stm; Type: COMMENT; Schema: audit; Owner: -
--

COMMENT ON COLUMN logged_actions.action_tstamp_stm IS 'Statement start timestamp for tx in which audited event occurred';


--
-- Name: COLUMN logged_actions.action_tstamp_clk; Type: COMMENT; Schema: audit; Owner: -
--

COMMENT ON COLUMN logged_actions.action_tstamp_clk IS 'Wall clock time at which audited event''s trigger call occurred';


--
-- Name: COLUMN logged_actions.transaction_id; Type: COMMENT; Schema: audit; Owner: -
--

COMMENT ON COLUMN logged_actions.transaction_id IS 'Identifier of transaction that made the change. May wrap, but unique paired with action_tstamp_tx.';


--
-- Name: COLUMN logged_actions.application_name; Type: COMMENT; Schema: audit; Owner: -
--

COMMENT ON COLUMN logged_actions.application_name IS 'Application name set when this audit event occurred. Can be changed in-session by client.';


--
-- Name: COLUMN logged_actions.client_addr; Type: COMMENT; Schema: audit; Owner: -
--

COMMENT ON COLUMN logged_actions.client_addr IS 'IP address of client that issued query. Null for unix domain socket.';


--
-- Name: COLUMN logged_actions.client_port; Type: COMMENT; Schema: audit; Owner: -
--

COMMENT ON COLUMN logged_actions.client_port IS 'Remote peer IP port address of client that issued query. Undefined for unix socket.';


--
-- Name: COLUMN logged_actions.client_query; Type: COMMENT; Schema: audit; Owner: -
--

COMMENT ON COLUMN logged_actions.client_query IS 'Top-level query that caused this auditable event. May be more than one statement.';


--
-- Name: COLUMN logged_actions.action; Type: COMMENT; Schema: audit; Owner: -
--

COMMENT ON COLUMN logged_actions.action IS 'Action type; I = insert, D = delete, U = update, T = truncate';


--
-- Name: COLUMN logged_actions.row_data; Type: COMMENT; Schema: audit; Owner: -
--

COMMENT ON COLUMN logged_actions.row_data IS 'Record value. Null for statement-level trigger. For INSERT this is the new tuple. For DELETE and UPDATE it is the old tuple.';


--
-- Name: COLUMN logged_actions.changed_fields; Type: COMMENT; Schema: audit; Owner: -
--

COMMENT ON COLUMN logged_actions.changed_fields IS 'New values of fields changed by UPDATE. Null except for row-level UPDATE events.';


--
-- Name: COLUMN logged_actions.statement_only; Type: COMMENT; Schema: audit; Owner: -
--

COMMENT ON COLUMN logged_actions.statement_only IS '''t'' if audit event is from an FOR EACH STATEMENT trigger, ''f'' for FOR EACH ROW';


--
-- Name: logged_actions_event_id_seq; Type: SEQUENCE; Schema: audit; Owner: -
--

CREATE SEQUENCE logged_actions_event_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: logged_actions_event_id_seq; Type: SEQUENCE OWNED BY; Schema: audit; Owner: -
--

ALTER SEQUENCE logged_actions_event_id_seq OWNED BY logged_actions.event_id;


SET search_path = mapper, pg_catalog;

--
-- Name: db_version; Type: TABLE; Schema: mapper; Owner: -
--

CREATE TABLE db_version (
    id bigint NOT NULL,
    version integer NOT NULL
);


--
-- Name: mapper_sequence; Type: SEQUENCE; Schema: mapper; Owner: -
--

CREATE SEQUENCE mapper_sequence
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: host; Type: TABLE; Schema: mapper; Owner: -
--

CREATE TABLE host (
    id bigint DEFAULT nextval('mapper_sequence'::regclass) NOT NULL,
    host_name character varying(512) NOT NULL,
    preferred boolean DEFAULT false NOT NULL
);


--
-- Name: identifier; Type: TABLE; Schema: mapper; Owner: -
--

CREATE TABLE identifier (
    id bigint DEFAULT nextval('mapper_sequence'::regclass) NOT NULL,
    id_number bigint NOT NULL,
    name_space character varying(255) NOT NULL,
    object_type character varying(255) NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    reason_deleted character varying(255),
    updated_at timestamp with time zone,
    updated_by character varying(255),
    preferred_uri_id bigint
);


--
-- Name: identifier_identities; Type: TABLE; Schema: mapper; Owner: -
--

CREATE TABLE identifier_identities (
    match_id bigint NOT NULL,
    identifier_id bigint NOT NULL
);


--
-- Name: match; Type: TABLE; Schema: mapper; Owner: -
--

CREATE TABLE match (
    id bigint DEFAULT nextval('mapper_sequence'::regclass) NOT NULL,
    uri character varying(255) NOT NULL,
    deprecated boolean DEFAULT false NOT NULL,
    updated_at timestamp with time zone,
    updated_by character varying(255)
);


--
-- Name: match_host; Type: TABLE; Schema: mapper; Owner: -
--

CREATE TABLE match_host (
    match_hosts_id bigint,
    host_id bigint
);


SET search_path = public, pg_catalog;

--
-- Name: hibernate_sequence; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE hibernate_sequence
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: nsl_global_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE nsl_global_seq
    START WITH 1000
    INCREMENT BY 1
    MINVALUE 1000
    MAXVALUE 100000000000
    CACHE 1;


--
-- Name: instance; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE instance (
    id bigint DEFAULT nextval('nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    bhl_url character varying(4000),
    cited_by_id bigint,
    cites_id bigint,
    created_at timestamp with time zone NOT NULL,
    created_by character varying(50) NOT NULL,
    draft boolean DEFAULT false NOT NULL,
    instance_type_id bigint NOT NULL,
    name_id bigint NOT NULL,
    namespace_id bigint NOT NULL,
    nomenclatural_status character varying(50),
    page character varying(255),
    page_qualifier character varying(255),
    parent_id bigint,
    reference_id bigint NOT NULL,
    source_id bigint,
    source_id_string character varying(100),
    source_system character varying(50),
    trash boolean DEFAULT false NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    updated_by character varying(1000) NOT NULL,
    valid_record boolean DEFAULT false NOT NULL,
    verbatim_name_string character varying(255),
    CONSTRAINT citescheck CHECK (((cites_id IS NULL) OR (cited_by_id IS NOT NULL)))
);


--
-- Name: name; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE name (
    id bigint DEFAULT nextval('nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    author_id bigint,
    base_author_id bigint,
    created_at timestamp with time zone NOT NULL,
    created_by character varying(50) NOT NULL,
    duplicate_of_id bigint,
    ex_author_id bigint,
    ex_base_author_id bigint,
    full_name character varying(512),
    full_name_html character varying(2048),
    name_element character varying(255),
    name_rank_id bigint NOT NULL,
    name_status_id bigint NOT NULL,
    name_type_id bigint NOT NULL,
    namespace_id bigint NOT NULL,
    orth_var boolean DEFAULT false NOT NULL,
    parent_id bigint,
    sanctioning_author_id bigint,
    second_parent_id bigint,
    simple_name character varying(250),
    simple_name_html character varying(2048),
    source_dup_of_id bigint,
    source_id bigint,
    source_id_string character varying(100),
    source_system character varying(50),
    status_summary character varying(50),
    trash boolean DEFAULT false NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    updated_by character varying(50) NOT NULL,
    valid_record boolean DEFAULT false NOT NULL,
    why_is_this_here_id bigint,
    verbatim_rank character varying(50),
    sort_name character varying(250)
);


--
-- Name: shard_config; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE shard_config (
    id bigint DEFAULT nextval('hibernate_sequence'::regclass) NOT NULL,
    name character varying(255) NOT NULL,
    value character varying(5000) NOT NULL
);


--
-- Name: tree_arrangement; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tree_arrangement (
    id bigint DEFAULT nextval('nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    tree_type bpchar NOT NULL,
    description character varying(255),
    label character varying(50),
    node_id bigint,
    is_synthetic bpchar NOT NULL,
    title character varying(50),
    namespace_id bigint,
    owner character varying(255),
    shared boolean DEFAULT true,
    base_arrangement_id bigint,
    CONSTRAINT chk_classification_has_label CHECK (((tree_type <> ALL (ARRAY['E'::bpchar, 'P'::bpchar])) OR (label IS NOT NULL))),
    CONSTRAINT chk_tree_arrangement_type CHECK ((tree_type = ANY (ARRAY['E'::bpchar, 'P'::bpchar, 'U'::bpchar, 'Z'::bpchar]))),
    CONSTRAINT chk_work_trees_have_base_trees CHECK (((tree_type <> 'U'::bpchar) OR (base_arrangement_id IS NOT NULL)))
);


--
-- Name: tree_node; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tree_node (
    id bigint DEFAULT nextval('nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    checked_in_at_id bigint,
    internal_type character varying(255) NOT NULL,
    literal character varying(4096),
    name_uri_id_part character varying(255),
    name_uri_ns_part_id bigint,
    next_node_id bigint,
    prev_node_id bigint,
    replaced_at_id bigint,
    resource_uri_id_part character varying(255),
    resource_uri_ns_part_id bigint,
    tree_arrangement_id bigint,
    is_synthetic bpchar NOT NULL,
    taxon_uri_id_part character varying(255),
    taxon_uri_ns_part_id bigint,
    type_uri_id_part character varying(255),
    type_uri_ns_part_id bigint NOT NULL,
    name_id bigint,
    instance_id bigint,
    CONSTRAINT chk_arrangement_synthetic_yn CHECK ((is_synthetic = ANY (ARRAY['N'::bpchar, 'Y'::bpchar]))),
    CONSTRAINT chk_internal_type_d CHECK ((((internal_type)::text <> 'D'::text) OR ((name_uri_ns_part_id IS NULL) AND (taxon_uri_ns_part_id IS NULL) AND (literal IS NULL)))),
    CONSTRAINT chk_internal_type_enum CHECK (((internal_type)::text = ANY (ARRAY[('S'::character varying)::text, ('Z'::character varying)::text, ('T'::character varying)::text, ('D'::character varying)::text, ('V'::character varying)::text]))),
    CONSTRAINT chk_internal_type_s CHECK ((((internal_type)::text <> 'S'::text) OR ((name_uri_ns_part_id IS NULL) AND (taxon_uri_ns_part_id IS NULL) AND (resource_uri_ns_part_id IS NULL) AND (literal IS NULL)))),
    CONSTRAINT chk_internal_type_t CHECK ((((internal_type)::text <> 'T'::text) OR (literal IS NULL))),
    CONSTRAINT chk_internal_type_v CHECK ((((internal_type)::text <> 'V'::text) OR ((name_uri_ns_part_id IS NULL) AND (taxon_uri_ns_part_id IS NULL) AND (((resource_uri_ns_part_id IS NOT NULL) AND (literal IS NULL)) OR ((resource_uri_ns_part_id IS NULL) AND (literal IS NOT NULL)))))),
    CONSTRAINT chk_tree_node_instance_matches CHECK (((instance_id IS NULL) OR (((instance_id)::character varying)::text = (taxon_uri_id_part)::text))),
    CONSTRAINT chk_tree_node_name_matches CHECK (((name_id IS NULL) OR (((name_id)::character varying)::text = (name_uri_id_part)::text))),
    CONSTRAINT chk_tree_node_synthetic_yn CHECK ((is_synthetic = ANY (ARRAY['N'::bpchar, 'Y'::bpchar])))
);


--
-- Name: accepted_name_vw; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW accepted_name_vw AS
 SELECT accepted.id,
    accepted.simple_name,
    accepted.full_name,
    accepted.full_name_html,
    tree_node.type_uri_id_part AS type_code,
    instance.id AS instance_id,
    tree_node.id AS tree_node_id,
    0 AS accepted_id,
    ''::character varying AS accepted_full_name,
    accepted.name_status_id,
    instance.reference_id,
    accepted.name_rank_id,
    accepted.sort_name,
    0 AS synonym_type_id,
    0 AS synonym_ref_id,
    0 AS citer_instance_id,
    0 AS cites_instance_id,
    ''::character varying AS cites_instance_type_name,
    false AS cites_misapplied,
    0 AS citer_ref_year,
    0 AS cites_cites_id,
    0 AS cites_cites_ref_id,
    0 AS cites_cites_ref_year
   FROM (((name accepted
     JOIN instance ON ((accepted.id = instance.name_id)))
     JOIN tree_node ON ((accepted.id = tree_node.name_id)))
     JOIN tree_arrangement ta ON ((tree_node.tree_arrangement_id = ta.id)))
  WHERE (((ta.label)::text = (( SELECT shard_config.value
           FROM shard_config
          WHERE ((shard_config.name)::text = 'tree label'::text)))::text) AND (tree_node.next_node_id IS NULL) AND (tree_node.checked_in_at_id IS NOT NULL) AND (instance.id = tree_node.instance_id));


--
-- Name: instance_type; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE instance_type (
    id bigint DEFAULT nextval('nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    citing boolean DEFAULT false NOT NULL,
    deprecated boolean DEFAULT false NOT NULL,
    doubtful boolean DEFAULT false NOT NULL,
    misapplied boolean DEFAULT false NOT NULL,
    name character varying(255) NOT NULL,
    nomenclatural boolean DEFAULT false NOT NULL,
    primary_instance boolean DEFAULT false NOT NULL,
    pro_parte boolean DEFAULT false NOT NULL,
    protologue boolean DEFAULT false NOT NULL,
    relationship boolean DEFAULT false NOT NULL,
    secondary_instance boolean DEFAULT false NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL,
    standalone boolean DEFAULT false NOT NULL,
    synonym boolean DEFAULT false NOT NULL,
    taxonomic boolean DEFAULT false NOT NULL,
    unsourced boolean DEFAULT false NOT NULL,
    description_html text,
    rdf_id character varying(50),
    has_label character varying(255) DEFAULT 'not set'::character varying NOT NULL,
    of_label character varying(255) DEFAULT 'not set'::character varying NOT NULL,
    bidirectional boolean DEFAULT false NOT NULL
);


--
-- Name: reference; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE reference (
    id bigint DEFAULT nextval('nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    abbrev_title character varying(2000),
    author_id bigint NOT NULL,
    bhl_url character varying(4000),
    citation character varying(4000),
    citation_html character varying(4000),
    created_at timestamp with time zone NOT NULL,
    created_by character varying(255) NOT NULL,
    display_title character varying(2000) NOT NULL,
    doi character varying(255),
    duplicate_of_id bigint,
    edition character varying(100),
    isbn character varying(16),
    issn character varying(16),
    language_id bigint NOT NULL,
    namespace_id bigint NOT NULL,
    notes character varying(1000),
    pages character varying(1000),
    parent_id bigint,
    publication_date character varying(50),
    published boolean DEFAULT false NOT NULL,
    published_location character varying(1000),
    publisher character varying(1000),
    ref_author_role_id bigint NOT NULL,
    ref_type_id bigint NOT NULL,
    source_id bigint,
    source_id_string character varying(100),
    source_system character varying(50),
    title character varying(2000) NOT NULL,
    tl2 character varying(30),
    trash boolean DEFAULT false NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    updated_by character varying(1000) NOT NULL,
    valid_record boolean DEFAULT false NOT NULL,
    verbatim_author character varying(1000),
    verbatim_citation character varying(2000),
    verbatim_reference character varying(1000),
    volume character varying(100),
    year integer
);


--
-- Name: accepted_synonym_vw; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW accepted_synonym_vw AS
 SELECT name_as_syn.id,
    name_as_syn.simple_name,
    name_as_syn.full_name,
    name_as_syn.full_name_html,
    'synonym'::character varying AS type_code,
    citer.id AS instance_id,
    tree_node.id AS tree_node_id,
    citer_name.id AS accepted_id,
    citer_name.full_name AS accepted_full_name,
    name_as_syn.name_status_id,
    0 AS reference_id,
    name_as_syn.name_rank_id,
    name_as_syn.sort_name,
    cites.instance_type_id AS synonym_type_id,
    cites.reference_id AS synonym_ref_id,
    citer.id AS citer_instance_id,
    cites.id AS cites_instance_id,
    cites_instance_type.name AS cites_instance_type_name,
    cites_instance_type.misapplied AS cites_misapplied,
    citer_ref.year AS citer_ref_year,
    cites_cites.id AS cites_cites_id,
    cites_cites.reference_id AS cites_cites_ref_id,
    cites_cites_ref.year AS cites_cites_ref_year
   FROM ((((((((((name name_as_syn
     JOIN instance cites ON ((name_as_syn.id = cites.name_id)))
     JOIN instance_type cites_instance_type ON ((cites.instance_type_id = cites_instance_type.id)))
     JOIN reference cites_ref ON ((cites.reference_id = cites_ref.id)))
     JOIN instance citer ON ((cites.cited_by_id = citer.id)))
     JOIN reference citer_ref ON ((citer.reference_id = citer_ref.id)))
     JOIN name citer_name ON ((citer.name_id = citer_name.id)))
     JOIN tree_node ON ((citer_name.id = tree_node.name_id)))
     JOIN tree_arrangement ta ON ((tree_node.tree_arrangement_id = ta.id)))
     JOIN instance cites_cites ON ((cites.cites_id = cites_cites.id)))
     JOIN reference cites_cites_ref ON ((cites_cites.reference_id = cites_cites_ref.id)))
  WHERE (((ta.label)::text = (( SELECT shard_config.value
           FROM shard_config
          WHERE ((shard_config.name)::text = 'tree label'::text)))::text) AND (tree_node.next_node_id IS NULL) AND (tree_node.checked_in_at_id IS NOT NULL) AND (tree_node.instance_id = citer.id));


--
-- Name: author; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE author (
    id bigint DEFAULT nextval('nsl_global_seq'::regclass) NOT NULL,
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
    trash boolean DEFAULT false NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    updated_by character varying(255) NOT NULL,
    valid_record boolean DEFAULT false NOT NULL
);


--
-- Name: comment; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE comment (
    id bigint DEFAULT nextval('hibernate_sequence'::regclass) NOT NULL,
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
-- Name: db_version; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE db_version (
    id bigint NOT NULL,
    version integer NOT NULL
);


--
-- Name: delayed_jobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE delayed_jobs (
    id bigint DEFAULT nextval('nsl_global_seq'::regclass) NOT NULL,
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
-- Name: distribution; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE distribution (
    region text
);


--
-- Name: external_ref; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE external_ref (
    id bigint DEFAULT nextval('nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    external_id character varying(50) NOT NULL,
    external_id_supplier character varying(50) NOT NULL,
    instance_id bigint NOT NULL,
    name_id bigint NOT NULL,
    object_type character varying(50),
    original_provider numeric(19,2),
    reference_id bigint NOT NULL
);


--
-- Name: help_topic; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE help_topic (
    id bigint DEFAULT nextval('nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    created_at timestamp without time zone NOT NULL,
    created_by character varying(4000) NOT NULL,
    marked_up_text text NOT NULL,
    name character varying(4000) NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL,
    trash boolean DEFAULT false NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    updated_by character varying(4000) NOT NULL
);


--
-- Name: id_mapper; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE id_mapper (
    id bigint NOT NULL,
    from_id bigint NOT NULL,
    namespace_id bigint NOT NULL,
    system character varying(20) NOT NULL,
    to_id bigint
);


--
-- Name: instance_note; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE instance_note (
    id bigint DEFAULT nextval('nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    created_at timestamp with time zone NOT NULL,
    created_by character varying(50) NOT NULL,
    instance_id bigint NOT NULL,
    instance_note_key_id bigint NOT NULL,
    namespace_id bigint NOT NULL,
    source_id bigint,
    source_id_string character varying(100),
    source_system character varying(50),
    trash boolean DEFAULT false NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    updated_by character varying(50) NOT NULL,
    value character varying(4000) NOT NULL
);


--
-- Name: instance_note_key; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE instance_note_key (
    id bigint DEFAULT nextval('nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    deprecated boolean DEFAULT false NOT NULL,
    name character varying(255) NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL,
    description_html text,
    rdf_id character varying(50)
);


--
-- Name: language; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE language (
    id bigint DEFAULT nextval('nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    iso6391code character varying(2),
    iso6393code character varying(3) NOT NULL,
    name character varying(50) NOT NULL
);


--
-- Name: locale; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE locale (
    id bigint DEFAULT nextval('nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    locale_name_string character varying(50) NOT NULL
);


--
-- Name: name_category; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE name_category (
    id bigint DEFAULT nextval('nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    name character varying(50) NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL,
    description_html text,
    rdf_id character varying(50)
);


--
-- Name: name_status; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE name_status (
    id bigint DEFAULT nextval('nsl_global_seq'::regclass) NOT NULL,
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

CREATE VIEW name_detail_commons_vw AS
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
   FROM (((instance
     JOIN name ON ((instance.name_id = name.id)))
     JOIN instance_type ity ON ((ity.id = instance.instance_type_id)))
     JOIN name_status ns ON ((ns.id = name.name_status_id)))
  WHERE ((ity.name)::text = ANY (ARRAY[('common name'::character varying)::text, ('vernacular name'::character varying)::text]));


--
-- Name: name_detail_synonyms_vw; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW name_detail_synonyms_vw AS
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
   FROM (((instance
     JOIN name ON ((instance.name_id = name.id)))
     JOIN instance_type ity ON ((ity.id = instance.instance_type_id)))
     JOIN name_status ns ON ((ns.id = name.name_status_id)))
  WHERE ((ity.name)::text <> ALL (ARRAY[('common name'::character varying)::text, ('vernacular name'::character varying)::text]));


--
-- Name: name_rank; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE name_rank (
    id bigint DEFAULT nextval('nsl_global_seq'::regclass) NOT NULL,
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
    rdf_id character varying(50)
);


--
-- Name: name_type; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE name_type (
    id bigint DEFAULT nextval('nsl_global_seq'::regclass) NOT NULL,
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

CREATE VIEW name_details_vw AS
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
   FROM ((((((((((name n
     JOIN name_status s ON ((n.name_status_id = s.id)))
     JOIN name_rank r ON ((n.name_rank_id = r.id)))
     JOIN name_type t ON ((n.name_type_id = t.id)))
     JOIN instance i ON ((n.id = i.name_id)))
     JOIN instance_type ity ON ((i.instance_type_id = ity.id)))
     JOIN reference ref ON ((i.reference_id = ref.id)))
     LEFT JOIN author ON ((ref.author_id = author.id)))
     LEFT JOIN instance syn ON ((syn.cited_by_id = i.id)))
     LEFT JOIN instance_type sty ON ((syn.instance_type_id = sty.id)))
     LEFT JOIN name sname ON ((syn.name_id = sname.id)))
  WHERE (n.duplicate_of_id IS NULL);


--
-- Name: name_group; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE name_group (
    id bigint DEFAULT nextval('nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    name character varying(50),
    description_html text,
    rdf_id character varying(50)
);


--
-- Name: name_or_synonym_vw; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW name_or_synonym_vw AS
 SELECT 0 AS id,
    ''::character varying AS simple_name,
    ''::character varying AS full_name,
    ''::character varying AS type_code,
    0 AS instance_id,
    0 AS tree_node_id,
    0 AS accepted_id,
    ''::character varying AS accepted_full_name,
    0 AS name_status_id,
    0 AS reference_id,
    0 AS name_rank_id,
    ''::character varying AS sort_name
   FROM name
  WHERE (1 = 0);


--
-- Name: name_part; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE name_part (
    id bigint DEFAULT nextval('nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    name_id bigint NOT NULL,
    preceding_name_id bigint NOT NULL,
    preceding_name_type character varying(50) NOT NULL
);


--
-- Name: name_tag; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE name_tag (
    id bigint DEFAULT nextval('nsl_global_seq'::regclass) NOT NULL,
    name character varying(255) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL
);


--
-- Name: name_tag_name; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE name_tag_name (
    name_id bigint NOT NULL,
    tag_id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    created_by character varying(255) NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    updated_by character varying(255) NOT NULL
);


--
-- Name: name_tree_path; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE name_tree_path (
    id bigint DEFAULT nextval('hibernate_sequence'::regclass) NOT NULL,
    version bigint NOT NULL,
    inserted bigint NOT NULL,
    name_id bigint NOT NULL,
    name_id_path text NOT NULL,
    name_path text NOT NULL,
    next_id bigint,
    parent_id bigint,
    rank_path text NOT NULL,
    tree_id bigint NOT NULL,
    family_id bigint
);


--
-- Name: name_view; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW name_view AS
 SELECT 'ICNAFP'::text AS "nomenclaturalCode",
    'APNI'::text AS "datasetName",
    nt.name AS "nameType",
        CASE
            WHEN (apc_inst.id IS NULL) THEN (( SELECT (('[unplaced '::text ||
                    CASE
                        WHEN (i.cited_by_id IS NULL) THEN 'name'::text
                        ELSE 'relationship'::text
                    END) || '?]'::text)
               FROM (instance i
                 JOIN reference r ON ((r.id = i.reference_id)))
              WHERE (i.name_id = n.id)
              ORDER BY r.year DESC
             LIMIT 1))::character varying
            ELSE
            CASE
                WHEN (apc_inst.id = apcn.instance_id) THEN apcn.type_uri_id_part
                ELSE apc_inst_type.name
            END
        END AS "taxonomicStatus",
    ('http://id.biodiversity.org.au/name/apni/'::text || n.id) AS "scientificNameID",
    n.full_name AS "scientificName",
        CASE
            WHEN ((ns.name)::text <> ALL (ARRAY[('legitimate'::character varying)::text, ('[default]'::character varying)::text])) THEN ns.name
            ELSE NULL::character varying
        END AS "nomenclaturalStatus",
    n.simple_name AS "canonicalName",
        CASE
            WHEN nt.autonym THEN NULL::text
            ELSE regexp_replace("substring"((n.full_name_html)::text, '<authors>(.*)</authors>'::text), '<[^>]*>'::text, ''::text, 'g'::text)
        END AS "scientificNameAuthorship",
    'http://creativecommons.org/licenses/by/3.0/'::text AS "ccLicense",
    ('http://id.biodiversity.org.au/name/apni/'::text || n.id) AS "ccAttributionIRI",
        CASE
            WHEN (nt.cultivar = true) THEN n.name_element
            ELSE NULL::character varying
        END AS "cultivarEpithet",
    n.simple_name_html AS "canonicalNameHTML",
    n.full_name_html AS "scientificNameHTML",
    nt.autonym,
    nt.hybrid,
    nt.cultivar,
    nt.formula,
    nt.scientific,
    ns.nom_inval AS "nomInval",
    ns.nom_illeg AS "nomIlleg",
    pro_ref.citation AS "namePublishedIn",
    pro_ref.year AS "namePublishedInYear",
    pit.name AS "nameInstanceType",
    bnm.full_name AS "originalNameUsage",
        CASE
            WHEN (bin.id IS NOT NULL) THEN ('http://id.biodiversity.org.au/instance/apni/'::text || bin.id)
            ELSE
            CASE
                WHEN (pro.id IS NOT NULL) THEN ('http://id.biodiversity.org.au/instance/apni/'::text || pro.id)
                ELSE NULL::text
            END
        END AS "originalNameUsageID",
    ( SELECT string_agg(regexp_replace((nt_1.value)::text, '[\n\r\u2028]+'::text, ' '::text, 'g'::text), ' '::text) AS string_agg
           FROM (instance_note nt_1
             JOIN instance_note_key key1 ON (((key1.id = nt_1.instance_note_key_id) AND ((key1.name)::text = 'Type'::text))))
          WHERE (nt_1.instance_id = apcn.instance_id)) AS "typeCitation",
    rank.name AS "taxonRank",
    rank.sort_order AS "taxonRankSortOrder",
    rank.abbrev AS "taxonRankAbbreviation",
    "substring"(ntp.rank_path, 'Regnum:([^>]*)'::text) AS kingdom,
    "substring"(ntp.rank_path, 'Classis:([^>]*)'::text) AS class,
    "substring"(ntp.rank_path, 'Subclassis:([^>]*)'::text) AS subclass,
    "substring"(ntp.rank_path, 'Familia:([^>]*)'::text) AS family,
    "substring"(ntp.rank_path, 'Genus:([^>]*)'::text) AS "genericName",
    "substring"(ntp.rank_path, 'Species:([^>]*)'::text) AS "specificEpithet",
    "substring"(ntp.rank_path, 'Species:[^>]*>.*:(.*)\\$'::text) AS "infraspecificEpithet",
    n.created_at AS created,
    n.updated_at AS modified,
    n.name_element AS "nameElement",
        CASE
            WHEN (firsthybridparent.id IS NOT NULL) THEN firsthybridparent.full_name
            ELSE NULL::character varying
        END AS "firstHybridParentName",
        CASE
            WHEN (firsthybridparent.id IS NOT NULL) THEN ('http://id.biodiversity.org.au/name/apni/'::text || firsthybridparent.id)
            ELSE NULL::text
        END AS "firstHybridParentNameID",
        CASE
            WHEN (secondhybridparent.id IS NOT NULL) THEN secondhybridparent.full_name
            ELSE NULL::character varying
        END AS "secondHybridParentName",
        CASE
            WHEN (secondhybridparent.id IS NOT NULL) THEN ('http://id.biodiversity.org.au/name/apni/'::text || secondhybridparent.id)
            ELSE NULL::text
        END AS "secondHybridParentNameID"
   FROM (((((((((((((name n
     JOIN name_type nt ON ((n.name_type_id = nt.id)))
     JOIN name_status ns ON ((n.name_status_id = ns.id)))
     JOIN name_rank rank ON ((n.name_rank_id = rank.id)))
     LEFT JOIN author combination_author ON ((combination_author.id = n.author_id)))
     LEFT JOIN author basionym_author ON ((n.base_author_id = basionym_author.id)))
     LEFT JOIN author ex_basionym_author ON ((n.ex_base_author_id = ex_basionym_author.id)))
     LEFT JOIN author ex_combination_author ON ((n.ex_author_id = ex_combination_author.id)))
     LEFT JOIN author sanctioning_work ON ((n.sanctioning_author_id = sanctioning_work.id)))
     LEFT JOIN ((instance pro
     JOIN instance_type pit ON (((pit.id = pro.instance_type_id) AND (pit.primary_instance = true))))
     JOIN reference pro_ref ON ((pro.reference_id = pro_ref.id))) ON ((pro.name_id = n.id)))
     LEFT JOIN ((instance bin
     JOIN instance_type "bit" ON ((("bit".id = bin.instance_type_id) AND (("bit".name)::text = 'basionym'::text))))
     JOIN name bnm ON ((bnm.id = bin.name_id))) ON ((bin.id = pro.cites_id)))
     LEFT JOIN (((instance apc_inst
     JOIN instance_type apc_inst_type ON ((apc_inst.instance_type_id = apc_inst_type.id)))
     JOIN reference apc_ref ON ((apc_ref.id = apc_inst.reference_id)))
     JOIN ((tree_node apcn
     JOIN tree_arrangement tree ON (((tree.id = apcn.tree_arrangement_id) AND ((tree.label)::text = 'APC'::text))))
     JOIN name_tree_path ntp ON (((ntp.name_id = apcn.name_id) AND (ntp.tree_id = tree.id)))) ON ((((apcn.instance_id = apc_inst.id) OR (apcn.instance_id = apc_inst.cited_by_id)) AND (apcn.checked_in_at_id IS NOT NULL) AND (apcn.next_node_id IS NULL) AND ((apcn.type_uri_id_part)::text <> 'DeclaredBt'::text)))) ON ((apc_inst.name_id = n.id)))
     LEFT JOIN name firsthybridparent ON (((n.parent_id = firsthybridparent.id) AND nt.hybrid)))
     LEFT JOIN name secondhybridparent ON (((n.second_parent_id = secondhybridparent.id) AND nt.hybrid)))
  WHERE ((EXISTS ( SELECT 1
           FROM instance
          WHERE (instance.name_id = n.id))) AND (n.duplicate_of_id IS NULL))
  WITH NO DATA;


--
-- Name: namespace; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE namespace (
    id bigint DEFAULT nextval('nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    name character varying(255) NOT NULL,
    description_html text,
    rdf_id character varying(50)
);


--
-- Name: nomenclatural_event_type; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE nomenclatural_event_type (
    id bigint DEFAULT nextval('nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    name_group_id bigint NOT NULL,
    nomenclatural_event_type character varying(50),
    description_html text,
    rdf_id character varying(50)
);


--
-- Name: notification; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE notification (
    id bigint NOT NULL,
    version bigint NOT NULL,
    message character varying(255) NOT NULL,
    object_id bigint
);


--
-- Name: nsl_simple_name_export; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE nsl_simple_name_export (
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
-- Name: ref_author_role; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE ref_author_role (
    id bigint DEFAULT nextval('nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    name character varying(255) NOT NULL,
    description_html text,
    rdf_id character varying(50)
);


--
-- Name: ref_type; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE ref_type (
    id bigint DEFAULT nextval('nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    name character varying(50) NOT NULL,
    parent_id bigint,
    parent_optional boolean DEFAULT false NOT NULL,
    description_html text,
    rdf_id character varying(50),
    use_parent_details boolean DEFAULT false NOT NULL
);


--
-- Name: tree_link; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tree_link (
    id bigint DEFAULT nextval('nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    link_seq integer NOT NULL,
    subnode_id bigint NOT NULL,
    supernode_id bigint NOT NULL,
    is_synthetic bpchar NOT NULL,
    type_uri_id_part character varying(255),
    type_uri_ns_part_id bigint NOT NULL,
    versioning_method bpchar NOT NULL,
    CONSTRAINT chk_tree_link_seq_positive CHECK ((link_seq >= 1)),
    CONSTRAINT chk_tree_link_sub_not_end CHECK ((subnode_id <> 0)),
    CONSTRAINT chk_tree_link_sup_not_end CHECK ((supernode_id <> 0)),
    CONSTRAINT chk_tree_link_synthetic_yn CHECK ((is_synthetic = ANY (ARRAY['N'::bpchar, 'Y'::bpchar]))),
    CONSTRAINT chk_tree_link_vmethod CHECK ((versioning_method = ANY (ARRAY['F'::bpchar, 'V'::bpchar, 'T'::bpchar])))
);


--
-- Name: taxon_view; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW taxon_view AS
 SELECT 'ICNAFP'::text AS "nomenclaturalCode",
        CASE
            WHEN (apcn.id IS NOT NULL) THEN
            CASE
                WHEN (apc_cited_inst.id IS NOT NULL) THEN ('http://id.biodiversity.org.au/instance/apni/'::text || apc_inst.id)
                ELSE ('http://id.biodiversity.org.au/node/apni/'::text || apcn.id)
            END
            ELSE NULL::text
        END AS "taxonID",
    nt.name AS "nameType",
    ('http://id.biodiversity.org.au/name/apni/'::text || n.id) AS "scientificNameID",
    n.full_name AS "scientificName",
        CASE
            WHEN ((ns.name)::text <> ALL (ARRAY[('legitimate'::character varying)::text, ('[default]'::character varying)::text])) THEN ns.name
            ELSE NULL::character varying
        END AS "nomenclaturalStatus",
        CASE
            WHEN (apc_inst.id = apcn.instance_id) THEN apcn.type_uri_id_part
            ELSE apc_inst_type.name
        END AS "taxonomicStatus",
    apc_inst_type.pro_parte AS "proParte",
        CASE
            WHEN (apc_inst.id <> apcn.instance_id) THEN accepted_name.full_name
            ELSE NULL::character varying
        END AS "acceptedNameUsage",
        CASE
            WHEN (apcn.instance_id IS NOT NULL) THEN ('http://id.biodiversity.org.au/node/apni/'::text || apcn.id)
            ELSE NULL::text
        END AS "acceptedNameUsageID",
        CASE
            WHEN ((apc_inst.id = apcn.instance_id) AND (apcp.id IS NOT NULL)) THEN
            CASE
                WHEN ((apcp.type_uri_id_part)::text = 'classification-root'::text) THEN '[APC]'::text
                ELSE ('http://id.biodiversity.org.au/node/apni/'::text || apcp.id)
            END
            ELSE NULL::text
        END AS "parentNameUsageID",
    rank.name AS "taxonRank",
    rank.sort_order AS "taxonRankSortOrder",
    "substring"(ntp.rank_path, 'Regnum:([^>]*)'::text) AS kingdom,
    "substring"(ntp.rank_path, 'Classis:([^>]*)'::text) AS class,
    "substring"(ntp.rank_path, 'Subclassis:([^>]*)'::text) AS subclass,
    "substring"(ntp.rank_path, 'Familia:([^>]*)'::text) AS family,
    n.created_at AS created,
    n.updated_at AS modified,
    ARRAY( SELECT t2.label
           FROM (name_tree_path ntp2
             JOIN tree_arrangement t2 ON ((ntp2.tree_id = t2.id)))
          WHERE (ntp2.name_id = n.id)
          ORDER BY t2.label) AS "datasetName",
        CASE
            WHEN (apc_cited_inst.id IS NOT NULL) THEN ('http://id.biodiversity.org.au/instance/apni/'::text || apc_inst.cites_id)
            ELSE ('http://id.biodiversity.org.au/instance/apni/'::text || apc_inst.id)
        END AS "taxonConceptID",
        CASE
            WHEN (apcr.citation IS NOT NULL) THEN ('http://id.biodiversity.org.au/reference/apni/'::text || apcr.id)
            ELSE ('http://id.biodiversity.org.au/reference/apni/'::text || apc_inst.reference_id)
        END AS "nameAccordingToID",
        CASE
            WHEN (apcr.citation IS NOT NULL) THEN apcr.citation
            ELSE apc_ref.citation
        END AS "nameAccordingTo",
    ( SELECT string_agg(regexp_replace((nt_1.value)::text, '[\n\r\u2028]+'::text, ' '::text, 'g'::text), ' '::text) AS string_agg
           FROM (instance_note nt_1
             JOIN instance_note_key key1 ON (((key1.id = nt_1.instance_note_key_id) AND ((key1.name)::text = 'APC Comment'::text))))
          WHERE (nt_1.instance_id = apcn.instance_id)) AS "taxonRemarks",
    ( SELECT string_agg(regexp_replace((nt_1.value)::text, '[\n\r\u2028]+'::text, ' '::text, 'g'::text), ' '::text) AS string_agg
           FROM (instance_note nt_1
             JOIN instance_note_key key1 ON (((key1.id = nt_1.instance_note_key_id) AND ((key1.name)::text = 'APC Dist.'::text))))
          WHERE (nt_1.instance_id = apcn.instance_id)) AS "taxonDistribution",
        CASE
            WHEN (apc_inst.id = apcn.instance_id) THEN regexp_replace(ntp.name_path, '\.'::text, '|'::text, 'g'::text)
            ELSE NULL::text
        END AS "higherClassification",
    'http://creativecommons.org/licenses/by/3.0/'::text AS "ccLicense",
        CASE
            WHEN (apcn.id IS NOT NULL) THEN
            CASE
                WHEN (apc_cited_inst.id IS NOT NULL) THEN ('http://id.biodiversity.org.au/instance/apni/'::text || apc_inst.id)
                ELSE ('http://id.biodiversity.org.au/node/apni/'::text || apcn.id)
            END
            ELSE NULL::text
        END AS "ccAttributionIRI ",
    n.simple_name AS "canonicalName",
        CASE
            WHEN nt.autonym THEN NULL::text
            ELSE regexp_replace("substring"((n.full_name_html)::text, '<authors>(.*)</authors>'::text), '<[^>]*>'::text, ''::text, 'g'::text)
        END AS "scientificNameAuthorship",
        CASE
            WHEN (firsthybridparent.id IS NOT NULL) THEN firsthybridparent.full_name
            ELSE NULL::character varying
        END AS "firstHybridParentName",
        CASE
            WHEN (firsthybridparent.id IS NOT NULL) THEN ('http://id.biodiversity.org.au/name/apni/'::text || firsthybridparent.id)
            ELSE NULL::text
        END AS "firstHybridParentNameID",
        CASE
            WHEN (secondhybridparent.id IS NOT NULL) THEN secondhybridparent.full_name
            ELSE NULL::character varying
        END AS "secondHybridParentName",
        CASE
            WHEN (secondhybridparent.id IS NOT NULL) THEN ('http://id.biodiversity.org.au/name/apni/'::text || secondhybridparent.id)
            ELSE NULL::text
        END AS "secondHybridParentNameID"
   FROM ((((((((((((((instance apc_inst
     JOIN instance_type apc_inst_type ON ((apc_inst.instance_type_id = apc_inst_type.id)))
     JOIN reference apc_ref ON ((apc_ref.id = apc_inst.reference_id)))
     JOIN (tree_node apcn
     JOIN tree_arrangement tree ON (((tree.id = apcn.tree_arrangement_id) AND ((tree.label)::text = 'APC'::text)))) ON ((((apcn.instance_id = apc_inst.id) OR (apcn.instance_id = apc_inst.cited_by_id)) AND (apcn.checked_in_at_id IS NOT NULL) AND (apcn.next_node_id IS NULL))))
     LEFT JOIN (tree_link
     JOIN tree_node apcp ON (((apcp.id = tree_link.supernode_id) AND (apcp.checked_in_at_id IS NOT NULL) AND (apcp.next_node_id IS NULL)))) ON ((apcn.id = tree_link.subnode_id)))
     LEFT JOIN instance apc_cited_inst ON ((apc_inst.cites_id = apc_cited_inst.id)))
     LEFT JOIN reference apcr ON ((apc_cited_inst.reference_id = apcr.id)))
     LEFT JOIN name_tree_path ntp ON (((ntp.name_id = apcn.name_id) AND (ntp.tree_id = tree.id))))
     LEFT JOIN name accepted_name ON ((accepted_name.id = apcn.name_id)))
     JOIN name n ON ((n.id = apc_inst.name_id)))
     JOIN name_type nt ON ((n.name_type_id = nt.id)))
     JOIN name_status ns ON ((n.name_status_id = ns.id)))
     JOIN name_rank rank ON ((n.name_rank_id = rank.id)))
     LEFT JOIN name firsthybridparent ON (((n.parent_id = firsthybridparent.id) AND nt.hybrid)))
     LEFT JOIN name secondhybridparent ON (((n.second_parent_id = secondhybridparent.id) AND nt.hybrid)))
  WITH NO DATA;


--
-- Name: tree_event; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tree_event (
    id bigint DEFAULT nextval('nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    auth_user character varying(255) NOT NULL,
    note character varying(255),
    time_stamp timestamp with time zone NOT NULL,
    namespace_id bigint
);


--
-- Name: tree_uri_ns; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tree_uri_ns (
    id bigint DEFAULT nextval('nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    description character varying(255),
    id_mapper_namespace_id bigint,
    id_mapper_system character varying(255),
    label character varying(20) NOT NULL,
    owner_uri_id_part character varying(255),
    owner_uri_ns_part_id bigint,
    title character varying(255),
    uri character varying(255)
);


--
-- Name: tree_value_uri; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tree_value_uri (
    id bigint DEFAULT nextval('nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    description character varying(2048),
    is_multi_valued boolean DEFAULT false NOT NULL,
    is_resource boolean DEFAULT false NOT NULL,
    label character varying(20) NOT NULL,
    link_uri_id_part character varying(255) NOT NULL,
    link_uri_ns_part_id bigint NOT NULL,
    node_uri_id_part character varying(255) NOT NULL,
    node_uri_ns_part_id bigint NOT NULL,
    root_id bigint NOT NULL,
    sort_order integer NOT NULL,
    title character varying(50) NOT NULL
);


--
-- Name: user_query; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE user_query (
    id bigint DEFAULT nextval('nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    created_at timestamp with time zone NOT NULL,
    query_completed boolean DEFAULT false NOT NULL,
    query_started boolean DEFAULT false NOT NULL,
    record_count numeric(19,2) NOT NULL,
    search_finished_at timestamp with time zone,
    search_info character varying(500),
    search_model character varying(4000),
    search_result text,
    search_started_at timestamp with time zone,
    search_terms character varying(4000),
    trash boolean DEFAULT false NOT NULL,
    updated_at timestamp with time zone NOT NULL
);


--
-- Name: why_is_this_here; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE why_is_this_here (
    id bigint DEFAULT nextval('nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    name character varying(50) NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL
);


--
-- Name: workspace_instance_value_vw; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW workspace_instance_value_vw AS
 SELECT workspace.id AS workspace_id,
    instance.id AS instance_id,
    tree_node.tree_arrangement_id,
    tree_node.id AS tree_node_id,
    tree_link.id AS tree_link_id,
    workspace.title AS workspace_title,
    tree_uri_ns.label AS tree_uri_ns_label,
    tree_link.type_uri_id_part AS tree_link_type_uri_id_part,
    base.label AS base_label,
    base_value.id AS base_value_uri_id,
    base_value.link_uri_ns_part_id AS base_link_uri_ns_part,
    link_value.link_uri_ns_part_id AS link_uri_ns_part,
    link_value.id AS link_value_uri_id,
    base_ns.title,
    tree_link.subnode_id,
    value_node.type_uri_id_part,
    link_value.link_uri_id_part,
    base_value.link_uri_id_part AS base_link_uri_id_part,
    value_node.literal
   FROM (((((((((instance
     JOIN tree_node ON ((instance.id = tree_node.instance_id)))
     JOIN tree_link ON ((tree_node.id = tree_link.supernode_id)))
     JOIN tree_value_uri link_value ON (((tree_link.type_uri_id_part)::text = (link_value.link_uri_id_part)::text)))
     JOIN tree_uri_ns ON ((tree_link.type_uri_ns_part_id = tree_uri_ns.id)))
     JOIN tree_arrangement workspace ON ((tree_node.tree_arrangement_id = workspace.id)))
     JOIN tree_arrangement base ON ((workspace.base_arrangement_id = base.id)))
     JOIN tree_value_uri base_value ON ((base.id = base_value.root_id)))
     JOIN tree_uri_ns base_ns ON ((base_value.node_uri_ns_part_id = base_ns.id)))
     JOIN tree_node value_node ON ((tree_link.subnode_id = value_node.id)))
  WHERE ((instance.id = 612278) AND ((link_value.link_uri_id_part)::text = (base_value.link_uri_id_part)::text));


--
-- Name: workspace_value_namespace_vw; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW workspace_value_namespace_vw AS
 SELECT workspace.id AS workspace_id,
    workspace.title AS workspace_title,
    base.label AS base_tree_label,
    value.label AS value_label,
    value.link_uri_id_part AS value_link_uri_id_part,
    value.node_uri_id_part AS value_node_uri_id_part,
    value.node_uri_ns_part_id AS "Value_node_uri_ns_part_id",
    value.title AS value_title,
    node_namespace.description AS node_namespace_description,
    node_namespace.id_mapper_namespace_id AS node_namespace_id_mapper_namespace_id,
    node_namespace.id_mapper_system AS node_namespace_id_mapper_system,
    node_namespace.label AS node_namespace_label,
    node_namespace.owner_uri_id_part AS node_namespace_owner_uri_id_part,
    node_namespace.owner_uri_ns_part_id AS node_namespace_owner_uri_ns_part_id,
    node_namespace.title AS node_namespace_title,
    node_namespace.uri AS node_namespace_uri,
    link_namespace.description AS link_namespace_description,
    link_namespace.id_mapper_namespace_id AS link_namespace_id_mapper_namespace_id,
    link_namespace.id_mapper_system AS link_namespace_id_mapper_system,
    link_namespace.label AS link_namespace_label,
    link_namespace.owner_uri_id_part AS link_namespace_owner_uri_id_part,
    link_namespace.owner_uri_ns_part_id AS link_namespace_owner_uri_ns_part_id,
    link_namespace.title AS link_namespace_title,
    link_namespace.uri AS link_namespace_uri
   FROM ((((tree_arrangement workspace
     JOIN tree_arrangement base ON ((workspace.base_arrangement_id = base.id)))
     JOIN tree_value_uri value ON ((base.id = value.root_id)))
     JOIN tree_uri_ns node_namespace ON ((value.node_uri_ns_part_id = node_namespace.id)))
     JOIN tree_uri_ns link_namespace ON ((value.link_uri_ns_part_id = link_namespace.id)));


--
-- Name: workspace_value_vw; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW workspace_value_vw AS
 SELECT name_node_link.id AS name_node_link_id,
    name_node.id AS name_node_id,
    instance.id AS instance_id,
    name_sub_link.type_uri_id_part,
    name_sub_link.type_uri_ns_part_id,
    workspace.id AS workspace_id,
    name_sub_link.type_uri_id_part AS name_sub_link_type_uri_id,
    name_sub_link_value.link_uri_id_part AS name_sub_link_value_link_uri_id_part,
    name_sub_link.type_uri_id_part AS field_name,
    value_node.literal,
    value_node.literal AS field_value,
    name_node.name_id,
    name_sub_link_value.label AS value_label,
    value_node.id AS value_node_id
   FROM ((((((tree_link name_node_link
     JOIN tree_node name_node ON ((name_node_link.subnode_id = name_node.id)))
     JOIN instance ON ((name_node.instance_id = instance.id)))
     JOIN tree_link name_sub_link ON ((name_node.id = name_sub_link.supernode_id)))
     JOIN tree_value_uri name_sub_link_value ON (((name_sub_link.type_uri_id_part)::text = (name_sub_link_value.link_uri_id_part)::text)))
     JOIN tree_arrangement workspace ON ((name_node.tree_arrangement_id = workspace.id)))
     JOIN tree_node value_node ON ((name_sub_link.subnode_id = value_node.id)));


SET search_path = audit, pg_catalog;

--
-- Name: event_id; Type: DEFAULT; Schema: audit; Owner: -
--

ALTER TABLE ONLY logged_actions ALTER COLUMN event_id SET DEFAULT nextval('logged_actions_event_id_seq'::regclass);


--
-- Name: logged_actions_pkey; Type: CONSTRAINT; Schema: audit; Owner: -
--

ALTER TABLE ONLY logged_actions
    ADD CONSTRAINT logged_actions_pkey PRIMARY KEY (event_id);


SET search_path = mapper, pg_catalog;

--
-- Name: db_version_pkey; Type: CONSTRAINT; Schema: mapper; Owner: -
--

ALTER TABLE ONLY db_version
    ADD CONSTRAINT db_version_pkey PRIMARY KEY (id);


--
-- Name: host_pkey; Type: CONSTRAINT; Schema: mapper; Owner: -
--

ALTER TABLE ONLY host
    ADD CONSTRAINT host_pkey PRIMARY KEY (id);


--
-- Name: identifier_identities_pkey; Type: CONSTRAINT; Schema: mapper; Owner: -
--

ALTER TABLE ONLY identifier_identities
    ADD CONSTRAINT identifier_identities_pkey PRIMARY KEY (identifier_id, match_id);


--
-- Name: identifier_pkey; Type: CONSTRAINT; Schema: mapper; Owner: -
--

ALTER TABLE ONLY identifier
    ADD CONSTRAINT identifier_pkey PRIMARY KEY (id);


--
-- Name: match_pkey; Type: CONSTRAINT; Schema: mapper; Owner: -
--

ALTER TABLE ONLY match
    ADD CONSTRAINT match_pkey PRIMARY KEY (id);


--
-- Name: uk_2u4bey0rox6ubtvqevg3wasp9; Type: CONSTRAINT; Schema: mapper; Owner: -
--

ALTER TABLE ONLY match
    ADD CONSTRAINT uk_2u4bey0rox6ubtvqevg3wasp9 UNIQUE (uri);


--
-- Name: unique_name_space; Type: CONSTRAINT; Schema: mapper; Owner: -
--

ALTER TABLE ONLY identifier
    ADD CONSTRAINT unique_name_space UNIQUE (id_number, object_type, name_space);


SET search_path = public, pg_catalog;

--
-- Name: author_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY author
    ADD CONSTRAINT author_pkey PRIMARY KEY (id);


--
-- Name: comment_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY comment
    ADD CONSTRAINT comment_pkey PRIMARY KEY (id);


--
-- Name: db_version_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY db_version
    ADD CONSTRAINT db_version_pkey PRIMARY KEY (id);


--
-- Name: delayed_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY delayed_jobs
    ADD CONSTRAINT delayed_jobs_pkey PRIMARY KEY (id);


--
-- Name: external_ref_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY external_ref
    ADD CONSTRAINT external_ref_pkey PRIMARY KEY (id);


--
-- Name: help_topic_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY help_topic
    ADD CONSTRAINT help_topic_pkey PRIMARY KEY (id);


--
-- Name: id_mapper_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY id_mapper
    ADD CONSTRAINT id_mapper_pkey PRIMARY KEY (id);


--
-- Name: instance_note_key_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY instance_note_key
    ADD CONSTRAINT instance_note_key_pkey PRIMARY KEY (id);


--
-- Name: instance_note_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY instance_note
    ADD CONSTRAINT instance_note_pkey PRIMARY KEY (id);


--
-- Name: instance_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY instance
    ADD CONSTRAINT instance_pkey PRIMARY KEY (id);


--
-- Name: instance_type_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY instance_type
    ADD CONSTRAINT instance_type_pkey PRIMARY KEY (id);


--
-- Name: language_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY language
    ADD CONSTRAINT language_pkey PRIMARY KEY (id);


--
-- Name: locale_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY locale
    ADD CONSTRAINT locale_pkey PRIMARY KEY (id);


--
-- Name: name_category_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY name_category
    ADD CONSTRAINT name_category_pkey PRIMARY KEY (id);


--
-- Name: name_group_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY name_group
    ADD CONSTRAINT name_group_pkey PRIMARY KEY (id);


--
-- Name: name_part_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY name_part
    ADD CONSTRAINT name_part_pkey PRIMARY KEY (id);


--
-- Name: name_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY name
    ADD CONSTRAINT name_pkey PRIMARY KEY (id);


--
-- Name: name_rank_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY name_rank
    ADD CONSTRAINT name_rank_pkey PRIMARY KEY (id);


--
-- Name: name_status_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY name_status
    ADD CONSTRAINT name_status_pkey PRIMARY KEY (id);


--
-- Name: name_tag_name_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY name_tag_name
    ADD CONSTRAINT name_tag_name_pkey PRIMARY KEY (name_id, tag_id);


--
-- Name: name_tag_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY name_tag
    ADD CONSTRAINT name_tag_pkey PRIMARY KEY (id);


--
-- Name: name_tree_path_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY name_tree_path
    ADD CONSTRAINT name_tree_path_pkey PRIMARY KEY (id);


--
-- Name: name_type_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY name_type
    ADD CONSTRAINT name_type_pkey PRIMARY KEY (id);


--
-- Name: namespace_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY namespace
    ADD CONSTRAINT namespace_pkey PRIMARY KEY (id);


--
-- Name: no_duplicate_synonyms; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY instance
    ADD CONSTRAINT no_duplicate_synonyms UNIQUE (name_id, reference_id, instance_type_id, page, cites_id, cited_by_id);


--
-- Name: nomenclatural_event_type_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY nomenclatural_event_type
    ADD CONSTRAINT nomenclatural_event_type_pkey PRIMARY KEY (id);


--
-- Name: notification_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY notification
    ADD CONSTRAINT notification_pkey PRIMARY KEY (id);


--
-- Name: ref_author_role_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY ref_author_role
    ADD CONSTRAINT ref_author_role_pkey PRIMARY KEY (id);


--
-- Name: ref_type_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY ref_type
    ADD CONSTRAINT ref_type_pkey PRIMARY KEY (id);


--
-- Name: reference_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY reference
    ADD CONSTRAINT reference_pkey PRIMARY KEY (id);


--
-- Name: shard_config_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY shard_config
    ADD CONSTRAINT shard_config_pkey PRIMARY KEY (id);


--
-- Name: tree_arrangement_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tree_arrangement
    ADD CONSTRAINT tree_arrangement_pkey PRIMARY KEY (id);


--
-- Name: tree_event_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tree_event
    ADD CONSTRAINT tree_event_pkey PRIMARY KEY (id);


--
-- Name: tree_link_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tree_link
    ADD CONSTRAINT tree_link_pkey PRIMARY KEY (id);


--
-- Name: tree_node_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tree_node
    ADD CONSTRAINT tree_node_pkey PRIMARY KEY (id);


--
-- Name: tree_uri_ns_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tree_uri_ns
    ADD CONSTRAINT tree_uri_ns_pkey PRIMARY KEY (id);


--
-- Name: tree_value_uri_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tree_value_uri
    ADD CONSTRAINT tree_value_uri_pkey PRIMARY KEY (id);


--
-- Name: uk_314uhkq8i7r46050kd1nfrs95; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY name_type
    ADD CONSTRAINT uk_314uhkq8i7r46050kd1nfrs95 UNIQUE (name);


--
-- Name: uk_4fp66uflo7rgx59167ajs0ujv; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY ref_type
    ADD CONSTRAINT uk_4fp66uflo7rgx59167ajs0ujv UNIQUE (name);


--
-- Name: uk_5185nbyw5hkxqyyqgylfn2o6d; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY name_group
    ADD CONSTRAINT uk_5185nbyw5hkxqyyqgylfn2o6d UNIQUE (name);


--
-- Name: uk_5smmen5o34hs50jxd247k81ia; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tree_uri_ns
    ADD CONSTRAINT uk_5smmen5o34hs50jxd247k81ia UNIQUE (label);


--
-- Name: uk_70p0ys3l5v6s9dqrpjr3u3rrf; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tree_uri_ns
    ADD CONSTRAINT uk_70p0ys3l5v6s9dqrpjr3u3rrf UNIQUE (uri);


--
-- Name: uk_9kovg6nyb11658j2tv2yv4bsi; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY author
    ADD CONSTRAINT uk_9kovg6nyb11658j2tv2yv4bsi UNIQUE (abbrev);


--
-- Name: uk_a0justk7c77bb64o6u1riyrlh; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY instance_note_key
    ADD CONSTRAINT uk_a0justk7c77bb64o6u1riyrlh UNIQUE (name);


--
-- Name: uk_eq2y9mghytirkcofquanv5frf; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY namespace
    ADD CONSTRAINT uk_eq2y9mghytirkcofquanv5frf UNIQUE (name);


--
-- Name: uk_g8hr207ijpxlwu10pewyo65gv; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY language
    ADD CONSTRAINT uk_g8hr207ijpxlwu10pewyo65gv UNIQUE (name);


--
-- Name: uk_hghw87nl0ho38f166atlpw2hy; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY language
    ADD CONSTRAINT uk_hghw87nl0ho38f166atlpw2hy UNIQUE (iso6391code);


--
-- Name: uk_j5337m9qdlirvd49v4h11t1lk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY instance_type
    ADD CONSTRAINT uk_j5337m9qdlirvd49v4h11t1lk UNIQUE (name);


--
-- Name: uk_kqwpm0crhcq4n9t9uiyfxo2df; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY reference
    ADD CONSTRAINT uk_kqwpm0crhcq4n9t9uiyfxo2df UNIQUE (doi);


--
-- Name: uk_l95kedbafybjpp3h53x8o9fke; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY ref_author_role
    ADD CONSTRAINT uk_l95kedbafybjpp3h53x8o9fke UNIQUE (name);


--
-- Name: uk_o4su6hi7vh0yqs4c1dw0fsf1e; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY name_tag
    ADD CONSTRAINT uk_o4su6hi7vh0yqs4c1dw0fsf1e UNIQUE (name);


--
-- Name: uk_qjkskvl9hx0w78truoyq9teju; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY locale
    ADD CONSTRAINT uk_qjkskvl9hx0w78truoyq9teju UNIQUE (locale_name_string);


--
-- Name: uk_rpsahneqboogcki6p1bpygsua; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY language
    ADD CONSTRAINT uk_rpsahneqboogcki6p1bpygsua UNIQUE (iso6393code);


--
-- Name: uk_rxqxoenedjdjyd4x7c98s59io; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY name_category
    ADD CONSTRAINT uk_rxqxoenedjdjyd4x7c98s59io UNIQUE (name);


--
-- Name: uk_se7crmfnhjmyvirp3p9hiqerx; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY name_status
    ADD CONSTRAINT uk_se7crmfnhjmyvirp3p9hiqerx UNIQUE (name);


--
-- Name: uk_sv1q1i7xve7xgmkwvmdbeo1mb; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY why_is_this_here
    ADD CONSTRAINT uk_sv1q1i7xve7xgmkwvmdbeo1mb UNIQUE (name);


--
-- Name: uk_y303qbh1ijdg3sncl9vlxus0; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tree_arrangement
    ADD CONSTRAINT uk_y303qbh1ijdg3sncl9vlxus0 UNIQUE (label);


--
-- Name: unique_from_id; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY id_mapper
    ADD CONSTRAINT unique_from_id UNIQUE (to_id, from_id);


--
-- Name: user_query_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_query
    ADD CONSTRAINT user_query_pkey PRIMARY KEY (id);


--
-- Name: why_is_this_here_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY why_is_this_here
    ADD CONSTRAINT why_is_this_here_pkey PRIMARY KEY (id);


SET search_path = audit, pg_catalog;

--
-- Name: logged_actions_action_idx; Type: INDEX; Schema: audit; Owner: -
--

CREATE INDEX logged_actions_action_idx ON logged_actions USING btree (action);


--
-- Name: logged_actions_action_tstamp_tx_stm_idx; Type: INDEX; Schema: audit; Owner: -
--

CREATE INDEX logged_actions_action_tstamp_tx_stm_idx ON logged_actions USING btree (action_tstamp_stm);


--
-- Name: logged_actions_relid_idx; Type: INDEX; Schema: audit; Owner: -
--

CREATE INDEX logged_actions_relid_idx ON logged_actions USING btree (relid);


SET search_path = mapper, pg_catalog;

--
-- Name: identifier_index; Type: INDEX; Schema: mapper; Owner: -
--

CREATE INDEX identifier_index ON identifier USING btree (id_number, name_space, object_type);


--
-- Name: identity_uri_index; Type: INDEX; Schema: mapper; Owner: -
--

CREATE INDEX identity_uri_index ON match USING btree (uri);


--
-- Name: mapper_identifier_index; Type: INDEX; Schema: mapper; Owner: -
--

CREATE INDEX mapper_identifier_index ON identifier_identities USING btree (identifier_id);


--
-- Name: mapper_match_index; Type: INDEX; Schema: mapper; Owner: -
--

CREATE INDEX mapper_match_index ON identifier_identities USING btree (match_id);


--
-- Name: match_host_index; Type: INDEX; Schema: mapper; Owner: -
--

CREATE INDEX match_host_index ON match_host USING btree (match_hosts_id);


SET search_path = public, pg_catalog;

--
-- Name: auth_source_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auth_source_index ON author USING btree (namespace_id, source_id, source_system);


--
-- Name: auth_source_string_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auth_source_string_index ON author USING btree (source_id_string);


--
-- Name: auth_system_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auth_system_index ON author USING btree (source_system);


--
-- Name: author_abbrev_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX author_abbrev_index ON author USING btree (abbrev);


--
-- Name: author_name_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX author_name_index ON author USING btree (name);


--
-- Name: by_root_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX by_root_id ON tree_value_uri USING btree (root_id);


--
-- Name: comment_author_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX comment_author_index ON comment USING btree (author_id);


--
-- Name: comment_instance_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX comment_instance_index ON comment USING btree (instance_id);


--
-- Name: comment_name_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX comment_name_index ON comment USING btree (name_id);


--
-- Name: comment_reference_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX comment_reference_index ON comment USING btree (reference_id);


--
-- Name: id_mapper_from_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX id_mapper_from_index ON id_mapper USING btree (from_id, namespace_id, system);


--
-- Name: idx_node_current_a; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_node_current_a ON tree_node USING btree (tree_arrangement_id) WHERE (replaced_at_id IS NULL);


--
-- Name: idx_node_current_b; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_node_current_b ON tree_node USING btree (tree_arrangement_id) WHERE (next_node_id IS NULL);


--
-- Name: idx_node_current_instance_a; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_node_current_instance_a ON tree_node USING btree (instance_id, tree_arrangement_id) WHERE (replaced_at_id IS NULL);


--
-- Name: idx_node_current_instance_b; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_node_current_instance_b ON tree_node USING btree (instance_id, tree_arrangement_id) WHERE (next_node_id IS NULL);


--
-- Name: idx_node_current_name_a; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_node_current_name_a ON tree_node USING btree (name_id, tree_arrangement_id) WHERE (replaced_at_id IS NULL);


--
-- Name: idx_node_current_name_b; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_node_current_name_b ON tree_node USING btree (name_id, tree_arrangement_id) WHERE (next_node_id IS NULL);


--
-- Name: idx_tree_link_seq; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_tree_link_seq ON tree_link USING btree (supernode_id, link_seq);


--
-- Name: idx_tree_node_instance_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tree_node_instance_id ON tree_node USING btree (instance_id);


--
-- Name: idx_tree_node_instance_id_in; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tree_node_instance_id_in ON tree_node USING btree (instance_id, tree_arrangement_id);


--
-- Name: idx_tree_node_literal; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tree_node_literal ON tree_node USING btree (literal);


--
-- Name: idx_tree_node_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tree_node_name ON tree_node USING btree (name_uri_id_part, name_uri_ns_part_id);


--
-- Name: idx_tree_node_name_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tree_node_name_id ON tree_node USING btree (name_id);


--
-- Name: idx_tree_node_name_id_in; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tree_node_name_id_in ON tree_node USING btree (name_id, tree_arrangement_id);


--
-- Name: idx_tree_node_name_in; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tree_node_name_in ON tree_node USING btree (name_uri_id_part, name_uri_ns_part_id, tree_arrangement_id);


--
-- Name: idx_tree_node_resource; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tree_node_resource ON tree_node USING btree (resource_uri_id_part, resource_uri_ns_part_id);


--
-- Name: idx_tree_node_resource_in; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tree_node_resource_in ON tree_node USING btree (resource_uri_id_part, resource_uri_ns_part_id, tree_arrangement_id);


--
-- Name: idx_tree_node_taxon; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tree_node_taxon ON tree_node USING btree (taxon_uri_id_part, taxon_uri_ns_part_id);


--
-- Name: idx_tree_node_taxon_in; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tree_node_taxon_in ON tree_node USING btree (taxon_uri_id_part, taxon_uri_ns_part_id, tree_arrangement_id);


--
-- Name: idx_tree_uri_ns_label; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tree_uri_ns_label ON tree_uri_ns USING btree (label);


--
-- Name: idx_tree_uri_ns_uri; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tree_uri_ns_uri ON tree_uri_ns USING btree (uri);


--
-- Name: instance_citedby_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX instance_citedby_index ON instance USING btree (cited_by_id);


--
-- Name: instance_cites_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX instance_cites_index ON instance USING btree (cites_id);


--
-- Name: instance_instancetype_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX instance_instancetype_index ON instance USING btree (instance_type_id);


--
-- Name: instance_name_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX instance_name_index ON instance USING btree (name_id);


--
-- Name: instance_note_key_rdfid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX instance_note_key_rdfid ON instance_note_key USING btree (rdf_id);


--
-- Name: instance_parent_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX instance_parent_index ON instance USING btree (parent_id);


--
-- Name: instance_reference_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX instance_reference_index ON instance USING btree (reference_id);


--
-- Name: instance_source_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX instance_source_index ON instance USING btree (namespace_id, source_id, source_system);


--
-- Name: instance_source_string_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX instance_source_string_index ON instance USING btree (source_id_string);


--
-- Name: instance_system_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX instance_system_index ON instance USING btree (source_system);


--
-- Name: instance_type_rdfid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX instance_type_rdfid ON instance_type USING btree (rdf_id);


--
-- Name: link_uri_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX link_uri_index ON tree_value_uri USING btree (link_uri_id_part, link_uri_ns_part_id, root_id);


--
-- Name: lower_full_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX lower_full_name ON name USING btree (lower((full_name)::text));


--
-- Name: name_author_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_author_index ON name USING btree (author_id);


--
-- Name: name_baseauthor_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_baseauthor_index ON name USING btree (base_author_id);


--
-- Name: name_category_rdfid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_category_rdfid ON name_category USING btree (rdf_id);


--
-- Name: name_duplicate_of_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_duplicate_of_id_index ON name USING btree (duplicate_of_id);


--
-- Name: name_exauthor_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_exauthor_index ON name USING btree (ex_author_id);


--
-- Name: name_exbaseauthor_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_exbaseauthor_index ON name USING btree (ex_base_author_id);


--
-- Name: name_full_name_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_full_name_index ON name USING btree (full_name);


--
-- Name: name_group_rdfid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_group_rdfid ON name_group USING btree (rdf_id);


--
-- Name: name_lower_f_unaccent_full_name_like; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_lower_f_unaccent_full_name_like ON name USING btree (lower(f_unaccent((full_name)::text)) varchar_pattern_ops);


--
-- Name: name_lower_full_name_gin_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_lower_full_name_gin_trgm ON name USING gin (lower((full_name)::text) gin_trgm_ops);


--
-- Name: name_lower_simple_name_gin_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_lower_simple_name_gin_trgm ON name USING gin (lower((simple_name)::text) gin_trgm_ops);


--
-- Name: name_lower_unacent_full_name_gin_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_lower_unacent_full_name_gin_trgm ON name USING gin (lower(f_unaccent((full_name)::text)) gin_trgm_ops);


--
-- Name: name_lower_unacent_simple_name_gin_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_lower_unacent_simple_name_gin_trgm ON name USING gin (lower(f_unaccent((simple_name)::text)) gin_trgm_ops);


--
-- Name: name_name_element_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_name_element_index ON name USING btree (name_element);


--
-- Name: name_parent_id_ndx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_parent_id_ndx ON name USING btree (parent_id);


--
-- Name: name_part_name_id_ndx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_part_name_id_ndx ON name_part USING btree (name_id);


--
-- Name: name_rank_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_rank_index ON name USING btree (name_rank_id);


--
-- Name: name_rank_rdfid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_rank_rdfid ON name_rank USING btree (rdf_id);


--
-- Name: name_sanctioningauthor_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_sanctioningauthor_index ON name USING btree (sanctioning_author_id);


--
-- Name: name_second_parent_id_ndx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_second_parent_id_ndx ON name USING btree (second_parent_id);


--
-- Name: name_simple_name_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_simple_name_index ON name USING btree (simple_name);


--
-- Name: name_source_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_source_index ON name USING btree (namespace_id, source_id, source_system);


--
-- Name: name_source_string_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_source_string_index ON name USING btree (source_id_string);


--
-- Name: name_status_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_status_index ON name USING btree (name_status_id);


--
-- Name: name_status_rdfid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_status_rdfid ON name_status USING btree (rdf_id);


--
-- Name: name_system_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_system_index ON name USING btree (source_system);


--
-- Name: name_tag_name_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_tag_name_index ON name_tag_name USING btree (name_id);


--
-- Name: name_tag_tag_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_tag_tag_index ON name_tag_name USING btree (tag_id);


--
-- Name: name_tree_path_family_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_tree_path_family_index ON name_tree_path USING btree (family_id);


--
-- Name: name_tree_path_treename_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_tree_path_treename_index ON name_tree_path USING btree (name_id, tree_id);


--
-- Name: name_type_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_type_index ON name USING btree (name_type_id);


--
-- Name: name_type_rdfid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_type_rdfid ON name_type USING btree (rdf_id);


--
-- Name: name_whyisthishere_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_whyisthishere_index ON name USING btree (why_is_this_here_id);


--
-- Name: namespace_rdfid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX namespace_rdfid ON namespace USING btree (rdf_id);


--
-- Name: node_uri_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX node_uri_index ON tree_value_uri USING btree (node_uri_id_part, node_uri_ns_part_id, root_id);


--
-- Name: nomenclatural_event_type_rdfid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX nomenclatural_event_type_rdfid ON nomenclatural_event_type USING btree (rdf_id);


--
-- Name: note_instance_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX note_instance_index ON instance_note USING btree (instance_id);


--
-- Name: note_key_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX note_key_index ON instance_note USING btree (instance_note_key_id);


--
-- Name: note_source_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX note_source_index ON instance_note USING btree (namespace_id, source_id, source_system);


--
-- Name: note_source_string_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX note_source_string_index ON instance_note USING btree (source_id_string);


--
-- Name: note_system_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX note_system_index ON instance_note USING btree (source_system);


--
-- Name: preceding_name_type_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX preceding_name_type_index ON name_part USING btree (preceding_name_type);


--
-- Name: ref_author_role_rdfid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ref_author_role_rdfid ON ref_author_role USING btree (rdf_id);


--
-- Name: ref_citation_text_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ref_citation_text_index ON reference USING gin (to_tsvector('english'::regconfig, f_unaccent(COALESCE((citation)::text, ''::text))));


--
-- Name: ref_source_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ref_source_index ON reference USING btree (namespace_id, source_id, source_system);


--
-- Name: ref_source_string_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ref_source_string_index ON reference USING btree (source_id_string);


--
-- Name: ref_system_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ref_system_index ON reference USING btree (source_system);


--
-- Name: ref_type_rdfid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ref_type_rdfid ON ref_type USING btree (rdf_id);


--
-- Name: reference_author_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX reference_author_index ON reference USING btree (author_id);


--
-- Name: reference_authorrole_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX reference_authorrole_index ON reference USING btree (ref_author_role_id);


--
-- Name: reference_parent_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX reference_parent_index ON reference USING btree (parent_id);


--
-- Name: reference_type_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX reference_type_index ON reference USING btree (ref_type_id);


--
-- Name: tree_arrangement_label; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tree_arrangement_label ON tree_arrangement USING btree (label);


--
-- Name: tree_arrangement_node; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tree_arrangement_node ON tree_arrangement USING btree (node_id);


--
-- Name: tree_link_subnode; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tree_link_subnode ON tree_link USING btree (subnode_id);


--
-- Name: tree_link_supernode; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tree_link_supernode ON tree_link USING btree (supernode_id);


--
-- Name: tree_node_next; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tree_node_next ON tree_node USING btree (next_node_id);


--
-- Name: tree_node_prev; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tree_node_prev ON tree_node USING btree (prev_node_id);


--
-- Name: audit_trigger_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON author FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');


--
-- Name: audit_trigger_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON instance FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');


--
-- Name: audit_trigger_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON name FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');


--
-- Name: audit_trigger_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON reference FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');


--
-- Name: audit_trigger_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON instance_note FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');


--
-- Name: audit_trigger_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON comment FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');


--
-- Name: audit_trigger_stm; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON author FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');


--
-- Name: audit_trigger_stm; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON instance FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');


--
-- Name: audit_trigger_stm; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON name FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');


--
-- Name: audit_trigger_stm; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON reference FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');


--
-- Name: audit_trigger_stm; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON instance_note FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');


--
-- Name: audit_trigger_stm; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON comment FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');


--
-- Name: author_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER author_update AFTER INSERT OR DELETE OR UPDATE ON author FOR EACH ROW EXECUTE PROCEDURE author_notification();


--
-- Name: name_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER name_update AFTER INSERT OR DELETE OR UPDATE ON name FOR EACH ROW EXECUTE PROCEDURE name_notification();


--
-- Name: reference_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER reference_update AFTER INSERT OR DELETE OR UPDATE ON reference FOR EACH ROW EXECUTE PROCEDURE reference_notification();


SET search_path = mapper, pg_catalog;

--
-- Name: fk_3unhnjvw9xhs9l3ney6tvnioq; Type: FK CONSTRAINT; Schema: mapper; Owner: -
--

ALTER TABLE ONLY match_host
    ADD CONSTRAINT fk_3unhnjvw9xhs9l3ney6tvnioq FOREIGN KEY (host_id) REFERENCES host(id);


--
-- Name: fk_iw1fva74t5r4ehvmoy87n37yr; Type: FK CONSTRAINT; Schema: mapper; Owner: -
--

ALTER TABLE ONLY match_host
    ADD CONSTRAINT fk_iw1fva74t5r4ehvmoy87n37yr FOREIGN KEY (match_hosts_id) REFERENCES match(id);


--
-- Name: fk_k2o53uoslf9gwqrd80cu2al4s; Type: FK CONSTRAINT; Schema: mapper; Owner: -
--

ALTER TABLE ONLY identifier
    ADD CONSTRAINT fk_k2o53uoslf9gwqrd80cu2al4s FOREIGN KEY (preferred_uri_id) REFERENCES match(id);


--
-- Name: fk_mf2dsc2dxvsa9mlximsct7uau; Type: FK CONSTRAINT; Schema: mapper; Owner: -
--

ALTER TABLE ONLY identifier_identities
    ADD CONSTRAINT fk_mf2dsc2dxvsa9mlximsct7uau FOREIGN KEY (match_id) REFERENCES match(id);


--
-- Name: fk_ojfilkcwskdvvbggwsnachry2; Type: FK CONSTRAINT; Schema: mapper; Owner: -
--

ALTER TABLE ONLY identifier_identities
    ADD CONSTRAINT fk_ojfilkcwskdvvbggwsnachry2 FOREIGN KEY (identifier_id) REFERENCES identifier(id);


SET search_path = public, pg_catalog;

--
-- Name: fk_10d0jlulq2woht49j5ccpeehu; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY name_type
    ADD CONSTRAINT fk_10d0jlulq2woht49j5ccpeehu FOREIGN KEY (name_category_id) REFERENCES name_category(id);


--
-- Name: fk_156ncmx4599jcsmhh5k267cjv; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY name
    ADD CONSTRAINT fk_156ncmx4599jcsmhh5k267cjv FOREIGN KEY (namespace_id) REFERENCES namespace(id);


--
-- Name: fk_16c4wgya68bwotwn6f50dhw69; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tree_node
    ADD CONSTRAINT fk_16c4wgya68bwotwn6f50dhw69 FOREIGN KEY (taxon_uri_ns_part_id) REFERENCES tree_uri_ns(id);


--
-- Name: fk_1g9477sa8plad5cxkxmiuh5b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tree_node
    ADD CONSTRAINT fk_1g9477sa8plad5cxkxmiuh5b FOREIGN KEY (instance_id) REFERENCES instance(id);


--
-- Name: fk_1qx84m8tuk7vw2diyxfbj5r2n; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY reference
    ADD CONSTRAINT fk_1qx84m8tuk7vw2diyxfbj5r2n FOREIGN KEY (language_id) REFERENCES language(id);


--
-- Name: fk_22wdc2pxaskytkgpdgpyok07n; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY name_tag_name
    ADD CONSTRAINT fk_22wdc2pxaskytkgpdgpyok07n FOREIGN KEY (name_id) REFERENCES name(id);


--
-- Name: fk_2dk33tolvn16lfmp25nk2584y; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tree_link
    ADD CONSTRAINT fk_2dk33tolvn16lfmp25nk2584y FOREIGN KEY (type_uri_ns_part_id) REFERENCES tree_uri_ns(id);


--
-- Name: fk_2uiijd73snf6lh5s6a82yjfin; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY name_tag_name
    ADD CONSTRAINT fk_2uiijd73snf6lh5s6a82yjfin FOREIGN KEY (tag_id) REFERENCES name_tag(id);


--
-- Name: fk_30enb6qoexhuk479t75apeuu5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY instance
    ADD CONSTRAINT fk_30enb6qoexhuk479t75apeuu5 FOREIGN KEY (cites_id) REFERENCES instance(id);


--
-- Name: fk_3min66ljijxavb0fjergx5dpm; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY reference
    ADD CONSTRAINT fk_3min66ljijxavb0fjergx5dpm FOREIGN KEY (duplicate_of_id) REFERENCES reference(id);


--
-- Name: fk_3pqdqa03w5c6h4yyrrvfuagos; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY name
    ADD CONSTRAINT fk_3pqdqa03w5c6h4yyrrvfuagos FOREIGN KEY (duplicate_of_id) REFERENCES name(id);


--
-- Name: fk_3tfkdcmf6rg6hcyiu8t05er7x; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY comment
    ADD CONSTRAINT fk_3tfkdcmf6rg6hcyiu8t05er7x FOREIGN KEY (reference_id) REFERENCES reference(id);


--
-- Name: fk_4g2i2qry4941xmqijgeo8ns2h; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY external_ref
    ADD CONSTRAINT fk_4g2i2qry4941xmqijgeo8ns2h FOREIGN KEY (instance_id) REFERENCES instance(id);


--
-- Name: fk_4kc2kv5choyybkaetmshegbet; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY name_tree_path
    ADD CONSTRAINT fk_4kc2kv5choyybkaetmshegbet FOREIGN KEY (family_id) REFERENCES name(id);


--
-- Name: fk_4y1qy9beekbv71e9i6hto6hun; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tree_node
    ADD CONSTRAINT fk_4y1qy9beekbv71e9i6hto6hun FOREIGN KEY (resource_uri_ns_part_id) REFERENCES tree_uri_ns(id);


--
-- Name: fk_51alfoe7eobwh60yfx45y22ay; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY ref_type
    ADD CONSTRAINT fk_51alfoe7eobwh60yfx45y22ay FOREIGN KEY (parent_id) REFERENCES ref_type(id);


--
-- Name: fk_5fpm5u0ukiml9nvmq14bd7u51; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY name
    ADD CONSTRAINT fk_5fpm5u0ukiml9nvmq14bd7u51 FOREIGN KEY (name_status_id) REFERENCES name_status(id);


--
-- Name: fk_5gp2lfblqq94c4ud3340iml0l; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY name
    ADD CONSTRAINT fk_5gp2lfblqq94c4ud3340iml0l FOREIGN KEY (second_parent_id) REFERENCES name(id);


--
-- Name: fk_5r3o78sgdbxsf525hmm3t44gv; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY name_type
    ADD CONSTRAINT fk_5r3o78sgdbxsf525hmm3t44gv FOREIGN KEY (name_group_id) REFERENCES name_group(id);


--
-- Name: fk_6a4p11f1bt171w09oo06m0wag; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY author
    ADD CONSTRAINT fk_6a4p11f1bt171w09oo06m0wag FOREIGN KEY (duplicate_of_id) REFERENCES author(id);


--
-- Name: fk_6oqj6vquqc33cyawn853hfu5g; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY comment
    ADD CONSTRAINT fk_6oqj6vquqc33cyawn853hfu5g FOREIGN KEY (instance_id) REFERENCES instance(id);


--
-- Name: fk_9aq5p2jgf17y6b38x5ayd90oc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY comment
    ADD CONSTRAINT fk_9aq5p2jgf17y6b38x5ayd90oc FOREIGN KEY (author_id) REFERENCES author(id);


--
-- Name: fk_a98ei1lxn89madjihel3cvi90; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY reference
    ADD CONSTRAINT fk_a98ei1lxn89madjihel3cvi90 FOREIGN KEY (ref_author_role_id) REFERENCES ref_author_role(id);


--
-- Name: fk_ai81l07vh2yhmthr3582igo47; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY name
    ADD CONSTRAINT fk_ai81l07vh2yhmthr3582igo47 FOREIGN KEY (sanctioning_author_id) REFERENCES author(id);


--
-- Name: fk_airfjupm6ohehj1lj82yqkwdx; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY name
    ADD CONSTRAINT fk_airfjupm6ohehj1lj82yqkwdx FOREIGN KEY (author_id) REFERENCES author(id);


--
-- Name: fk_am2j11kvuwl19gqewuu18gjjm; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY reference
    ADD CONSTRAINT fk_am2j11kvuwl19gqewuu18gjjm FOREIGN KEY (namespace_id) REFERENCES namespace(id);


--
-- Name: fk_bcef76k0ijrcquyoc0yxehxfp; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY name
    ADD CONSTRAINT fk_bcef76k0ijrcquyoc0yxehxfp FOREIGN KEY (name_type_id) REFERENCES name_type(id);


--
-- Name: fk_bu7q5itmt7w7q1bex049xvac7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY external_ref
    ADD CONSTRAINT fk_bu7q5itmt7w7q1bex049xvac7 FOREIGN KEY (name_id) REFERENCES name(id);


--
-- Name: fk_budb70h51jhcxe7qbtpea0hi2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tree_node
    ADD CONSTRAINT fk_budb70h51jhcxe7qbtpea0hi2 FOREIGN KEY (prev_node_id) REFERENCES tree_node(id);


--
-- Name: fk_bw41122jb5rcu8wfnog812s97; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY instance_note
    ADD CONSTRAINT fk_bw41122jb5rcu8wfnog812s97 FOREIGN KEY (instance_id) REFERENCES instance(id);


--
-- Name: fk_coqxx3ewgiecsh3t78yc70b35; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY name
    ADD CONSTRAINT fk_coqxx3ewgiecsh3t78yc70b35 FOREIGN KEY (base_author_id) REFERENCES author(id);


--
-- Name: fk_cr9avt4miqikx4kk53aflnnkd; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY reference
    ADD CONSTRAINT fk_cr9avt4miqikx4kk53aflnnkd FOREIGN KEY (parent_id) REFERENCES reference(id);


--
-- Name: fk_dd33etb69v5w5iah1eeisy7yt; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY name
    ADD CONSTRAINT fk_dd33etb69v5w5iah1eeisy7yt FOREIGN KEY (parent_id) REFERENCES name(id);


--
-- Name: fk_djkn41tin6shkjuut9nam9xvn; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tree_value_uri
    ADD CONSTRAINT fk_djkn41tin6shkjuut9nam9xvn FOREIGN KEY (node_uri_ns_part_id) REFERENCES tree_uri_ns(id);


--
-- Name: fk_dm9y4p9xpsc8m7vljbohubl7x; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY reference
    ADD CONSTRAINT fk_dm9y4p9xpsc8m7vljbohubl7x FOREIGN KEY (ref_type_id) REFERENCES ref_type(id);


--
-- Name: fk_dqhn53mdh0n77xhsw7l5dgd38; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY name
    ADD CONSTRAINT fk_dqhn53mdh0n77xhsw7l5dgd38 FOREIGN KEY (why_is_this_here_id) REFERENCES why_is_this_here(id);


--
-- Name: fk_ds3bc89iy6q3ts4ts85mqiys; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tree_value_uri
    ADD CONSTRAINT fk_ds3bc89iy6q3ts4ts85mqiys FOREIGN KEY (link_uri_ns_part_id) REFERENCES tree_uri_ns(id);


--
-- Name: fk_eqw4xo7vty6e4tq8hy34c51om; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tree_node
    ADD CONSTRAINT fk_eqw4xo7vty6e4tq8hy34c51om FOREIGN KEY (name_id) REFERENCES name(id);


--
-- Name: fk_f6s94njexmutjxjv8t5dy1ugt; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY instance_note
    ADD CONSTRAINT fk_f6s94njexmutjxjv8t5dy1ugt FOREIGN KEY (namespace_id) REFERENCES namespace(id);


--
-- Name: fk_f7igpcpvgcmdfb7v3bgjluqsf; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY external_ref
    ADD CONSTRAINT fk_f7igpcpvgcmdfb7v3bgjluqsf FOREIGN KEY (reference_id) REFERENCES reference(id);


--
-- Name: fk_fvfq13j3dqv994o9vg54yj5kk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tree_arrangement
    ADD CONSTRAINT fk_fvfq13j3dqv994o9vg54yj5kk FOREIGN KEY (node_id) REFERENCES tree_node(id);


--
-- Name: fk_g4o6xditli5a0xrm6eqc6h9gw; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY name_status
    ADD CONSTRAINT fk_g4o6xditli5a0xrm6eqc6h9gw FOREIGN KEY (name_status_id) REFERENCES name_status(id);


--
-- Name: fk_gc6f9ykh7eaflvty9tr6n4cb6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tree_node
    ADD CONSTRAINT fk_gc6f9ykh7eaflvty9tr6n4cb6 FOREIGN KEY (name_uri_ns_part_id) REFERENCES tree_uri_ns(id);


--
-- Name: fk_gdunt8xo68ct1vfec9c6x5889; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY instance
    ADD CONSTRAINT fk_gdunt8xo68ct1vfec9c6x5889 FOREIGN KEY (name_id) REFERENCES name(id);


--
-- Name: fk_gtkjmbvk6uk34fbfpy910e7t6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY instance
    ADD CONSTRAINT fk_gtkjmbvk6uk34fbfpy910e7t6 FOREIGN KEY (namespace_id) REFERENCES namespace(id);


--
-- Name: fk_h9t5eaaqhnqwrc92rhryyvdcf; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY comment
    ADD CONSTRAINT fk_h9t5eaaqhnqwrc92rhryyvdcf FOREIGN KEY (name_id) REFERENCES name(id);


--
-- Name: fk_hb0xb97midopfgrm2k5fpe3p1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY instance
    ADD CONSTRAINT fk_hb0xb97midopfgrm2k5fpe3p1 FOREIGN KEY (parent_id) REFERENCES instance(id);


--
-- Name: fk_he1t3ug0o7ollnk2jbqaouooa; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY instance_note
    ADD CONSTRAINT fk_he1t3ug0o7ollnk2jbqaouooa FOREIGN KEY (instance_note_key_id) REFERENCES instance_note_key(id);


--
-- Name: fk_kqshktm171nwvk38ot4d12w6b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tree_link
    ADD CONSTRAINT fk_kqshktm171nwvk38ot4d12w6b FOREIGN KEY (supernode_id) REFERENCES tree_node(id);


--
-- Name: fk_lumlr5avj305pmc4hkjwaqk45; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY instance
    ADD CONSTRAINT fk_lumlr5avj305pmc4hkjwaqk45 FOREIGN KEY (reference_id) REFERENCES reference(id);


--
-- Name: fk_nlq0qddnhgx65iojhj2xm8tay; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tree_node
    ADD CONSTRAINT fk_nlq0qddnhgx65iojhj2xm8tay FOREIGN KEY (checked_in_at_id) REFERENCES tree_event(id);


--
-- Name: fk_nw785lqesvg8ntfaper0tw2vs; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tree_value_uri
    ADD CONSTRAINT fk_nw785lqesvg8ntfaper0tw2vs FOREIGN KEY (root_id) REFERENCES tree_arrangement(id);


--
-- Name: fk_o80rrtl8xwy4l3kqrt9qv0mnt; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY instance
    ADD CONSTRAINT fk_o80rrtl8xwy4l3kqrt9qv0mnt FOREIGN KEY (instance_type_id) REFERENCES instance_type(id);


--
-- Name: fk_oge4ibjd3ff3oyshexl6set2u; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tree_node
    ADD CONSTRAINT fk_oge4ibjd3ff3oyshexl6set2u FOREIGN KEY (type_uri_ns_part_id) REFERENCES tree_uri_ns(id);


--
-- Name: fk_p0ysrub11cm08xnhrbrfrvudh; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY author
    ADD CONSTRAINT fk_p0ysrub11cm08xnhrbrfrvudh FOREIGN KEY (namespace_id) REFERENCES namespace(id);


--
-- Name: fk_p3lpayfbl9s3hshhoycfj82b9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY name_rank
    ADD CONSTRAINT fk_p3lpayfbl9s3hshhoycfj82b9 FOREIGN KEY (name_group_id) REFERENCES name_group(id);


--
-- Name: fk_p8lhsoo01164dsvvwxob0w3sp; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY reference
    ADD CONSTRAINT fk_p8lhsoo01164dsvvwxob0w3sp FOREIGN KEY (author_id) REFERENCES author(id);


--
-- Name: fk_pc0tkp9bgp1cxull530y60v46; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tree_node
    ADD CONSTRAINT fk_pc0tkp9bgp1cxull530y60v46 FOREIGN KEY (replaced_at_id) REFERENCES tree_event(id);


--
-- Name: fk_pj38oewhgjq8rp08fc9cviteu; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY name_part
    ADD CONSTRAINT fk_pj38oewhgjq8rp08fc9cviteu FOREIGN KEY (preceding_name_id) REFERENCES name(id);


--
-- Name: fk_pr2f6peqhnx9rjiwkr5jgc5be; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY instance
    ADD CONSTRAINT fk_pr2f6peqhnx9rjiwkr5jgc5be FOREIGN KEY (cited_by_id) REFERENCES instance(id);


--
-- Name: fk_q9k8he941kvl07j2htmqxq35v; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tree_uri_ns
    ADD CONSTRAINT fk_q9k8he941kvl07j2htmqxq35v FOREIGN KEY (owner_uri_ns_part_id) REFERENCES tree_uri_ns(id);


--
-- Name: fk_qiy281xsleyhjgr0eu1sboagm; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY id_mapper
    ADD CONSTRAINT fk_qiy281xsleyhjgr0eu1sboagm FOREIGN KEY (namespace_id) REFERENCES namespace(id);


--
-- Name: fk_ql5g85814a9y57c1ifd0nkq3v; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY nomenclatural_event_type
    ADD CONSTRAINT fk_ql5g85814a9y57c1ifd0nkq3v FOREIGN KEY (name_group_id) REFERENCES name_group(id);


--
-- Name: fk_r67um91pujyfrx7h1cifs3cmb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY name_rank
    ADD CONSTRAINT fk_r67um91pujyfrx7h1cifs3cmb FOREIGN KEY (parent_rank_id) REFERENCES name_rank(id);


--
-- Name: fk_rp659tjcxokf26j8551k6an2y; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY name
    ADD CONSTRAINT fk_rp659tjcxokf26j8551k6an2y FOREIGN KEY (ex_base_author_id) REFERENCES author(id);


--
-- Name: fk_s13ituehdpf6uh859umme7g1j; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY name_part
    ADD CONSTRAINT fk_s13ituehdpf6uh859umme7g1j FOREIGN KEY (name_id) REFERENCES name(id);


--
-- Name: fk_sbuntfo4jfai44yjh9o09vu6s; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tree_node
    ADD CONSTRAINT fk_sbuntfo4jfai44yjh9o09vu6s FOREIGN KEY (next_node_id) REFERENCES tree_node(id);


--
-- Name: fk_sgvxmyj7r9g4wy9c4hd1yn4nu; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY name
    ADD CONSTRAINT fk_sgvxmyj7r9g4wy9c4hd1yn4nu FOREIGN KEY (ex_author_id) REFERENCES author(id);


--
-- Name: fk_sk2iikq8wla58jeypkw6h74hc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY name
    ADD CONSTRAINT fk_sk2iikq8wla58jeypkw6h74hc FOREIGN KEY (name_rank_id) REFERENCES name_rank(id);


--
-- Name: fk_swotu3c2gy1hp8f6ekvuo7s26; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY name_status
    ADD CONSTRAINT fk_swotu3c2gy1hp8f6ekvuo7s26 FOREIGN KEY (name_group_id) REFERENCES name_group(id);


--
-- Name: fk_t6kkvm8ubsiw6fqg473j0gjga; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tree_node
    ADD CONSTRAINT fk_t6kkvm8ubsiw6fqg473j0gjga FOREIGN KEY (tree_arrangement_id) REFERENCES tree_arrangement(id);


--
-- Name: fk_tgankaahxgr4p0mw4opafah05; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tree_link
    ADD CONSTRAINT fk_tgankaahxgr4p0mw4opafah05 FOREIGN KEY (subnode_id) REFERENCES tree_node(id);


--
-- Name: tree_arrangement_base_arrangement_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tree_arrangement
    ADD CONSTRAINT tree_arrangement_base_arrangement_id_fkey FOREIGN KEY (base_arrangement_id) REFERENCES tree_arrangement(id);


--
-- Name: tree_arrangement_namespace_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tree_arrangement
    ADD CONSTRAINT tree_arrangement_namespace_id_fkey FOREIGN KEY (namespace_id) REFERENCES namespace(id);


--
-- Name: tree_event_namespace_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tree_event
    ADD CONSTRAINT tree_event_namespace_id_fkey FOREIGN KEY (namespace_id) REFERENCES namespace(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

