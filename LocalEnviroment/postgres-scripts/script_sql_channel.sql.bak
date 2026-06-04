--
-- PostgreSQL database dump
--

-- Dumped from database version 12.2 (Debian 12.2-2.pgdg100+1)
-- Dumped by pg_dump version 13.0

-- Started on 2020-11-24 16:16:58

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 9 (class 2615 OID 16385)
-- Name: auth; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA auth;


ALTER SCHEMA auth OWNER TO postgres;

--
-- TOC entry 6 (class 2615 OID 16414)
-- Name: channeltrx; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA channeltrx;


ALTER SCHEMA channeltrx OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 207 (class 1259 OID 16404)
-- Name: authentication; Type: TABLE; Schema: auth; Owner: postgres
--

CREATE TABLE auth.authentication (
    id bigint NOT NULL,
    user_name character varying(256),
    channel_id character varying(256),
    application_id character varying(256),
    authentication_time timestamp with time zone,
    authentication_ip character varying(256),
    authentication_device character varying(256),
    access_token character varying(4096),
    refresh_token character varying(256)
);


ALTER TABLE auth.authentication OWNER TO postgres;

--
-- TOC entry 206 (class 1259 OID 16402)
-- Name: authentication_id_seq; Type: SEQUENCE; Schema: auth; Owner: postgres
--

CREATE SEQUENCE auth.authentication_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE auth.authentication_id_seq OWNER TO postgres;

--
-- TOC entry 2967 (class 0 OID 0)
-- Dependencies: 206
-- Name: authentication_id_seq; Type: SEQUENCE OWNED BY; Schema: auth; Owner: postgres
--

ALTER SEQUENCE auth.authentication_id_seq OWNED BY auth.authentication.id;


--
-- TOC entry 204 (class 1259 OID 16386)
-- Name: oauth_client_details; Type: TABLE; Schema: auth; Owner: postgres
--

CREATE TABLE auth.oauth_client_details (
    client_id character varying(256) NOT NULL,
    resource_ids character varying(256),
    client_secret character varying(256),
    scope character varying(256),
    authorized_grant_types character varying(256),
    web_server_redirect_uri character varying(256),
    authorities character varying(256),
    access_token_validity integer,
    refresh_token_validity integer,
    additional_information character varying(4096),
    auto_approve character varying(256),
    simultaneous_session character varying(256)
);


ALTER TABLE auth.oauth_client_details OWNER TO postgres;

--
-- TOC entry 205 (class 1259 OID 16394)
-- Name: oauth_refresh_token; Type: TABLE; Schema: auth; Owner: postgres
--

CREATE TABLE auth.oauth_refresh_token (
    token character varying(256) NOT NULL,
    user_name character varying(256),
    client_id character varying(256)
);


ALTER TABLE auth.oauth_refresh_token OWNER TO postgres;

--
-- TOC entry 208 (class 1259 OID 16440)
-- Name: channel; Type: TABLE; Schema: channeltrx; Owner: postgres
--

