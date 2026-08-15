CREATE SCHEMA channeltrx;

CREATE TABLE channeltrx.channel (
    code character varying(4) NOT NULL,
    description character varying(100),
    state character varying(100),
    active boolean,
    created_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE TABLE channeltrx.channel_state (
    code character varying(100) NOT NULL
);

CREATE TABLE channeltrx.channel_transaction (
    channel_code character varying(4) NOT NULL,
    transaction_code character varying(4) NOT NULL,
    state character varying(100),
    active boolean,
    uri character varying(100),
    method_http character varying(100),
    created_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE TABLE channeltrx.channel_transaction_state (
    code character varying(100) NOT NULL
);

CREATE TABLE channeltrx.transaction (
    code character varying(4) NOT NULL,
    description character varying(100)
);

ALTER TABLE ONLY channeltrx.channel
    ADD CONSTRAINT channel_pkey PRIMARY KEY (code);

ALTER TABLE ONLY channeltrx.channel_state
    ADD CONSTRAINT channel_state_pkey PRIMARY KEY (code);

ALTER TABLE ONLY channeltrx.channel_transaction
    ADD CONSTRAINT channel_transaction_pkey PRIMARY KEY (channel_code, transaction_code);

ALTER TABLE ONLY channeltrx.channel_transaction_state
    ADD CONSTRAINT channel_transaction_state_pkey PRIMARY KEY (code);

ALTER TABLE ONLY channeltrx.transaction
    ADD CONSTRAINT transaction_pkey PRIMARY KEY (code);

ALTER TABLE ONLY channeltrx.channel_transaction
    ADD CONSTRAINT channel_code_fkey FOREIGN KEY (channel_code) REFERENCES channeltrx.channel(code);

ALTER TABLE ONLY channeltrx.channel
    ADD CONSTRAINT channel_state_fkey FOREIGN KEY (state) REFERENCES channeltrx.channel_state(code);

ALTER TABLE ONLY channeltrx.channel_transaction
    ADD CONSTRAINT channel_transaction_state_fkey FOREIGN KEY (state) REFERENCES channeltrx.channel_transaction_state(code);

ALTER TABLE ONLY channeltrx.channel_transaction
    ADD CONSTRAINT transaction_code_fkey FOREIGN KEY (transaction_code) REFERENCES channeltrx.transaction(code);

ALTER TABLE channeltrx.channel ADD previous_state varchar(100) NOT NULL DEFAULT 'Active';

ALTER TABLE channeltrx.channel_transaction ADD previous_state varchar(100) NOT NULL DEFAULT 'Active';

ALTER TABLE ONLY channeltrx.channel
    ADD CONSTRAINT channel_previous_state_fkey FOREIGN KEY (previous_state) REFERENCES channeltrx.channel_state(code);

ALTER TABLE ONLY channeltrx.channel_transaction
    ADD CONSTRAINT channel_transaction_previous_state_fkey FOREIGN KEY (previous_state) REFERENCES channeltrx.channel_transaction_state(code);