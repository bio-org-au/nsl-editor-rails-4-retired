drop table bulk_name_processed;

create table
       bulk_name_processed (
        id bigint not null default nextval('nsl_global_seq'::regclass) primary key,
        genus varchar,
        species varchar,
        subsp_var varchar,
        authority varchar,
        preferred_authority varchar,
        page varchar,
        act_page varchar,
        nsw_page varchar,
        nt_page varchar,
        qld_page varchar,
        sa_page varchar,
        tas_page varchar,
        vic_page varchar,
        wa_page varchar,
        ait_page varchar,
        constructed_name varchar,
        matched_name_id bigint,
        matched_name_count bigint not null default 0,
        inferred_rank varchar not null default 'unknown', 
        autonym boolean not null default false,
        phrase_name boolean not null default false,
        constructed_page varchar
       );

\echo load data into processing table

insert into bulk_name_processed(genus,
       species,subsp_var,authority, preferred_authority, page,
      act_page, nsw_page, nt_page, qld_page, sa_page, tas_page,
      vic_page, wa_page, ait_page
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
			        ),page, act_page, nsw_page, nt_page, qld_page, sa_page, tas_page,
              vic_page, wa_page, ait_page
  from bulk_name_raw;


\echo remove the one csv heading record from bulk table if they slipped through.

delete from bulk_name_processed
where genus = 'Genus'
  and species = 'sp.'
  and act_page = 'ACT';

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
   set constructed_name = genus || ' ' || species 
 where constructed_name is null
   and authority is null
   and preferred_authority is null
   and subsp_var is null;

\echo construct species names with a preferred authority

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
   and subsp_var != concat('var. ',species);

\echo construct autonym variety names

update bulk_name_processed
   set constructed_name = genus || ' ' || species || ' ' || coalesce(preferred_authority, authority) || ' ' || subsp_var
 where constructed_name is null
   and subsp_var like 'var. %'
   and authority is not null
   and subsp_var = concat('var. ', species);

\echo construct non-autonym subspecies variety names - e.g. subsp. x var. y

update bulk_name_processed
   set constructed_name = genus || ' ' || species || ' ' || substring(subsp_var,position('var. ' in subsp_var)) || ' ' || coalesce(preferred_authority, authority)
 where constructed_name is null
   and subsp_var like 'subsp. % var. %'
	 and authority is not null
	 and subsp_var != ('subsp. '||species||' var. '||species);

\echo construct autonymic subspecies variety names - e.g. subsp. x var. y

update bulk_name_processed
   set constructed_name = genus || ' ' || species || ' ' || coalesce(preferred_authority, authority) || ' ' || substring(subsp_var,position('var. ' in subsp_var))
 where constructed_name is null
   and subsp_var like 'subsp. % var. %'
	 and authority is not null
	 and subsp_var = ('subsp. '||species||' var. '||species);


\echo construct non-autonym subspecies names

update bulk_name_processed
   set constructed_name = genus || ' ' || species || ' ' || subsp_var || ' ' || coalesce(preferred_authority, authority)
 where constructed_name is null
   and subsp_var like 'subsp. %'
   and authority is not null
   and subsp_var != concat('subsp. ', species);

\echo construct autonym subspecies names

update bulk_name_processed
   set constructed_name = genus || ' ' || species || ' ' || coalesce(preferred_authority, authority) || ' ' || subsp_var
 where constructed_name is null
   and subsp_var like 'subsp. %'
   and authority is not null
   and subsp_var = concat('subsp. ', species);

\echo construct names without authority

update bulk_name_processed
   set constructed_name = genus || ' ' || species || ' ' || subsp_var
 where constructed_name is null
   and subsp_var is not null
   and authority is null;

\echo all records should now have constructed names

select count(*) from bulk_name_processed where constructed_name is null;

\echo run a simple match

update bulk_name_processed
   set matched_name_id = (
    select min(id)
      from name
    where full_name = bulk_name_processed.constructed_name
      and duplicate_of_id is null
    group by full_name
    having count(*) = 1
       ),
    matched_name_count = 
    (
    select count(*)
      from name
    where full_name = bulk_name_processed.constructed_name
      and duplicate_of_id is null
    group by full_name
    having count(*) = 1
    )
  where exists ( select null
                   from name
                  where full_name = bulk_name_processed.constructed_name
                    and duplicate_of_id is null 
                  group by full_name
                  having count(*) = 1)
   and constructed_name is not null
   and matched_name_id is null;

\echo run a match on unmatched that excludes non-instance names

update bulk_name_processed
   set matched_name_id = (
    select min(id)
      from name
    where full_name = bulk_name_processed.constructed_name
      and duplicate_of_id is null
      and exists (select null from instance where name_id = name.id)
    group by full_name
    having count(*) = 1
       ),
    matched_name_count = (select count(*)
      from name
    where full_name = bulk_name_processed.constructed_name
      and duplicate_of_id is null
      and exists (select null from instance where name_id = name.id)
    group by full_name
    having count(*) = 1)
  where exists ( select null
                   from name
                  where full_name = bulk_name_processed.constructed_name
                    and duplicate_of_id is null 
                    and exists (select null from instance where name_id = name.id)
                  group by full_name
                  having count(*) = 1 )
   and constructed_name is not null
   and matched_name_id is null;

\echo run a match on unmatched that excludes nom_inval names
\echo

