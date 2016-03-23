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

select count(*) from bulk_name_raw;




