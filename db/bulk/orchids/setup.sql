drop table bulk_name_raw;

create table bulk_name_raw (
  genus varchar,
  species varchar,
  subsp_var varchar,
  authority varchar,
  preferred_authority varchar,
  page varchar,
  page_extra varchar
);

--export spreadsheet to csv
--edit spreadsheet to remove heading, empty line


select count(*) from bulk_name_raw;

\copy bulk_name_raw from '~/Downloads/orchid-checklist.csv' delimiter ',' csv;

delete from bulk_name_raw
 where genus = 'Genus'
   and species = 'sp.'
   and subsp_var = 'subsp./var.'
   and authority = 'Taxonomic Authority';

delete from bulk_name_raw
 where genus is null
   and species is null
   and subsp_var is null
   and authority is null;


select count(*) from bulk_name_raw;




