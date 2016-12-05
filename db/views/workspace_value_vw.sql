create view workspace_value_vw as
select name_node_link.id name_node_link_id,
       name_node.id name_node_id,
       instance.id instance_id,
       name_sub_link.type_uri_id_part,
       name_sub_link.type_uri_ns_part_id,
       workspace.id workspace_id,
       name_sub_link.type_uri_id_part name_sub_link_type_uri_id,
       name_sub_link_value.link_uri_id_part name_sub_link_value_link_uri_id_part,
       name_sub_link.type_uri_id_part field_name,
       value_node.literal field_value
from tree_link name_node_link
     inner join tree_node name_node
     on name_node_link.subnode_id = name_node.id
     inner join instance
     on name_node.instance_id = instance.id
     inner join tree_link name_sub_link
     on name_node.id = name_sub_link.supernode_id 
     inner join tree_value_uri name_sub_link_value
     on name_sub_link.type_uri_id_part = name_sub_link_value.link_uri_id_part
     inner join tree_arrangement workspace
     on name_node.tree_arrangement_id = workspace.id
     inner join tree_node value_node
     on name_sub_link.subnode_id = value_node.id
;

grant select on workspace_value_vw to webapni
;