CREATE TABLE channeltrx.channel (
    code character varying(4) NOT NULL,
    description character varying(100),
    state character varying(100),
    previous_state character varying(100),
    active boolean,
    created_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE channeltrx.channel OWNER TO postgres;

--
-- TOC entry 209 (class 1259 OID 16443)
-- Name: channel_state; Type: TABLE; Schema: channeltrx; Owner: postgres
--

CREATE TABLE channeltrx.channel_state (
    code character varying(100) NOT NULL
);


ALTER TABLE channeltrx.channel_state OWNER TO postgres;

--
-- TOC entry 210 (class 1259 OID 16446)
-- Name: channel_transaction; Type: TABLE; Schema: channeltrx; Owner: postgres
--

CREATE TABLE channeltrx.channel_transaction (
    channel_code character varying(4) NOT NULL,
    transaction_code character varying(4) NOT NULL,
    state character varying(100),
    active boolean,
    uri character varying(100),
    method_http character varying(100),
    created_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    description character varying(100)
);


ALTER TABLE channeltrx.channel_transaction OWNER TO postgres;

--
-- TOC entry 211 (class 1259 OID 16449)
-- Name: channel_transaction_state; Type: TABLE; Schema: channeltrx; Owner: postgres
--

CREATE TABLE channeltrx.channel_transaction_state (
    code character varying(100) NOT NULL
);


ALTER TABLE channeltrx.channel_transaction_state OWNER TO postgres;

--
-- TOC entry 212 (class 1259 OID 16452)
-- Name: transaction; Type: TABLE; Schema: channeltrx; Owner: postgres
--

CREATE TABLE channeltrx.transaction (
    code character varying(4) NOT NULL,
    description character varying(100)
);


ALTER TABLE channeltrx.transaction OWNER TO postgres;

--
-- TOC entry 2810 (class 2604 OID 16407)
-- Name: authentication id; Type: DEFAULT; Schema: auth; Owner: postgres
--

ALTER TABLE ONLY auth.authentication ALTER COLUMN id SET DEFAULT nextval('auth.authentication_id_seq'::regclass);


--
-- TOC entry 2820 (class 2606 OID 16412)
-- Name: authentication authentication_pkey; Type: CONSTRAINT; Schema: auth; Owner: postgres
--

ALTER TABLE ONLY auth.authentication
    ADD CONSTRAINT authentication_pkey PRIMARY KEY (id);


--
-- TOC entry 2816 (class 2606 OID 16393)
-- Name: oauth_client_details oauth_client_details_pkey; Type: CONSTRAINT; Schema: auth; Owner: postgres
--

ALTER TABLE ONLY auth.oauth_client_details
    ADD CONSTRAINT oauth_client_details_pkey PRIMARY KEY (client_id);


--
-- TOC entry 2818 (class 2606 OID 16401)
-- Name: oauth_refresh_token oauth_refresh_token_pkey; Type: CONSTRAINT; Schema: auth; Owner: postgres
--

ALTER TABLE ONLY auth.oauth_refresh_token
    ADD CONSTRAINT oauth_refresh_token_pkey PRIMARY KEY (token);


--
-- TOC entry 2823 (class 2606 OID 16456)
-- Name: channel channel_pkey; Type: CONSTRAINT; Schema: channeltrx; Owner: postgres
--

ALTER TABLE ONLY channeltrx.channel
    ADD CONSTRAINT channel_pkey PRIMARY KEY (code);


--
-- TOC entry 2825 (class 2606 OID 16458)
-- Name: channel_state channel_state_pkey; Type: CONSTRAINT; Schema: channeltrx; Owner: postgres
--

ALTER TABLE ONLY channeltrx.channel_state
    ADD CONSTRAINT channel_state_pkey PRIMARY KEY (code);


--
-- TOC entry 2827 (class 2606 OID 16460)
-- Name: channel_transaction channel_transaction_pkey; Type: CONSTRAINT; Schema: channeltrx; Owner: postgres
--

ALTER TABLE ONLY channeltrx.channel_transaction
    ADD CONSTRAINT channel_transaction_pkey PRIMARY KEY (channel_code, transaction_code);


--
-- TOC entry 2829 (class 2606 OID 16462)
-- Name: channel_transaction_state channel_transaction_state_pkey; Type: CONSTRAINT; Schema: channeltrx; Owner: postgres
--

ALTER TABLE ONLY channeltrx.channel_transaction_state
    ADD CONSTRAINT channel_transaction_state_pkey PRIMARY KEY (code);


--
-- TOC entry 2831 (class 2606 OID 16464)
-- Name: transaction transaction_pkey; Type: CONSTRAINT; Schema: channeltrx; Owner: postgres
--

ALTER TABLE ONLY channeltrx.transaction
    ADD CONSTRAINT transaction_pkey PRIMARY KEY (code);


--
-- TOC entry 2821 (class 1259 OID 16413)
-- Name: authentication_uk; Type: INDEX; Schema: auth; Owner: postgres
--

CREATE UNIQUE INDEX authentication_uk ON auth.authentication USING btree (user_name, channel_id);


--
-- TOC entry 2833 (class 2606 OID 16465)
-- Name: channel_transaction channel_code_fkey; Type: FK CONSTRAINT; Schema: channeltrx; Owner: postgres
--

ALTER TABLE ONLY channeltrx.channel_transaction
    ADD CONSTRAINT channel_code_fkey FOREIGN KEY (channel_code) REFERENCES channeltrx.channel(code);


--
-- TOC entry 2832 (class 2606 OID 16470)
-- Name: channel channel_state_fkey; Type: FK CONSTRAINT; Schema: channeltrx; Owner: postgres
--

ALTER TABLE ONLY channeltrx.channel
    ADD CONSTRAINT channel_state_fkey FOREIGN KEY (state) REFERENCES channeltrx.channel_state(code);


--
-- TOC entry 2834 (class 2606 OID 16475)
-- Name: channel_transaction channel_transaction_state_fkey; Type: FK CONSTRAINT; Schema: channeltrx; Owner: postgres
--

ALTER TABLE ONLY channeltrx.channel_transaction
    ADD CONSTRAINT channel_transaction_state_fkey FOREIGN KEY (state) REFERENCES channeltrx.channel_transaction_state(code);


--
-- TOC entry 2835 (class 2606 OID 16480)
-- Name: channel_transaction transaction_code_fkey; Type: FK CONSTRAINT; Schema: channeltrx; Owner: postgres
--

ALTER TABLE ONLY channeltrx.channel_transaction
    ADD CONSTRAINT transaction_code_fkey FOREIGN KEY (transaction_code) REFERENCES channeltrx.transaction(code);


-- Completed on 2020-11-24 16:16:59

--
-- PostgreSQL database dump complete
--

