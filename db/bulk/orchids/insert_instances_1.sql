insert into instance (
 created_at,
 created_by,
 instance_type_id,
 name_id,
 namespace_id,
 page,
 page_qualifier,
 parent_id,
 reference_id,
 updated_at,
 updated_by)
 select now(),
        'bulk',
        (select id from instance_type where name = 'secondary reference'),
        matched_name_id,
        (select id from namespace where name = (select value from shard_config where name = 'name space')),
        array_to_string(regexp_split_to_array(regexp_replace(concat(page,' ',act_page,' ',nsw_page, ' ', nt_page, ' ', qld_page, ' ', sa_page, ' ', tas_page, ' ', vic_page, ' ', wa_page, ' ', ait_page),' +$',''),' +'),', '),
        null,
        null,
        (select id from reference where citation = 'Backhouse, G.N., Bates, R.J., Brown, A.P. & Copeland, L.M. (2016), Checklist of the orchids of Australia including its island territories'),
        now(),
        'bulk'
   from bulk_name_processed
  where matched_name_count = 1
    and concat(page,act_page, nsw_page, nt_page, qld_page, sa_page, tas_page, vic_page, wa_page, ait_page) is not null