update bulk_name_processed
   set matched_name_id = (
    select min(id)
      from name
    where full_name = bulk_name_processed.constructed_name
      and duplicate_of_id is null
      and not exists (select null from name_status where name.name_status_id = name_status.id and nom_inval)
    group by full_name
    having count(*) = 1
       ),
    matched_name_count = (select count(*)
      from name
    where full_name = bulk_name_processed.constructed_name
      and duplicate_of_id is null
      and not exists (select null from name_status where name.name_status_id = name_status.id and nom_inval)
    group by full_name
    having count(*) = 1)
  where exists ( select null
                   from name
                  where full_name = bulk_name_processed.constructed_name
                    and duplicate_of_id is null 
                    and not exists (select null from name_status where name.name_status_id = name_status.id and nom_inval) 
                    group by full_name
                    having count(*) = 1)
   and constructed_name is not null
   and matched_name_id is null;


\echo run a match on unmatched that excludes nom_inval and no-instance names
\echo

update bulk_name_processed
   set matched_name_id = (
    select min(id)
      from name
    where full_name = bulk_name_processed.constructed_name
      and duplicate_of_id is null
      and not exists (select null from name_status where name.name_status_id = name_status.id and nom_inval)
      and exists (select null from instance i where i.name_id = name.id)
    group by full_name
    having count(*) = 1
       ),
    matched_name_count = (select count(*)
      from name
    where full_name = bulk_name_processed.constructed_name
      and duplicate_of_id is null
      and not exists (select null from name_status where name.name_status_id = name_status.id and nom_inval)
      and exists (select null from instance i where i.name_id = name.id)
    group by full_name
    having count(*) = 1)
  where exists ( select null
                   from name
                  where full_name = bulk_name_processed.constructed_name
                    and duplicate_of_id is null 
                    and not exists (select null from name_status where name.name_status_id = name_status.id and nom_inval) 
                    and exists (select null from instance i where i.name_id = name.id)
                    group by full_name
                    having count(*) = 1)
   and constructed_name is not null
   and matched_name_id is null;



\echo run a min(id) match on leftovers
\echo

update bulk_name_processed
   set matched_name_id = (
    select min(id)
      from name
    where full_name = bulk_name_processed.constructed_name
      and duplicate_of_id is null
    group by full_name
       ),
       matched_name_count = (
    select coalesce(count(*),0)
      from name
    where full_name = bulk_name_processed.constructed_name
      and duplicate_of_id is null
    group by full_name
       )
  where exists ( select null
                   from name
                  where full_name = bulk_name_processed.constructed_name
                    and duplicate_of_id is null )
    and constructed_name is not null
    and matched_name_id is null;

\echo summary
\echo
select inferred_rank, matched_name_count, count(*)
  from bulk_name_processed
 where constructed_name is not null
 group by inferred_rank, matched_name_count
 order by 1,2;


select inferred_rank, matched_name_count, count(*)
  from bulk_name_processed
 where constructed_name is not null
 group by inferred_rank, matched_name_count
 order by 1,2;

\echo Non-matched names with a matching legitimate simple name
\echo

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

\echo match leftovers on simple name
\echo

update bulk_name_processed
   set matched_name_id = (
    select min(id)
      from name
    where simple_name = bulk_name_processed.constructed_name
      and duplicate_of_id is null
    group by full_name
    having count(*) = 1
       ),
    matched_name_count = 
    (
    select count(*)
      from name
    where simple_name = bulk_name_processed.constructed_name
      and duplicate_of_id is null
    group by full_name
    having count(*) = 1
    )
  where exists ( select null
                   from name
                  where simple_name = bulk_name_processed.constructed_name
                    and duplicate_of_id is null 
                  group by full_name
                  having count(*) = 1)
   and constructed_name is not null
   and matched_name_id is null;

\echo Review results
\echo

 select inferred_rank, matched_name_count, count(*)
   from bulk_name_processed
  where constructed_name is not null
  group by inferred_rank, matched_name_count
  order by 1,2;


\echo Non-matched names
\echo

select genus, species, subsp_var, authority, preferred_authority, constructed_name
  from bulk_name_processed bnp
 where matched_name_count = 0
 order by genus, species;
 
\echo Non-matched names - just the raw data
\echo

select genus, species, subsp_var, authority, preferred_authority
   from bulk_name_processed bnp
  where matched_name_count = 0
  order by genus, species;
 
\echo Non-matched names - just the constructed names
\echo

	select constructed_name
	  from bulk_name_processed bnp
	 where matched_name_count = 0
	 order by genus, species;

\echo Multi-matched names
\echo

select genus, species, subsp_var, authority, preferred_authority, constructed_name
  from bulk_name_processed bnp
 where matched_name_count > 1
order by genus, species;


\echo Remaining unmatched or multi-matched
\echo

	select inferred_rank, matched_name_count, count(*)
	  from bulk_name_processed
	 group by inferred_rank, matched_name_count
	 having matched_name_count != 1 
	 order by 1,2;


\echo Count all raw records
select count(*) from bulk_name_raw;

\echo Count all processing records: should equal previous
select count(*) from bulk_name_processed;

\echo Count records with no constructed name: 0 is a good result
select count(*) from bulk_name_processed where constructed_name is null;

\echo count records with no matched name (count is 0): these will be created
select count(*) from bulk_name_processed where matched_name_count = 0;

\echo count records with no matched name (matched_id is null): this should equal the previous count
select count(*) from bulk_name_processed where matched_name_id is null;

\echo big picture
\echo
select matched_name_count, count(*) from bulk_name_processed group by matched_name_count order by 1;
