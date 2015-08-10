select parent_ref_type.name parent_type, ref_type.name ref_type,count(*)
from reference ref
     inner join
     reference parent_ref
     on ref.parent_id = parent_ref.id
     inner join
     ref_type
     on ref.ref_type_id = ref_type.id
     inner join
     ref_type parent_ref_type
     on parent_ref.ref_type_id = parent_ref_type.id
group by parent_ref_type.name, ref_type.name
order by count(*) desc


select parent_ref.id,parent_ref.source_system, parent_ref.source_id,
       parent_ref_type.name parent_type, parent_ref.title, ref_type.name ref_type, ref.title,
       ref.id,ref.source_system, ref.source_id
from reference ref
     inner join
     reference parent_ref
     on ref.parent_id = parent_ref.id
     inner join
     ref_type
     on ref.ref_type_id = ref_type.id
     inner join
     ref_type parent_ref_type
     on parent_ref.ref_type_id = parent_ref_type.id
where parent_ref_type.name = 'Book'
  and ref_type.name = 'Unknown'
limit 1;



select parent_ref.id,parent_ref.source_system, parent_ref.source_id,
       parent_ref_type.name parent_type, parent_ref.title, ref_type.name ref_type, ref.title,
       ref.id,ref.source_system, ref.source_id
from reference ref
     inner join
     reference parent_ref
     on ref.parent_id = parent_ref.id
     inner join
     ref_type
     on ref.ref_type_id = ref_type.id
     inner join
     ref_type parent_ref_type
     on parent_ref.ref_type_id = parent_ref_type.id
where ref.title = 'Tamaricaceae';


