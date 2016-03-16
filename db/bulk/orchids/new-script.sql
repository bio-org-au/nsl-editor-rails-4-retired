drop table bulk_name_processed;

create table
       bulk_name_processed (
        id bigint not null default nextval('nsl_global_seq'::regclass) primary key,
        genus varchar,species varchar,subsp_var varchar,authority varchar, preferred_authority varchar,
        page varchar, page_extra varchar, constructed_name varchar,
        matched_name_id bigint, matched_name_count bigint,
       inferred_rank varchar not null default 'unknown', 
      autonym boolean not null default false,
      phrase_name boolean not null default false
       );

\ echo load data into processing table

insert into bulk_name_processed(genus,
       species,subsp_var,authority, preferred_authority, page,page_extra
     )
select trim(
        both
  from genus
       ), trim(
        both
  from species
       ), trim(
        both
  from subsp_var
       ),trim(
        both
  from authority
       ),
			 trim(
			         both
			   from preferred_authority
			        ),page,page_extra
  from bulk_name_raw;


\echo set inferred rank

update bulk_name_processed
   set inferred_rank = 'variety'
 where subsp_var like 'var. %';

update bulk_name_processed
   set inferred_rank = 'subspecies'
 where subsp_var like 'subsp. %';

update bulk_name_processed
   set inferred_rank = 'species'
 where subsp_var is null;


\echo construct species names

update bulk_name_processed
   set constructed_name = genus || ' ' || species || ' ' || coalesce(preferred_authority, authority)
 where constructed_name is null
   and authority is not null
   and subsp_var is null;

\echo construct non-autonym variety names

update bulk_name_processed
   set constructed_name = genus || ' ' || species || ' ' || subsp_var || ' ' || coalesce(preferred_authority, authority)
 where constructed_name is null
   and subsp_var like 'var. %'
   and authority is not null
   and subsp_var != 'var. '||species;

\echo construct autonym variety names

update bulk_name_processed
   set constructed_name = genus || ' ' || species || ' ' || coalesce(preferred_authority, authority) || ' ' || subsp_var
 where constructed_name is null
   and subsp_var like 'var. %'
   and authority is not null
   and subsp_var = 'var. '||species;

\echo construct non-autonym subspecies names

update bulk_name_processed
   set constructed_name = genus || ' ' || species || ' ' || subsp_var || ' ' || coalesce(preferred_authority, authority)
 where constructed_name is null
   and subsp_var like 'subsp. %'
   and authority is not null
   and subsp_var != 'subsp. '||species;

\echo construct autonym subspecies names

update bulk_name_processed
   set constructed_name = genus || ' ' || species || ' ' || coalesce(preferred_authority, authority) || ' ' || subsp_var
 where constructed_name is null
   and subsp_var like 'subsp. %'
   and authority is not null
   and subsp_var = 'subsp. '||species;

\echo construct names without authority

update bulk_name_processed
   set constructed_name = genus || ' ' || species || ' ' || subsp_var
 where constructed_name is null
   and subsp_var is not null
   and authority is null;

\echo all records should now have constructed names

select count(*) from bulk_name_processed where constructed_name is null;

\echo run a match

update bulk_name_processed
   set matched_name_id = (
    select min(id)
      from name
    where full_name = bulk_name_processed.constructed_name
      and duplicate_of_id is null
       )
 where constructed_name is not null
   and matched_name_id is null;

\echo record mulitple matches count

update bulk_name_processed
   set matched_name_count = (
    select count(*)
      from name
    where full_name = bulk_name_processed.constructed_name
      and duplicate_of_id is null
       )
 where constructed_name is not null
   and matched_name_count is null;

\echo review results

select inferred_rank, matched_name_count, count(*)
  from bulk_name_processed
 where constructed_name is not null
 group by inferred_rank, matched_name_count
 order by 1,2;

\echo now deal with multiple matches

update bulk_name_processed
   set matched_name_id = (
    select min(name.id)
      from name
           inner join
           name_status ns
           on name.name_status_id = ns.id
    where full_name = bulk_name_processed.constructed_name
      and duplicate_of_id is null
      and ns.name = 'legitimate'
       )
 where constructed_name is not null
   and matched_name_count > 1;

update bulk_name_processed
   set matched_name_count = (
    select count(*)
      from name
           inner join
           name_status ns
           on name.name_status_id = ns.id
    where full_name = bulk_name_processed.constructed_name
      and duplicate_of_id is null
      and ns.name = 'legitimate'
       )
 where constructed_name is not null
   and matched_name_count > 1;

select inferred_rank, matched_name_count, count(*)
  from bulk_name_processed
 where constructed_name is not null
 group by inferred_rank, matched_name_count
 order by 1,2;


select genus, species, subsp_var, authority, preferred_authority,constructed_name
  from bulk_name_processed
 where subsp_var like 'var.%';

select genus, species, subsp_var, authority, preferred_authority, constructed_name
  from bulk_name_processed 
 where matched_name_count = 0
   and subsp_var is null;

select genus, species, subsp_var, authority, preferred_authority, constructed_name
  from bulk_name_processed 
 where matched_name_count = 0
   and subsp_var is not null;

select inferred_rank, matched_name_count, count(*)
  from bulk_name_processed
 where constructed_name is not null
 group by inferred_rank, matched_name_count
 order by 1,2;

\echo Non-matched names with a matching legitimate simple name

select genus, species, authority, preferred_authority, full_name
  from bulk_name_processed bnp
       inner join
       name on
       bnp.genus || ' ' || bnp.species = name.simple_name
       inner join 
       name_status ns
       on name.name_status_id = ns.id
 where matched_name_count = 0
   and ns.name = 'legitimate'
 order by genus, species;

