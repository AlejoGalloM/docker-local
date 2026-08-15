CREATE SCHEMA IF NOT EXISTS channel_management;

CREATE TABLE IF NOT EXISTS channel_management.language(
   id          bigserial primary key,
   description       varchar(50) NOT NULL
);

CREATE TABLE IF NOT EXISTS channel_management.transversal_message(
   technical_code       varchar(8) NOT NULL,
   channel                varchar(4) NOT NULL,
   origin             varchar(4096) NOT NULL,
   id_language             bigint,
   technical_exception       varchar(4096) NOT NULL,
   user_message         varchar(4096),
   type               varchar(50),
   message_type         varchar(50),
   transaction_code      varchar(10),
   itc_homologated_code   varchar(10),
   response_type        varchar(50),
   primary key(technical_code ,channel, origin, id_language),
   CONSTRAINT fk_id_language FOREIGN KEY (id_language) REFERENCES channel_management.language(id)
);