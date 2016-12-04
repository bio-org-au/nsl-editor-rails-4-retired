create or replace view workspace_value_namespace_vw as
select workspace.id "workspace_id", workspace.title "workspace_title", base.label "base_tree_label",
       value.label "value_label", value.link_uri_id_part "value_link_uri_id_part",
       value.node_uri_id_part "value_node_uri_id_part",
       value.node_uri_ns_part_id "Value_node_uri_ns_part_id", value.title "value_title",
       node_namespace.description "node_namespace_description",
       node_namespace.id_mapper_namespace_id "node_namespace_id_mapper_namespace_id",
       node_namespace.id_mapper_system "node_namespace_id_mapper_system",
       node_namespace.label "node_namespace_label",
       node_namespace.owner_uri_id_part "node_namespace_owner_uri_id_part",
       node_namespace.owner_uri_ns_part_id "node_namespace_owner_uri_ns_part_id",
       node_namespace.title "node_namespace_title",
       node_namespace.uri "node_namespace_uri",
       link_namespace.description "link_namespace_description",
       link_namespace.id_mapper_namespace_id "link_namespace_id_mapper_namespace_id",
       link_namespace.id_mapper_system "link_namespace_id_mapper_system",
       link_namespace.label "link_namespace_label",
       link_namespace.owner_uri_id_part "link_namespace_owner_uri_id_part",
       link_namespace.owner_uri_ns_part_id "link_namespace_owner_uri_ns_part_id",
       link_namespace.title "link_namespace_title",
       link_namespace.uri "link_namespace_uri"
  from tree_arrangement workspace
 inner join tree_arrangement base
    on workspace.base_arrangement_id = base.id
 inner join tree_value_uri value
    on base.id = value.root_id
 inner join tree_uri_ns node_namespace
    on value.node_uri_ns_part_id = node_namespace.id
 inner join tree_uri_ns link_namespace
    on value.link_uri_ns_part_id = link_namespace.id
;

grant select on workspace_value_namespace_vw to webapni;



