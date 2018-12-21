puts "First line of config"
Rails.configuration.mapper_root_url = 'http://localhost:9090/nsl-mapper/'
Rails.configuration.tree_editor_url = 'http://localhost:9090/nsl/tree-editor/'
Rails.configuration.mapper_shard = 'apni'
Rails.configuration.api_key = 'test-api-key'
Rails.configuration.environment = 'test'

Rails.configuration.services_clientside_root_url = 'http://localhost:9090/'
Rails.configuration.nsl_links = 'http://biodiversity.org.au/nsl/services/'
Rails.configuration.services = 'http://localhost:9090/nsl/services/'
Rails.configuration.name_services = 'http://localhost:9090/nsl/services/rest/name/apni/'
Rails.configuration.reference_services = 'http://localhost:9090/nsl/services/rest/reference/apni/'

Rails.configuration.session_key_tag = 'local_test'

Rails.configuration.ldap_admin_username = "uid=admin,ou=system"
Rails.configuration.ldap_admin_password = "secret"
Rails.configuration.ldap_base = "dc=com"
Rails.configuration.ldap_host = 'localhost'
Rails.configuration.ldap_port = 10389
Rails.configuration.ldap_users = "ou=users,dc=example,dc=com"
Rails.configuration.ldap_groups = "ou=groups,dc=example,dc=com"

Rails.configuration.nsl_linker = 'http://localhost:9090/nsl/mapper/'
puts "Last line of config"

