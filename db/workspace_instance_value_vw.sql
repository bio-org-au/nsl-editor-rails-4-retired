create view workspace_instance_value_vw as
select workspace.id workspace_id,
       instance.id instance_id,
       tree_node.tree_arrangement_id,
       tree_node.id tree_node_id,
       tree_link.id tree_link_id,
       workspace.title workspace_title,
       tree_uri_ns.label tree_uri_ns_label,
       tree_link.type_uri_id_part tree_link_type_uri_id_part,
       base.label base_label,
       base_value.id base_value_uri_id,
       base_value.link_uri_ns_part_id base_link_uri_ns_part,
       link_value.link_uri_ns_part_id link_uri_ns_part,
       link_value.id link_value_uri_id,
       base_ns.title,
       tree_link.subnode_id,
       value_node.type_uri_id_part,
       link_value.link_uri_id_part link_uri_id_part,
       base_value.link_uri_id_part base_link_uri_id_part,
       value_node.literal
  from instance
 inner join tree_node
    on instance.id = tree_node.instance_id
 inner join tree_link 
    on tree_node.id = tree_link.supernode_id
 inner join tree_value_uri link_value
    on tree_link.type_uri_id_part = link_value.link_uri_id_part
 inner join tree_uri_ns 
    on tree_link.type_uri_ns_part_id = tree_uri_ns.id
 inner join tree_arrangement workspace
    on tree_node.tree_arrangement_id = workspace.id
 inner join tree_arrangement base
    on workspace.base_arrangement_id = base.id
 inner join tree_value_uri base_value
    on base.id = base_value.root_id
 inner join tree_uri_ns base_ns
    on base_value.node_uri_ns_part_id = base_ns.id
 inner join tree_node value_node
    on tree_link.subnode_id = value_node.id
 where instance.id = 612278
   and link_value.link_uri_id_part = base_value.link_uri_id_part
