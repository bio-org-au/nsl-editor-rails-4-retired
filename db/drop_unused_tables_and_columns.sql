drop table trashed_item;
drop table trashing_event;
alter table author drop column trash;
alter table help_topic drop column trash;
alter table instance drop column trash;
alter table name drop column trash;
alter table reference drop column trash;
alter table user_query drop column trash;
