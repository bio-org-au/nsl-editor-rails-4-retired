This directory contains scripts and files created when bulk loading orchids.

General process:
-  import csv data into a raw table (setup.sql)
-  do some sort of processing of that data if necessary putting
   results into a "processed" table (various load scripts)
-  produce reports for review (also from load.sql)
-  insert records for selected processed records (various insert_ sql scripts)


Rules

- for each record, look for an exact match name
  - if matches == 1
      you just need to create an instance
  - elsif matches > 1
      you need more information to get a new match
  - else 0 matches
      you need to create a name and an instance (haven't done this yet)



