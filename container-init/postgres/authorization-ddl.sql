CREATE SCHEMA IF NOT EXISTS auth;

CREATE TABLE IF NOT EXISTS auth.oauth_client_details(
  client_id               varchar(256) primary key,
  resource_ids            varchar(256),
  client_secret           varchar(256),
  scope                   varchar(256),
  authorized_grant_types  varchar(256),
  web_server_redirect_uri varchar(256),
  authorities             varchar(256),
  access_token_validity   integer,
  refresh_token_validity  integer,
  additional_information  varchar(4096),
  auto_approve            varchar(256),
  simultaneous_session    varchar (256)
);

create TABLE IF NOT EXISTS auth.oauth_refresh_token(
  token     varchar(256) primary key,
  user_name varchar(256),
  client_id varchar(256)
);

create TABLE IF NOT EXISTS auth.authentication(
  id					bigserial primary key,
  user_name             varchar(256),
  channel_id            varchar(256),
  application_id        varchar(256),
  authentication_time   timestamp with time zone,
  authentication_ip     varchar(256),
  authentication_device varchar(256),
  access_token          varchar(4096),
  refresh_token         varchar(256)
);

create unique INDEX authentication_uk ON auth.authentication (user_name, channel_id);