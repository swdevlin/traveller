SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA IF NOT EXISTS public;


--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA public IS 'standard public schema';


--
-- Name: shared_extensions; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA IF NOT EXISTS shared_extensions;


--
-- Name: parsecs_set_hex_coordinates(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.parsecs_set_hex_coordinates() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.q := NEW.x;
  NEW.r := -NEW.y - ((NEW.x - (NEW.x & 1)) / 2);
  NEW.s := -NEW.q - NEW.r;
  RETURN NEW;
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: active_storage_attachments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_attachments (
    id bigint NOT NULL,
    blob_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    name character varying NOT NULL,
    record_id bigint NOT NULL,
    record_type character varying NOT NULL
);


--
-- Name: active_storage_attachments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_attachments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_attachments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_attachments_id_seq OWNED BY public.active_storage_attachments.id;


--
-- Name: active_storage_blobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_blobs (
    id bigint NOT NULL,
    byte_size bigint NOT NULL,
    checksum character varying,
    content_type character varying,
    created_at timestamp(6) without time zone NOT NULL,
    filename character varying NOT NULL,
    key character varying NOT NULL,
    metadata text,
    service_name character varying NOT NULL
);


--
-- Name: active_storage_blobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_blobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_blobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_blobs_id_seq OWNED BY public.active_storage_blobs.id;


--
-- Name: active_storage_variant_records; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_variant_records (
    id bigint NOT NULL,
    blob_id bigint NOT NULL,
    variation_digest character varying NOT NULL
);


--
-- Name: active_storage_variant_records_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_variant_records_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_variant_records_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_variant_records_id_seq OWNED BY public.active_storage_variant_records.id;


--
-- Name: allegiances; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.allegiances (
    id bigint NOT NULL,
    background_colour character varying,
    border_colour character varying,
    code character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    legacy_code character varying,
    name character varying NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: allegiances_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.allegiances_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: allegiances_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.allegiances_id_seq OWNED BY public.allegiances.id;


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: campaigns; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.campaigns (
    id bigint NOT NULL,
    referee_id bigint NOT NULL,
    slug character varying NOT NULL,
    name character varying NOT NULL,
    settings jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    schema_name character varying,
    campaign_type character varying DEFAULT 'charted_space'::character varying NOT NULL,
    sector_source character varying,
    api_token character varying
);


--
-- Name: campaigns_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.campaigns_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: campaigns_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.campaigns_id_seq OWNED BY public.campaigns.id;


--
-- Name: facilities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.facilities (
    id bigint NOT NULL,
    code character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    name character varying,
    traveller_map_code character varying,
    updated_at timestamp(6) without time zone NOT NULL,
    icon_class character varying
);


--
-- Name: facilities_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.facilities_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: facilities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.facilities_id_seq OWNED BY public.facilities.id;


--
-- Name: font_awesome_icons; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.font_awesome_icons (
    id bigint NOT NULL,
    name character varying NOT NULL,
    style character varying DEFAULT 'regular'::character varying NOT NULL,
    view_box character varying NOT NULL,
    svg_content text NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: font_awesome_icons_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.font_awesome_icons_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: font_awesome_icons_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.font_awesome_icons_id_seq OWNED BY public.font_awesome_icons.id;


--
-- Name: governments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.governments (
    id bigint NOT NULL,
    code integer,
    created_at timestamp(6) without time zone NOT NULL,
    description text,
    government_type character varying,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: governments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.governments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: governments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.governments_id_seq OWNED BY public.governments.id;


--
-- Name: jump_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.jump_logs (
    id bigint NOT NULL,
    ship_id bigint NOT NULL,
    from_parsec_id bigint NOT NULL,
    to_parsec_id bigint NOT NULL,
    depart_year integer,
    depart_day integer,
    arrive_year integer,
    arrive_day integer,
    sequence integer,
    notes text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    misjump boolean DEFAULT false NOT NULL
);


--
-- Name: jump_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.jump_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: jump_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.jump_logs_id_seq OWNED BY public.jump_logs.id;


--
-- Name: jump_route_links; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.jump_route_links (
    id bigint CONSTRAINT network_links_id_not_null NOT NULL,
    jump_route_id bigint CONSTRAINT network_links_network_id_not_null NOT NULL,
    from_star_system_id bigint CONSTRAINT network_links_from_star_system_id_not_null NOT NULL,
    to_star_system_id bigint CONSTRAINT network_links_to_star_system_id_not_null NOT NULL,
    created_at timestamp(6) without time zone CONSTRAINT network_links_created_at_not_null NOT NULL,
    updated_at timestamp(6) without time zone CONSTRAINT network_links_updated_at_not_null NOT NULL
);


--
-- Name: jump_route_links_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.jump_route_links_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: jump_route_links_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.jump_route_links_id_seq OWNED BY public.jump_route_links.id;


--
-- Name: jump_routes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.jump_routes (
    id bigint CONSTRAINT networks_id_not_null NOT NULL,
    name character varying,
    colour character varying,
    max_jump integer,
    known boolean,
    notes text,
    created_at timestamp(6) without time zone CONSTRAINT networks_created_at_not_null NOT NULL,
    updated_at timestamp(6) without time zone CONSTRAINT networks_updated_at_not_null NOT NULL,
    line_style character varying DEFAULT 'solid'::character varying NOT NULL,
    line_width integer DEFAULT 4 NOT NULL,
    route_type character varying DEFAULT 'network'::character varying NOT NULL,
    refueling character varying,
    excluded_travel_zone_ids integer[] DEFAULT '{}'::integer[],
    from_star_system_id bigint,
    to_star_system_id bigint
);


--
-- Name: jump_routes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.jump_routes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: jump_routes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.jump_routes_id_seq OWNED BY public.jump_routes.id;


--
-- Name: law_levels; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.law_levels (
    id bigint NOT NULL,
    armour character varying,
    code integer,
    created_at timestamp(6) without time zone NOT NULL,
    criminal_law character varying,
    economic_law character varying,
    notes text,
    personal_law character varying,
    private_law character varying,
    updated_at timestamp(6) without time zone NOT NULL,
    weapons character varying
);


--
-- Name: law_levels_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.law_levels_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: law_levels_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.law_levels_id_seq OWNED BY public.law_levels.id;


--
-- Name: parsecs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.parsecs (
    id bigint NOT NULL,
    build_log jsonb,
    created_at timestamp(6) without time zone NOT NULL,
    note text,
    sector_id bigint NOT NULL,
    star_chance double precision DEFAULT 50.0,
    survey_index integer DEFAULT 0,
    updated_at timestamp(6) without time zone NOT NULL,
    x integer NOT NULL,
    y integer NOT NULL,
    label character varying,
    player_visible boolean DEFAULT false,
    label_colour character varying,
    q integer NOT NULL,
    r integer NOT NULL,
    s integer NOT NULL
);


--
-- Name: parsecs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.parsecs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: parsecs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.parsecs_id_seq OWNED BY public.parsecs.id;


--
-- Name: region_parsecs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.region_parsecs (
    id bigint NOT NULL,
    parsec_id bigint NOT NULL,
    kind character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    region_id bigint NOT NULL,
    "position" integer
);


--
-- Name: region_parsecs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.region_parsecs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: region_parsecs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.region_parsecs_id_seq OWNED BY public.region_parsecs.id;


--
-- Name: regions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.regions (
    id bigint NOT NULL,
    name character varying NOT NULL,
    label character varying,
    source character varying DEFAULT 'user'::character varying NOT NULL,
    external_source character varying,
    external_key character varying,
    data jsonb DEFAULT '{}'::jsonb NOT NULL,
    allegiance_id bigint,
    customized boolean DEFAULT false NOT NULL,
    notes text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    border_colour character varying,
    colour character varying,
    label_colour character varying,
    label_x integer,
    label_y integer,
    player_visible boolean DEFAULT false NOT NULL
);


--
-- Name: regions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.regions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: regions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.regions_id_seq OWNED BY public.regions.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: sectors; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sectors (
    id bigint NOT NULL,
    abbreviation character varying,
    build text,
    build_log jsonb,
    created_at timestamp(6) without time zone NOT NULL,
    discarded_at timestamp(6) without time zone,
    name character varying,
    notes text,
    source character varying DEFAULT 'manual'::character varying,
    star_chance double precision DEFAULT 50.0,
    updated_at timestamp(6) without time zone NOT NULL,
    x integer,
    y integer,
    language character varying
);


--
-- Name: sectors_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sectors_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sectors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sectors_id_seq OWNED BY public.sectors.id;


--
-- Name: sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sessions (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    ip_address character varying,
    user_agent character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: sessions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sessions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sessions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sessions_id_seq OWNED BY public.sessions.id;


--
-- Name: ships; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ships (
    id bigint NOT NULL,
    name character varying,
    jump_drive integer,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    m_drive integer DEFAULT 1
);


--
-- Name: ships_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ships_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ships_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ships_id_seq OWNED BY public.ships.id;


--
-- Name: social_characteristics_presets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.social_characteristics_presets (
    id bigint NOT NULL,
    name character varying NOT NULL,
    settings jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: social_characteristics_presets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.social_characteristics_presets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: social_characteristics_presets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.social_characteristics_presets_id_seq OWNED BY public.social_characteristics_presets.id;


--
-- Name: star_system_facilities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.star_system_facilities (
    id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    facility_id bigint NOT NULL,
    star_system_id bigint NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: star_system_facilities_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.star_system_facilities_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: star_system_facilities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.star_system_facilities_id_seq OWNED BY public.star_system_facilities.id;


--
-- Name: star_system_trade_codes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.star_system_trade_codes (
    id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    star_system_id bigint NOT NULL,
    trade_code_id bigint NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: star_system_trade_codes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.star_system_trade_codes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: star_system_trade_codes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.star_system_trade_codes_id_seq OWNED BY public.star_system_trade_codes.id;


--
-- Name: star_systems; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.star_systems (
    id bigint NOT NULL,
    allegiance_id bigint,
    belt_count integer DEFAULT 0 NOT NULL,
    build_log jsonb,
    created_at timestamp(6) without time zone NOT NULL,
    gas_giant_count integer DEFAULT 0 NOT NULL,
    main_world_id bigint,
    meta jsonb,
    name character varying,
    notes text,
    parsec_id bigint NOT NULL,
    survey_index integer DEFAULT 0,
    terrestrial_count integer DEFAULT 0 NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    locked boolean DEFAULT false,
    native_sophont boolean DEFAULT false NOT NULL,
    extinct_sophont boolean DEFAULT false NOT NULL,
    travel_zone_id bigint,
    language character varying,
    build_config text
);


--
-- Name: star_systems_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.star_systems_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: star_systems_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.star_systems_id_seq OWNED BY public.star_systems.id;


--
-- Name: stellar_object_trade_codes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.stellar_object_trade_codes (
    id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    stellar_object_id bigint NOT NULL,
    trade_code_id bigint NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: stellar_object_trade_codes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.stellar_object_trade_codes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: stellar_object_trade_codes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.stellar_object_trade_codes_id_seq OWNED BY public.stellar_object_trade_codes.id;


--
-- Name: stellar_objects; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.stellar_objects (
    id bigint NOT NULL,
    allegiance_id bigint,
    au double precision,
    build_log jsonb,
    characteristics jsonb,
    companion_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    data jsonb DEFAULT '{}'::jsonb NOT NULL,
    detect_si integer,
    diameter double precision,
    eccentricity double precision,
    effective_hzco_deviation double precision,
    inclination double precision,
    mass double precision,
    name character varying,
    notes text,
    orbit double precision,
    orbit_sequence character varying,
    orbit_x double precision,
    orbit_y double precision,
    orbiting_id bigint,
    parsec_id bigint,
    size_code character varying,
    star_system_id bigint,
    survey_index integer,
    type character varying,
    updated_at timestamp(6) without time zone NOT NULL,
    uwp character varying,
    tidal_lock_target_id bigint,
    language character varying,
    known boolean DEFAULT false NOT NULL,
    CONSTRAINT stellar_objects_parsec_xor_orbiting_present CHECK ((((type)::text = 'Star'::text) OR ((parsec_id IS NULL) <> (orbiting_id IS NULL))))
);


--
-- Name: stellar_objects_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.stellar_objects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: stellar_objects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.stellar_objects_id_seq OWNED BY public.stellar_objects.id;


--
-- Name: subsectors; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.subsectors (
    id bigint NOT NULL,
    abbreviation character varying,
    build text,
    build_log jsonb,
    created_at timestamp(6) without time zone NOT NULL,
    name character varying,
    notes text,
    sector_id bigint NOT NULL,
    star_chance double precision DEFAULT 50.0,
    updated_at timestamp(6) without time zone NOT NULL,
    x integer NOT NULL,
    y integer NOT NULL,
    build_source character varying,
    language character varying
);


--
-- Name: subsectors_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.subsectors_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: subsectors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.subsectors_id_seq OWNED BY public.subsectors.id;


--
-- Name: tech_levels; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tech_levels (
    id bigint NOT NULL,
    air character varying,
    code integer,
    created_at timestamp(6) without time zone NOT NULL,
    electronics character varying,
    energy character varying,
    environmental character varying,
    heavy_military character varying,
    land character varying,
    manufacturing character varying,
    medical character varying,
    notes character varying,
    personal_military character varying,
    sea character varying,
    space character varying,
    updated_at timestamp(6) without time zone NOT NULL,
    descriptor character varying,
    short_description text
);


--
-- Name: tech_levels_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tech_levels_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tech_levels_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tech_levels_id_seq OWNED BY public.tech_levels.id;


--
-- Name: trade_codes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.trade_codes (
    id bigint NOT NULL,
    code character varying(2) NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    definition character varying NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: trade_codes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.trade_codes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: trade_codes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.trade_codes_id_seq OWNED BY public.trade_codes.id;


--
-- Name: travel_zones; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.travel_zones (
    id bigint NOT NULL,
    code character varying NOT NULL,
    name character varying NOT NULL,
    colour character varying NOT NULL,
    protected boolean DEFAULT false NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: travel_zones_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.travel_zones_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: travel_zones_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.travel_zones_id_seq OWNED BY public.travel_zones.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    email_address character varying NOT NULL,
    password_digest character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: active_storage_attachments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments ALTER COLUMN id SET DEFAULT nextval('public.active_storage_attachments_id_seq'::regclass);


--
-- Name: active_storage_blobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_blobs ALTER COLUMN id SET DEFAULT nextval('public.active_storage_blobs_id_seq'::regclass);


--
-- Name: active_storage_variant_records id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records ALTER COLUMN id SET DEFAULT nextval('public.active_storage_variant_records_id_seq'::regclass);


--
-- Name: allegiances id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.allegiances ALTER COLUMN id SET DEFAULT nextval('public.allegiances_id_seq'::regclass);


--
-- Name: campaigns id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.campaigns ALTER COLUMN id SET DEFAULT nextval('public.campaigns_id_seq'::regclass);


--
-- Name: facilities id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.facilities ALTER COLUMN id SET DEFAULT nextval('public.facilities_id_seq'::regclass);


--
-- Name: font_awesome_icons id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.font_awesome_icons ALTER COLUMN id SET DEFAULT nextval('public.font_awesome_icons_id_seq'::regclass);


--
-- Name: governments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.governments ALTER COLUMN id SET DEFAULT nextval('public.governments_id_seq'::regclass);


--
-- Name: jump_logs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.jump_logs ALTER COLUMN id SET DEFAULT nextval('public.jump_logs_id_seq'::regclass);


--
-- Name: jump_route_links id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.jump_route_links ALTER COLUMN id SET DEFAULT nextval('public.jump_route_links_id_seq'::regclass);


--
-- Name: jump_routes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.jump_routes ALTER COLUMN id SET DEFAULT nextval('public.jump_routes_id_seq'::regclass);


--
-- Name: law_levels id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.law_levels ALTER COLUMN id SET DEFAULT nextval('public.law_levels_id_seq'::regclass);


--
-- Name: parsecs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parsecs ALTER COLUMN id SET DEFAULT nextval('public.parsecs_id_seq'::regclass);


--
-- Name: region_parsecs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.region_parsecs ALTER COLUMN id SET DEFAULT nextval('public.region_parsecs_id_seq'::regclass);


--
-- Name: regions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.regions ALTER COLUMN id SET DEFAULT nextval('public.regions_id_seq'::regclass);


--
-- Name: sectors id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sectors ALTER COLUMN id SET DEFAULT nextval('public.sectors_id_seq'::regclass);


--
-- Name: sessions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessions ALTER COLUMN id SET DEFAULT nextval('public.sessions_id_seq'::regclass);


--
-- Name: ships id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ships ALTER COLUMN id SET DEFAULT nextval('public.ships_id_seq'::regclass);


--
-- Name: social_characteristics_presets id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.social_characteristics_presets ALTER COLUMN id SET DEFAULT nextval('public.social_characteristics_presets_id_seq'::regclass);


--
-- Name: star_system_facilities id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.star_system_facilities ALTER COLUMN id SET DEFAULT nextval('public.star_system_facilities_id_seq'::regclass);


--
-- Name: star_system_trade_codes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.star_system_trade_codes ALTER COLUMN id SET DEFAULT nextval('public.star_system_trade_codes_id_seq'::regclass);


--
-- Name: star_systems id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.star_systems ALTER COLUMN id SET DEFAULT nextval('public.star_systems_id_seq'::regclass);


--
-- Name: stellar_object_trade_codes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stellar_object_trade_codes ALTER COLUMN id SET DEFAULT nextval('public.stellar_object_trade_codes_id_seq'::regclass);


--
-- Name: stellar_objects id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stellar_objects ALTER COLUMN id SET DEFAULT nextval('public.stellar_objects_id_seq'::regclass);


--
-- Name: subsectors id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subsectors ALTER COLUMN id SET DEFAULT nextval('public.subsectors_id_seq'::regclass);


--
-- Name: tech_levels id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tech_levels ALTER COLUMN id SET DEFAULT nextval('public.tech_levels_id_seq'::regclass);


--
-- Name: trade_codes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trade_codes ALTER COLUMN id SET DEFAULT nextval('public.trade_codes_id_seq'::regclass);


--
-- Name: travel_zones id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.travel_zones ALTER COLUMN id SET DEFAULT nextval('public.travel_zones_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: active_storage_attachments active_storage_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments
    ADD CONSTRAINT active_storage_attachments_pkey PRIMARY KEY (id);


--
-- Name: active_storage_blobs active_storage_blobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_blobs
    ADD CONSTRAINT active_storage_blobs_pkey PRIMARY KEY (id);


--
-- Name: active_storage_variant_records active_storage_variant_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records
    ADD CONSTRAINT active_storage_variant_records_pkey PRIMARY KEY (id);


--
-- Name: allegiances allegiances_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.allegiances
    ADD CONSTRAINT allegiances_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: campaigns campaigns_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.campaigns
    ADD CONSTRAINT campaigns_pkey PRIMARY KEY (id);


--
-- Name: facilities facilities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.facilities
    ADD CONSTRAINT facilities_pkey PRIMARY KEY (id);


--
-- Name: font_awesome_icons font_awesome_icons_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.font_awesome_icons
    ADD CONSTRAINT font_awesome_icons_pkey PRIMARY KEY (id);


--
-- Name: governments governments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.governments
    ADD CONSTRAINT governments_pkey PRIMARY KEY (id);


--
-- Name: jump_logs jump_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.jump_logs
    ADD CONSTRAINT jump_logs_pkey PRIMARY KEY (id);


--
-- Name: jump_route_links jump_route_links_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.jump_route_links
    ADD CONSTRAINT jump_route_links_pkey PRIMARY KEY (id);


--
-- Name: jump_routes jump_routes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.jump_routes
    ADD CONSTRAINT jump_routes_pkey PRIMARY KEY (id);


--
-- Name: law_levels law_levels_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.law_levels
    ADD CONSTRAINT law_levels_pkey PRIMARY KEY (id);


--
-- Name: parsecs parsecs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parsecs
    ADD CONSTRAINT parsecs_pkey PRIMARY KEY (id);


--
-- Name: region_parsecs region_parsecs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.region_parsecs
    ADD CONSTRAINT region_parsecs_pkey PRIMARY KEY (id);


--
-- Name: regions regions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.regions
    ADD CONSTRAINT regions_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: sectors sectors_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sectors
    ADD CONSTRAINT sectors_pkey PRIMARY KEY (id);


--
-- Name: sessions sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- Name: ships ships_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ships
    ADD CONSTRAINT ships_pkey PRIMARY KEY (id);


--
-- Name: social_characteristics_presets social_characteristics_presets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.social_characteristics_presets
    ADD CONSTRAINT social_characteristics_presets_pkey PRIMARY KEY (id);


--
-- Name: star_system_facilities star_system_facilities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.star_system_facilities
    ADD CONSTRAINT star_system_facilities_pkey PRIMARY KEY (id);


--
-- Name: star_system_trade_codes star_system_trade_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.star_system_trade_codes
    ADD CONSTRAINT star_system_trade_codes_pkey PRIMARY KEY (id);


--
-- Name: star_systems star_systems_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.star_systems
    ADD CONSTRAINT star_systems_pkey PRIMARY KEY (id);


--
-- Name: stellar_object_trade_codes stellar_object_trade_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stellar_object_trade_codes
    ADD CONSTRAINT stellar_object_trade_codes_pkey PRIMARY KEY (id);


--
-- Name: stellar_objects stellar_objects_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stellar_objects
    ADD CONSTRAINT stellar_objects_pkey PRIMARY KEY (id);


--
-- Name: subsectors subsectors_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subsectors
    ADD CONSTRAINT subsectors_pkey PRIMARY KEY (id);


--
-- Name: tech_levels tech_levels_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tech_levels
    ADD CONSTRAINT tech_levels_pkey PRIMARY KEY (id);


--
-- Name: trade_codes trade_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trade_codes
    ADD CONSTRAINT trade_codes_pkey PRIMARY KEY (id);


--
-- Name: travel_zones travel_zones_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.travel_zones
    ADD CONSTRAINT travel_zones_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: idx_on_from_star_system_id_to_star_system_id_90e126fb8d; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_on_from_star_system_id_to_star_system_id_90e126fb8d ON public.jump_route_links USING btree (from_star_system_id, to_star_system_id);


--
-- Name: idx_on_star_system_id_trade_code_id_9139c73bd8; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_on_star_system_id_trade_code_id_9139c73bd8 ON public.star_system_trade_codes USING btree (star_system_id, trade_code_id);


--
-- Name: idx_on_stellar_object_id_trade_code_id_0e62e9d1bb; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_on_stellar_object_id_trade_code_id_0e62e9d1bb ON public.stellar_object_trade_codes USING btree (stellar_object_id, trade_code_id);


--
-- Name: idx_region_parsecs_on_region_parsec_kind; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_region_parsecs_on_region_parsec_kind ON public.region_parsecs USING btree (region_id, parsec_id, kind);


--
-- Name: index_active_storage_attachments_on_blob_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_active_storage_attachments_on_blob_id ON public.active_storage_attachments USING btree (blob_id);


--
-- Name: index_active_storage_attachments_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_attachments_uniqueness ON public.active_storage_attachments USING btree (record_type, record_id, name, blob_id);


--
-- Name: index_active_storage_blobs_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_blobs_on_key ON public.active_storage_blobs USING btree (key);


--
-- Name: index_active_storage_variant_records_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_variant_records_uniqueness ON public.active_storage_variant_records USING btree (blob_id, variation_digest);


--
-- Name: index_allegiances_on_code; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_allegiances_on_code ON public.allegiances USING btree (code);


--
-- Name: index_campaigns_on_referee_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_campaigns_on_referee_id ON public.campaigns USING btree (referee_id);


--
-- Name: index_campaigns_on_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_campaigns_on_slug ON public.campaigns USING btree (slug);


--
-- Name: index_facilities_on_code; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_facilities_on_code ON public.facilities USING btree (code);


--
-- Name: index_font_awesome_icons_on_name_and_style; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_font_awesome_icons_on_name_and_style ON public.font_awesome_icons USING btree (name, style);


--
-- Name: index_governments_on_code; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_governments_on_code ON public.governments USING btree (code);


--
-- Name: index_jump_logs_on_from_parsec_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_jump_logs_on_from_parsec_id ON public.jump_logs USING btree (from_parsec_id);


--
-- Name: index_jump_logs_on_ship_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_jump_logs_on_ship_id ON public.jump_logs USING btree (ship_id);


--
-- Name: index_jump_logs_on_to_parsec_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_jump_logs_on_to_parsec_id ON public.jump_logs USING btree (to_parsec_id);


--
-- Name: index_jump_route_links_on_jump_route_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_jump_route_links_on_jump_route_id ON public.jump_route_links USING btree (jump_route_id);


--
-- Name: index_jump_route_links_on_to_star_system_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_jump_route_links_on_to_star_system_id ON public.jump_route_links USING btree (to_star_system_id);


--
-- Name: index_jump_routes_on_from_star_system_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_jump_routes_on_from_star_system_id ON public.jump_routes USING btree (from_star_system_id);


--
-- Name: index_jump_routes_on_to_star_system_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_jump_routes_on_to_star_system_id ON public.jump_routes USING btree (to_star_system_id);


--
-- Name: index_law_levels_on_code; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_law_levels_on_code ON public.law_levels USING btree (code);


--
-- Name: index_parsecs_on_q_and_r_and_s; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_parsecs_on_q_and_r_and_s ON public.parsecs USING btree (q, r, s);


--
-- Name: index_parsecs_on_sector_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_parsecs_on_sector_id ON public.parsecs USING btree (sector_id);


--
-- Name: index_parsecs_on_sector_id_and_x_and_y; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_parsecs_on_sector_id_and_x_and_y ON public.parsecs USING btree (sector_id, x, y);


--
-- Name: index_region_parsecs_on_parsec_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_region_parsecs_on_parsec_id ON public.region_parsecs USING btree (parsec_id);


--
-- Name: index_region_parsecs_on_region_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_region_parsecs_on_region_id ON public.region_parsecs USING btree (region_id);


--
-- Name: index_regions_on_allegiance_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_regions_on_allegiance_id ON public.regions USING btree (allegiance_id);


--
-- Name: index_regions_on_external_source_and_external_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_regions_on_external_source_and_external_key ON public.regions USING btree (external_source, external_key) WHERE ((external_source IS NOT NULL) AND (external_key IS NOT NULL));


--
-- Name: index_sectors_on_discarded_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sectors_on_discarded_at ON public.sectors USING btree (discarded_at);


--
-- Name: index_sectors_on_name_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sectors_on_name_trgm ON public.sectors USING gin (name shared_extensions.gin_trgm_ops);


--
-- Name: index_sectors_on_x_and_y; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_sectors_on_x_and_y ON public.sectors USING btree (x, y);


--
-- Name: index_sessions_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sessions_on_user_id ON public.sessions USING btree (user_id);


--
-- Name: index_social_characteristics_presets_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_social_characteristics_presets_on_name ON public.social_characteristics_presets USING btree (name);


--
-- Name: index_star_system_facilities_on_facility_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_star_system_facilities_on_facility_id ON public.star_system_facilities USING btree (facility_id);


--
-- Name: index_star_system_facilities_on_star_system_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_star_system_facilities_on_star_system_id ON public.star_system_facilities USING btree (star_system_id);


--
-- Name: index_star_system_facilities_on_star_system_id_and_facility_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_star_system_facilities_on_star_system_id_and_facility_id ON public.star_system_facilities USING btree (star_system_id, facility_id);


--
-- Name: index_star_system_trade_codes_on_star_system_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_star_system_trade_codes_on_star_system_id ON public.star_system_trade_codes USING btree (star_system_id);


--
-- Name: index_star_system_trade_codes_on_trade_code_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_star_system_trade_codes_on_trade_code_id ON public.star_system_trade_codes USING btree (trade_code_id);


--
-- Name: index_star_systems_on_allegiance_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_star_systems_on_allegiance_id ON public.star_systems USING btree (allegiance_id);


--
-- Name: index_star_systems_on_main_world_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_star_systems_on_main_world_id ON public.star_systems USING btree (main_world_id);


--
-- Name: index_star_systems_on_name_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_star_systems_on_name_trgm ON public.star_systems USING gin (name shared_extensions.gin_trgm_ops);


--
-- Name: index_star_systems_on_parsec_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_star_systems_on_parsec_id ON public.star_systems USING btree (parsec_id);


--
-- Name: index_star_systems_on_travel_zone_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_star_systems_on_travel_zone_id ON public.star_systems USING btree (travel_zone_id);


--
-- Name: index_stellar_object_trade_codes_on_stellar_object_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_stellar_object_trade_codes_on_stellar_object_id ON public.stellar_object_trade_codes USING btree (stellar_object_id);


--
-- Name: index_stellar_object_trade_codes_on_trade_code_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_stellar_object_trade_codes_on_trade_code_id ON public.stellar_object_trade_codes USING btree (trade_code_id);


--
-- Name: index_stellar_objects_extinct_sophont; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_stellar_objects_extinct_sophont ON public.stellar_objects USING btree (star_system_id) WHERE (data @> '{"extinct_sophont": true}'::jsonb);


--
-- Name: index_stellar_objects_native_sophont; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_stellar_objects_native_sophont ON public.stellar_objects USING btree (star_system_id) WHERE (data @> '{"native_sophont": true}'::jsonb);


--
-- Name: index_stellar_objects_on_allegiance_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_stellar_objects_on_allegiance_id ON public.stellar_objects USING btree (allegiance_id);


--
-- Name: index_stellar_objects_on_companion_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_stellar_objects_on_companion_id ON public.stellar_objects USING btree (companion_id);


--
-- Name: index_stellar_objects_on_orbiting_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_stellar_objects_on_orbiting_id ON public.stellar_objects USING btree (orbiting_id);


--
-- Name: index_stellar_objects_on_parsec_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_stellar_objects_on_parsec_id ON public.stellar_objects USING btree (parsec_id);


--
-- Name: index_stellar_objects_on_star_system_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_stellar_objects_on_star_system_id ON public.stellar_objects USING btree (star_system_id);


--
-- Name: index_stellar_objects_on_tidal_lock_target_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_stellar_objects_on_tidal_lock_target_id ON public.stellar_objects USING btree (tidal_lock_target_id);


--
-- Name: index_subsectors_on_name_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_subsectors_on_name_trgm ON public.subsectors USING gin (name shared_extensions.gin_trgm_ops);


--
-- Name: index_subsectors_on_sector_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_subsectors_on_sector_id ON public.subsectors USING btree (sector_id);


--
-- Name: index_subsectors_on_sector_id_and_x_and_y; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_subsectors_on_sector_id_and_x_and_y ON public.subsectors USING btree (sector_id, x, y);


--
-- Name: index_tech_levels_on_code; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_tech_levels_on_code ON public.tech_levels USING btree (code);


--
-- Name: index_trade_codes_on_code; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_trade_codes_on_code ON public.trade_codes USING btree (code);


--
-- Name: index_travel_zones_on_code; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_travel_zones_on_code ON public.travel_zones USING btree (code);


--
-- Name: index_users_on_email_address; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_email_address ON public.users USING btree (email_address);


--
-- Name: parsecs trigger_parsecs_set_hex_coordinates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_parsecs_set_hex_coordinates BEFORE INSERT OR UPDATE OF x, y ON public.parsecs FOR EACH ROW EXECUTE FUNCTION public.parsecs_set_hex_coordinates();


--
-- Name: regions fk_rails_03ddd62ded; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.regions
    ADD CONSTRAINT fk_rails_03ddd62ded FOREIGN KEY (allegiance_id) REFERENCES public.allegiances(id);


--
-- Name: star_systems fk_rails_08b2fa5205; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.star_systems
    ADD CONSTRAINT fk_rails_08b2fa5205 FOREIGN KEY (parsec_id) REFERENCES public.parsecs(id) ON DELETE CASCADE;


--
-- Name: subsectors fk_rails_21fde0491a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subsectors
    ADD CONSTRAINT fk_rails_21fde0491a FOREIGN KEY (sector_id) REFERENCES public.sectors(id) ON DELETE CASCADE;


--
-- Name: stellar_objects fk_rails_25815953bd; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stellar_objects
    ADD CONSTRAINT fk_rails_25815953bd FOREIGN KEY (allegiance_id) REFERENCES public.allegiances(id) ON DELETE SET NULL;


--
-- Name: stellar_objects fk_rails_31a1fd0eb5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stellar_objects
    ADD CONSTRAINT fk_rails_31a1fd0eb5 FOREIGN KEY (orbiting_id) REFERENCES public.stellar_objects(id) ON DELETE CASCADE;


--
-- Name: jump_logs fk_rails_3342b6e980; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.jump_logs
    ADD CONSTRAINT fk_rails_3342b6e980 FOREIGN KEY (ship_id) REFERENCES public.ships(id);


--
-- Name: jump_route_links fk_rails_42802f7ca7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.jump_route_links
    ADD CONSTRAINT fk_rails_42802f7ca7 FOREIGN KEY (to_star_system_id) REFERENCES public.star_systems(id);


--
-- Name: campaigns fk_rails_5c5d81eea6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.campaigns
    ADD CONSTRAINT fk_rails_5c5d81eea6 FOREIGN KEY (referee_id) REFERENCES public.users(id);


--
-- Name: stellar_objects fk_rails_6decbb2331; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stellar_objects
    ADD CONSTRAINT fk_rails_6decbb2331 FOREIGN KEY (tidal_lock_target_id) REFERENCES public.stellar_objects(id) ON DELETE SET NULL;


--
-- Name: sessions fk_rails_758836b4f0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT fk_rails_758836b4f0 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: star_system_facilities fk_rails_84924f7005; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.star_system_facilities
    ADD CONSTRAINT fk_rails_84924f7005 FOREIGN KEY (star_system_id) REFERENCES public.star_systems(id) ON DELETE CASCADE;


--
-- Name: jump_route_links fk_rails_968ef22631; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.jump_route_links
    ADD CONSTRAINT fk_rails_968ef22631 FOREIGN KEY (from_star_system_id) REFERENCES public.star_systems(id);


--
-- Name: active_storage_variant_records fk_rails_993965df05; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records
    ADD CONSTRAINT fk_rails_993965df05 FOREIGN KEY (blob_id) REFERENCES public.active_storage_blobs(id);


--
-- Name: jump_logs fk_rails_9c065f667d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.jump_logs
    ADD CONSTRAINT fk_rails_9c065f667d FOREIGN KEY (from_parsec_id) REFERENCES public.parsecs(id);


--
-- Name: jump_routes fk_rails_a40373e8b5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.jump_routes
    ADD CONSTRAINT fk_rails_a40373e8b5 FOREIGN KEY (to_star_system_id) REFERENCES public.star_systems(id);


--
-- Name: star_system_facilities fk_rails_a7d6ad5778; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.star_system_facilities
    ADD CONSTRAINT fk_rails_a7d6ad5778 FOREIGN KEY (facility_id) REFERENCES public.facilities(id) ON DELETE CASCADE;


--
-- Name: stellar_object_trade_codes fk_rails_ab2bb76127; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stellar_object_trade_codes
    ADD CONSTRAINT fk_rails_ab2bb76127 FOREIGN KEY (stellar_object_id) REFERENCES public.stellar_objects(id) ON DELETE CASCADE;


--
-- Name: stellar_objects fk_rails_ab53bf8682; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stellar_objects
    ADD CONSTRAINT fk_rails_ab53bf8682 FOREIGN KEY (star_system_id) REFERENCES public.star_systems(id) ON DELETE CASCADE;


--
-- Name: star_system_trade_codes fk_rails_adaea6f0dc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.star_system_trade_codes
    ADD CONSTRAINT fk_rails_adaea6f0dc FOREIGN KEY (star_system_id) REFERENCES public.star_systems(id) ON DELETE CASCADE;


--
-- Name: star_system_trade_codes fk_rails_b2f2f3d56d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.star_system_trade_codes
    ADD CONSTRAINT fk_rails_b2f2f3d56d FOREIGN KEY (trade_code_id) REFERENCES public.trade_codes(id) ON DELETE CASCADE;


--
-- Name: stellar_object_trade_codes fk_rails_b3294dfcc3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stellar_object_trade_codes
    ADD CONSTRAINT fk_rails_b3294dfcc3 FOREIGN KEY (trade_code_id) REFERENCES public.trade_codes(id) ON DELETE CASCADE;


--
-- Name: star_systems fk_rails_b72f946ed6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.star_systems
    ADD CONSTRAINT fk_rails_b72f946ed6 FOREIGN KEY (allegiance_id) REFERENCES public.allegiances(id) ON DELETE SET NULL;


--
-- Name: star_systems fk_rails_ba603f6649; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.star_systems
    ADD CONSTRAINT fk_rails_ba603f6649 FOREIGN KEY (travel_zone_id) REFERENCES public.travel_zones(id);


--
-- Name: stellar_objects fk_rails_bbd654e3b1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stellar_objects
    ADD CONSTRAINT fk_rails_bbd654e3b1 FOREIGN KEY (companion_id) REFERENCES public.stellar_objects(id) ON DELETE SET NULL;


--
-- Name: active_storage_attachments fk_rails_c3b3935057; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments
    ADD CONSTRAINT fk_rails_c3b3935057 FOREIGN KEY (blob_id) REFERENCES public.active_storage_blobs(id);


--
-- Name: jump_route_links fk_rails_ccbcb39bca; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.jump_route_links
    ADD CONSTRAINT fk_rails_ccbcb39bca FOREIGN KEY (jump_route_id) REFERENCES public.jump_routes(id);


--
-- Name: star_systems fk_rails_cf9fa4abee; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.star_systems
    ADD CONSTRAINT fk_rails_cf9fa4abee FOREIGN KEY (main_world_id) REFERENCES public.stellar_objects(id) ON DELETE SET NULL;


--
-- Name: stellar_objects fk_rails_dd57f07897; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stellar_objects
    ADD CONSTRAINT fk_rails_dd57f07897 FOREIGN KEY (parsec_id) REFERENCES public.parsecs(id) ON DELETE CASCADE;


--
-- Name: region_parsecs fk_rails_e0deb3cb45; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.region_parsecs
    ADD CONSTRAINT fk_rails_e0deb3cb45 FOREIGN KEY (parsec_id) REFERENCES public.parsecs(id);


--
-- Name: jump_logs fk_rails_f385000113; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.jump_logs
    ADD CONSTRAINT fk_rails_f385000113 FOREIGN KEY (to_parsec_id) REFERENCES public.parsecs(id);


--
-- Name: parsecs fk_rails_f6eeaa3b05; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parsecs
    ADD CONSTRAINT fk_rails_f6eeaa3b05 FOREIGN KEY (sector_id) REFERENCES public.sectors(id) ON DELETE CASCADE;


--
-- Name: jump_routes fk_rails_fd61107ee6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.jump_routes
    ADD CONSTRAINT fk_rails_fd61107ee6 FOREIGN KEY (from_star_system_id) REFERENCES public.star_systems(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "public", "shared_extensions";

INSERT INTO "schema_migrations" (version) VALUES
('20260609150000'),
('20260609100843'),
('20260609100842'),
('20260525183956'),
('20260525183954'),
('20260525183952'),
('20260525183951'),
('20260522210542'),
('20260521182210'),
('20260511180000'),
('20260511165604'),
('20260511163842'),
('20260509195139'),
('20260503121920'),
('20260428000001'),
('20260427000002'),
('20260427000001'),
('20260425153307'),
('20260416190803'),
('20260416190802'),
('20260416000003'),
('20260416000002'),
('20260416000001'),
('20260414000000'),
('20260413035025'),
('20260413034712'),
('20260413031806'),
('20260411201353'),
('20260406224118'),
('20260401000001'),
('20260327151546'),
('20260327014341'),
('20260327014340'),
('20260327014339'),
('20260321123600'),
('20260320021159'),
('20260319143039'),
('20260319024305'),
('20260316140224'),
('20260316122010'),
('20260312210704'),
('20260312191008'),
('20260310204025'),
('20260310203349'),
('20260310193444'),
('20260310192233'),
('20260308220000'),
('20260308214659'),
('20260308214435'),
('20260308175632'),
('20260308173831'),
('20260308173749'),
('20260308173628'),
('20260308173436'),
('20260308013949'),
('20260308013136'),
('20260302205133'),
('20260302205132'),
('20260228125133'),
('20260224131951'),
('20260224091700'),
('20260223203524'),
('20260223201833'),
('20260218135149'),
('20260214141555'),
('20260206225308'),
('20260206165153'),
('20260203174848'),
('20260128180139'),
('20260128002451'),
('20260126190734'),
('20260122133857'),
('20260122022348'),
('20260119181343'),
('20260119181326'),
('20260119043501'),
('20260118164207'),
('20260118162556'),
('20260117203841'),
('20260116160534'),
('20260116155749'),
('20260116154100'),
('20260113015903'),
('20260109203202'),
('20260109194849'),
('20260109192739'),
('20260109192023'),
('20260109150825'),
('20260109143919'),
('20260106194321'),
('20251224151509'),
('20251224150711'),
('20251222201514'),
('20251222201129'),
('20251222190514'),
('20251217212727'),
('20251217204028'),
('20251215231748'),
('20251215231413'),
('20251214152150'),
('20251214041406'),
('20251214041405'),
('20251214034520'),
('20251214032224'),
('20251214031703'),
('20251214021912'),
('20251214021826'),
('20251214020748'),
('20251214020637');

