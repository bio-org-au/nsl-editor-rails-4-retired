\echo Count raw records

select count(*) from bulk_name_raw;


\echo Copy raw records into processing area

insert into bulk_name_processed(genus,
       species,subspecies_variety,authority
     )
select genus, species, subspecies_variety,authority
  from bulk_name_raw;

\echo Remove heading row

delete from bulk_name_processed where genus = 'Genus' and species = 'Species';

\echo Remove meaningless rows

delete from bulk_name_processed
 where genus is null
   and species is null;

\echo set inferred rank

update bulk_name_processed
   set inferred_rank = 'variety'
 where subspecies_variety like 'variety %';

update bulk_name_processed
   set inferred_rank = 'subspecies'
 where subspecies_variety like 'subspecies %';

update bulk_name_processed
   set inferred_rank = 'species'
 where subspecies_variety is null;


\echo construct species names

update bulk_name_processed
   set constructed_name = genus || ' ' || species || ' ' || authority
 where constructed_name is null
   and authority is not null
   and subspecies_variety is null;

\echo construct variety names

update bulk_name_processed
   set constructed_name = genus || ' ' || species || ' var. ' || substring(subspecies_variety,
       9
     ) || ' ' || authority
 where constructed_name is null
   and subspecies_variety like 'variety%'
   and authority is not null;

\echo construct subspecies names

update bulk_name_processed
   set constructed_name = genus || ' ' || species || ' ' || authority || ' subsp. ' || substring(subspecies_variety,
       12
     )
 where constructed_name is null
   and subspecies_variety like 'subspecies %'
   and authority is not null;


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
