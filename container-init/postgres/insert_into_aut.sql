insert into
auth.oauth_client_details (
	client_id, 
	resource_ids, 
	client_secret, 
	scope, 
	authorized_grant_types, 
	web_server_redirect_uri, 
	authorities, 
	access_token_validity, 
	refresh_token_validity, 
	additional_information, 
	auto_approve, 
	simultaneous_session)
values( 
	'079a8725-b174-4340-87bc-a7eecc5d02de', 
	'resource_id1 resource_id2', 
	'gJ0tS4bV5pB0yO8vP2wX8bP5uD8oE3mL2sM8bY5yN6sW0yO4eH', 
	'Wallet-cards:read:user', 
	'password refresh_token', 
	'127.0.0.1:8080', 
	'athoritie1 authoritie2', 
	8520, 
	9630, 
	'aditional information description', 
	'true', 
'false' );