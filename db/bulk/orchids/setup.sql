\! echo "Start of setup"

\! echo drop table bulk_name_raw

drop table bulk_name_raw;

\! echo create table bulk_name_raw 

create table bulk_name_raw (
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
  nominated_id integer
);

\! echo 'Count records in bulk_name_raw. Expect 0.'

select count(*) from bulk_name_raw;


\! echo 'Load from csv into raw'

\copy bulk_name_raw from '~/Downloads/orchid-many-matches.csv' delimiter ',' csv;

\! echo 'Count records in bulk_name_raw. Expect > 0.'

select count(*) from bulk_name_raw;



\! echo 'Delete possible csv heading row; expect 0 or 1'

delete from bulk_name_raw
 where genus = 'Genus'
   and species = 'sp.'
   and subsp_var = 'subsp./var.'
   and authority = 'Taxonomic Authority';

\! echo 'Delete empty rows; expect ?'

delete from bulk_name_raw
 where genus is null
   and species is null
   and subsp_var is null
   and authority is null;


\! echo 'Count records in bulk_name_raw. Expect > 0.'

select count(*) from bulk_name_raw;




