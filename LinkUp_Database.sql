--
-- PostgreSQL database dump
--

-- Dumped from database version 16.2
-- Dumped by pg_dump version 16.2

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
-- Name: article_reaction_type_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.article_reaction_type_enum AS ENUM (
    'li',
    'ce',
    'su',
    'lo',
    'in',
    'cu'
);


ALTER TYPE public.article_reaction_type_enum OWNER TO postgres;

--
-- Name: experience_employmenttype_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.experience_employmenttype_enum AS ENUM (
    'ft',
    'pt',
    'se',
    'fl',
    'co',
    'in',
    'ap',
    'sl'
);


ALTER TYPE public.experience_employmenttype_enum OWNER TO postgres;

--
-- Name: job_alert_type_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.job_alert_type_enum AS ENUM (
    'ft',
    'pt',
    'se',
    'fl',
    'co',
    'in',
    'ap',
    'sl'
);


ALTER TYPE public.job_alert_type_enum OWNER TO postgres;

--
-- Name: notification_type_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.notification_type_enum AS ENUM (
    'al',
    'ac',
    're',
    'cm',
    'ja',
    'jd'
);


ALTER TYPE public.notification_type_enum OWNER TO postgres;

--
-- Name: user_role_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.user_role_enum AS ENUM (
    'a',
    'p'
);


ALTER TYPE public.user_role_enum OWNER TO postgres;

--
-- Name: get_followings(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_followings(user_id integer) RETURNS TABLE(rows json)
    LANGUAGE sql
    AS $$
select(
SELECT json_agg(t.*) FROM (
	select id, "user2Id" from public.follower where "user1Id" = user_id
	)as t
) as rows
$$;


ALTER FUNCTION public.get_followings(user_id integer) OWNER TO postgres;

--
-- Name: get_friends(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_friends(user_id integer) RETURNS TABLE(rows json)
    LANGUAGE sql
    AS $$
select(
SELECT json_agg(t.*) FROM (
	select id, "user1Id", "user2Id" from public.friendship where "user2Id" = user_id OR "user1Id" = user_id
	)as t
) as rows
$$;


ALTER FUNCTION public.get_friends(user_id integer) OWNER TO postgres;

--
-- Name: get_sent_requests(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_sent_requests(user_id integer) RETURNS TABLE(rows json)
    LANGUAGE sql
    AS $$
select(
SELECT json_agg(t.*) FROM (
	select id, "receiverId" from public.friend_request where "senderId" = user_id
	)as t
) as rows
$$;


ALTER FUNCTION public.get_sent_requests(user_id integer) OWNER TO postgres;

--
-- Name: get_top_active_roles(character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_top_active_roles(current_rol character varying, future_role character varying) RETURNS TABLE(rows json)
    LANGUAGE sql
    AS $_$
select(
SELECT json_agg(r.*) FROM (
SELECT id, ((t.skillcounts/2) + t.followCount + t.articalcounts + t.jobcounts + t.articalLikeCounts) as points, t.skillcounts, t.followCount, t.articalcounts, t.jobcounts, t.articalLikeCounts, badgesList FROM (
	select u.id,
	(select COUNT(1) from public.user_skills_skill sk where sk."userId" = u.id) skillcounts,
	(select COUNT(1) from public.article sa where sa."publisherId" = u.id) articalcounts,
	(select COUNT(1) from public.job_alert sj where sj."creatorId" = u.id) jobcounts,
	(select COUNT(1) from public.follower sf where sf."user1Id" = u.id) followCount,
	(SELECT count(1) FROM public.article_reaction as ar INNER JOIN public.article as ssa ON ar."articleId" = ssa.id where ssa."publisherId" = 5 group by ssa.id) articalLikeCounts,
	(SELECT string_agg("levelId"::text, ',') FROM public.user_contribute_level cl where cl."userId" = u.id group by cl."userId") badgesList
	from public.user as u
	inner join (select "userId" from (Select "userId", string_agg(title, ', ') as title from experience
where ( $1 is null or title Ilike '%' || $1 || '%' )
		   or ($2 is null or title Ilike '%' || $2 || '%') group by "userId")
where ( $1 is null or title Ilike '%' || $1 || '%' )
		   and ($2 is null or title Ilike '%' || $2 || '%')
) exp on exp."userId" = u.id
	)as t where t.skillcounts + t.followCount + t.articalcounts + t.jobcounts + t.articalLikeCounts > 0
	order by (t.skillcounts + t.followCount + t.articalcounts + t.jobcounts + t.articalLikeCounts) desc LIMIT 25)as r
) as rows
$_$;


ALTER FUNCTION public.get_top_active_roles(current_rol character varying, future_role character varying) OWNER TO postgres;

--
-- Name: get_user_text_search(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_user_text_search(p_pattern character varying) RETURNS TABLE(rows json)
    LANGUAGE sql
    AS $_$
select(
SELECT json_agg(t.*) FROM (
	select u.* from public.user as u
	left join public.user_skills_skill as ss on ss."userId" = u.id
	left join public.skill sk ON sk.id = ss."skillId"
	where sk.name ilike '%' || $1 || '%' 
	or u.firstname ilike '%' || $1 || '%' 
	or u.lastname ilike '%' || $1 || '%'
	or u.email ilike '%' || $1 || '%'
	or u.phone ilike '%' || $1 || '%'
	)as t
) as rows
$_$;


ALTER FUNCTION public.get_user_text_search(p_pattern character varying) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: article; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.article (
    id integer NOT NULL,
    text character varying NOT NULL,
    published_at timestamp without time zone DEFAULT now() NOT NULL,
    "publisherId" integer
);


ALTER TABLE public.article OWNER TO postgres;

--
-- Name: article_comment; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.article_comment (
    id integer NOT NULL,
    text character varying NOT NULL,
    commented_at timestamp without time zone DEFAULT now() NOT NULL,
    "commenterId" integer,
    "articleId" integer
);


ALTER TABLE public.article_comment OWNER TO postgres;

--
-- Name: article_comment_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.article_comment_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.article_comment_id_seq OWNER TO postgres;

--
-- Name: article_comment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.article_comment_id_seq OWNED BY public.article_comment.id;


--
-- Name: article_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.article_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.article_id_seq OWNER TO postgres;

--
-- Name: article_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.article_id_seq OWNED BY public.article.id;


--
-- Name: article_image; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.article_image (
    id integer NOT NULL,
    name character varying NOT NULL,
    "articleId" integer
);


ALTER TABLE public.article_image OWNER TO postgres;

--
-- Name: article_image_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.article_image_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.article_image_id_seq OWNER TO postgres;

--
-- Name: article_image_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.article_image_id_seq OWNED BY public.article_image.id;


--
-- Name: article_reaction; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.article_reaction (
    id integer NOT NULL,
    type public.article_reaction_type_enum DEFAULT 'li'::public.article_reaction_type_enum NOT NULL,
    reacted_at timestamp without time zone DEFAULT now() NOT NULL,
    "reactorId" integer,
    "articleId" integer
);


ALTER TABLE public.article_reaction OWNER TO postgres;

--
-- Name: article_reaction_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.article_reaction_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.article_reaction_id_seq OWNER TO postgres;

--
-- Name: article_reaction_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.article_reaction_id_seq OWNED BY public.article_reaction.id;


--
-- Name: article_video; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.article_video (
    id integer NOT NULL,
    name character varying NOT NULL,
    "articleId" integer
);


ALTER TABLE public.article_video OWNER TO postgres;

--
-- Name: article_video_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.article_video_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.article_video_id_seq OWNER TO postgres;

--
-- Name: article_video_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.article_video_id_seq OWNED BY public.article_video.id;


--
-- Name: chat; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.chat (
    id integer NOT NULL,
    last_message timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.chat OWNER TO postgres;

--
-- Name: chat_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.chat_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.chat_id_seq OWNER TO postgres;

--
-- Name: chat_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.chat_id_seq OWNED BY public.chat.id;


--
-- Name: chat_users_user; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.chat_users_user (
    "chatId" integer NOT NULL,
    "userId" integer NOT NULL
);


ALTER TABLE public.chat_users_user OWNER TO postgres;

--
-- Name: company; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.company (
    id integer NOT NULL,
    name character varying NOT NULL
);


ALTER TABLE public.company OWNER TO postgres;

--
-- Name: company_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.company_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.company_id_seq OWNER TO postgres;

--
-- Name: company_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.company_id_seq OWNED BY public.company.id;


--
-- Name: contributor_levels; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.contributor_levels (
    id integer NOT NULL,
    level_name character varying(120) NOT NULL
);


ALTER TABLE public.contributor_levels OWNER TO postgres;

--
-- Name: contributor_levels_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.contributor_levels ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.contributor_levels_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: education; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.education (
    id integer NOT NULL,
    school character varying NOT NULL,
    degree character varying,
    "fieldOfStudy" character varying,
    "startDate" timestamp without time zone,
    "endDate" timestamp without time zone,
    grade character varying,
    description character varying,
    "userId" integer
);


ALTER TABLE public.education OWNER TO postgres;

--
-- Name: education_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.education_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.education_id_seq OWNER TO postgres;

--
-- Name: education_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.education_id_seq OWNED BY public.education.id;


--
-- Name: experience; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.experience (
    id integer NOT NULL,
    title character varying NOT NULL,
    "employmentType" public.experience_employmenttype_enum DEFAULT 'ft'::public.experience_employmenttype_enum,
    location character varying,
    "startDate" timestamp without time zone NOT NULL,
    "endDate" timestamp without time zone,
    description character varying,
    "userId" integer,
    "companyId" integer
);


ALTER TABLE public.experience OWNER TO postgres;

--
-- Name: experience_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.experience_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.experience_id_seq OWNER TO postgres;

--
-- Name: experience_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.experience_id_seq OWNED BY public.experience.id;


--
-- Name: follower_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.follower_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER SEQUENCE public.follower_id_seq OWNER TO postgres;

--
-- Name: follower; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.follower (
    id integer DEFAULT nextval('public.follower_id_seq'::regclass) NOT NULL,
    since timestamp without time zone DEFAULT now() NOT NULL,
    "user1Id" integer,
    "user2Id" integer
);


ALTER TABLE public.follower OWNER TO postgres;

--
-- Name: friend_request; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.friend_request (
    id integer NOT NULL,
    "sentAt" timestamp without time zone DEFAULT now() NOT NULL,
    "senderId" integer,
    "receiverId" integer
);


ALTER TABLE public.friend_request OWNER TO postgres;

--
-- Name: friend_request_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.friend_request_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.friend_request_id_seq OWNER TO postgres;

--
-- Name: friend_request_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.friend_request_id_seq OWNED BY public.friend_request.id;


--
-- Name: friendship; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.friendship (
    id integer NOT NULL,
    since timestamp without time zone DEFAULT now() NOT NULL,
    "user1Id" integer,
    "user2Id" integer
);


ALTER TABLE public.friendship OWNER TO postgres;

--
-- Name: friendship_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.friendship_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.friendship_id_seq OWNER TO postgres;

--
-- Name: friendship_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.friendship_id_seq OWNED BY public.friendship.id;


--
-- Name: job_alert; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.job_alert (
    id integer NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    title character varying NOT NULL,
    location character varying NOT NULL,
    description character varying NOT NULL,
    type public.job_alert_type_enum DEFAULT 'ft'::public.job_alert_type_enum NOT NULL,
    "creatorId" integer,
    "companyId" integer
);


ALTER TABLE public.job_alert OWNER TO postgres;

--
-- Name: job_alert_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_alert_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_alert_id_seq OWNER TO postgres;

--
-- Name: job_alert_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.job_alert_id_seq OWNED BY public.job_alert.id;


--
-- Name: job_alert_required_skills_skill; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.job_alert_required_skills_skill (
    "jobAlertId" integer NOT NULL,
    "skillId" integer NOT NULL
);


ALTER TABLE public.job_alert_required_skills_skill OWNER TO postgres;

--
-- Name: job_application; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.job_application (
    id integer NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    "coverLetter" character varying,
    "jobAlertId" integer,
    "applicantId" integer
);


ALTER TABLE public.job_application OWNER TO postgres;

--
-- Name: job_application_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.job_application_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.job_application_id_seq OWNER TO postgres;

--
-- Name: job_application_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.job_application_id_seq OWNED BY public.job_application.id;


--
-- Name: message; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.message (
    id integer NOT NULL,
    "sentAt" timestamp without time zone DEFAULT now() NOT NULL,
    text character varying NOT NULL,
    "chatId" integer,
    "senderId" integer
);


ALTER TABLE public.message OWNER TO postgres;

--
-- Name: message_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.message_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.message_id_seq OWNER TO postgres;

--
-- Name: message_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.message_id_seq OWNED BY public.message.id;


--
-- Name: notification; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.notification (
    id integer NOT NULL,
    type public.notification_type_enum DEFAULT 'al'::public.notification_type_enum NOT NULL,
    "receivedAt" timestamp without time zone DEFAULT now() NOT NULL,
    "refererEntity" integer DEFAULT 0 NOT NULL,
    read boolean DEFAULT false NOT NULL,
    "receiverId" integer,
    "refererUserId" integer
);


ALTER TABLE public.notification OWNER TO postgres;

--
-- Name: notification_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.notification_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.notification_id_seq OWNER TO postgres;

--
-- Name: notification_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.notification_id_seq OWNED BY public.notification.id;


--
-- Name: skill; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.skill (
    id integer NOT NULL,
    name character varying NOT NULL
);


ALTER TABLE public.skill OWNER TO postgres;

--
-- Name: skill_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.skill_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.skill_id_seq OWNER TO postgres;

--
-- Name: skill_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.skill_id_seq OWNED BY public.skill.id;


--
-- Name: user; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."user" (
    id integer NOT NULL,
    firstname character varying NOT NULL,
    lastname character varying NOT NULL,
    email character varying NOT NULL,
    phone character varying NOT NULL,
    password character varying NOT NULL,
    role public.user_role_enum DEFAULT 'p'::public.user_role_enum NOT NULL,
    "profilePicName" character varying
);


ALTER TABLE public."user" OWNER TO postgres;

--
-- Name: user_contribute_level; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_contribute_level (
    "userId" integer NOT NULL,
    "levelId" integer NOT NULL
);


ALTER TABLE public.user_contribute_level OWNER TO postgres;

--
-- Name: user_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.user_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.user_id_seq OWNER TO postgres;

--
-- Name: user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.user_id_seq OWNED BY public."user".id;


--
-- Name: user_skills_skill; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_skills_skill (
    "userId" integer NOT NULL,
    "skillId" integer NOT NULL
);


ALTER TABLE public.user_skills_skill OWNER TO postgres;

--
-- Name: visibility_settings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.visibility_settings (
    id integer NOT NULL,
    "experienceVisible" boolean DEFAULT true NOT NULL,
    "educationVisible" boolean DEFAULT true NOT NULL,
    "skillsVisible" boolean DEFAULT true NOT NULL,
    "userId" integer
);


ALTER TABLE public.visibility_settings OWNER TO postgres;

--
-- Name: visibility_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.visibility_settings_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.visibility_settings_id_seq OWNER TO postgres;

--
-- Name: visibility_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.visibility_settings_id_seq OWNED BY public.visibility_settings.id;


--
-- Name: article id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.article ALTER COLUMN id SET DEFAULT nextval('public.article_id_seq'::regclass);


--
-- Name: article_comment id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.article_comment ALTER COLUMN id SET DEFAULT nextval('public.article_comment_id_seq'::regclass);


--
-- Name: article_image id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.article_image ALTER COLUMN id SET DEFAULT nextval('public.article_image_id_seq'::regclass);


--
-- Name: article_reaction id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.article_reaction ALTER COLUMN id SET DEFAULT nextval('public.article_reaction_id_seq'::regclass);


--
-- Name: article_video id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.article_video ALTER COLUMN id SET DEFAULT nextval('public.article_video_id_seq'::regclass);


--
-- Name: chat id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat ALTER COLUMN id SET DEFAULT nextval('public.chat_id_seq'::regclass);


--
-- Name: company id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.company ALTER COLUMN id SET DEFAULT nextval('public.company_id_seq'::regclass);


--
-- Name: education id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.education ALTER COLUMN id SET DEFAULT nextval('public.education_id_seq'::regclass);


--
-- Name: experience id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.experience ALTER COLUMN id SET DEFAULT nextval('public.experience_id_seq'::regclass);


--
-- Name: friend_request id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.friend_request ALTER COLUMN id SET DEFAULT nextval('public.friend_request_id_seq'::regclass);


--
-- Name: friendship id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.friendship ALTER COLUMN id SET DEFAULT nextval('public.friendship_id_seq'::regclass);


--
-- Name: job_alert id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.job_alert ALTER COLUMN id SET DEFAULT nextval('public.job_alert_id_seq'::regclass);


--
-- Name: job_application id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.job_application ALTER COLUMN id SET DEFAULT nextval('public.job_application_id_seq'::regclass);


--
-- Name: message id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.message ALTER COLUMN id SET DEFAULT nextval('public.message_id_seq'::regclass);


--
-- Name: notification id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notification ALTER COLUMN id SET DEFAULT nextval('public.notification_id_seq'::regclass);


--
-- Name: skill id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.skill ALTER COLUMN id SET DEFAULT nextval('public.skill_id_seq'::regclass);


--
-- Name: user id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."user" ALTER COLUMN id SET DEFAULT nextval('public.user_id_seq'::regclass);


--
-- Name: visibility_settings id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.visibility_settings ALTER COLUMN id SET DEFAULT nextval('public.visibility_settings_id_seq'::regclass);


--
-- Data for Name: article; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.article (id, text, published_at, "publisherId") FROM stdin;
1	This is my First Post as a demo user	2024-04-17 16:50:49.599081	2
2	This my post a admin	2024-04-17 16:52:17.627047	1
3	Content marketing is a significant area of marketing, including video creation, email newsletters, social media posts, blog posts, and more. Content marketing focuses on providing value to the reader with high-quality content that solves pain points and answers questions without being overly promotional. Carefully crafted articles and blog posts can help build trust with your existing and potential customers. They can also help you rank higher in search engines so your target audience can find you, generating more leads and conversions.	2024-04-17 16:50:49.599081	5
4	Content marketing is a significant area of marketing, including video creation, email newsletters, social media posts, blog posts, and more. Content marketing focuses on providing value to the reader with high-quality content that solves pain points and answers questions without being overly promotional. Carefully crafted articles and blog posts can help build trust with your existing and potential customers. They can also help you rank higher in search engines so your target audience can find you, generating more leads and conversions.	2024-04-17 16:50:49.599081	6
5	Content marketing is a significant area of marketing, including video creation, email newsletters, social media posts, blog posts, and more. Content marketing focuses on providing value to the reader with high-quality content that solves pain points and answers questions without being overly promotional. Carefully crafted articles and blog posts can help build trust with your existing and potential customers. They can also help you rank higher in search engines so your target audience can find you, generating more leads and conversions.	2024-04-17 16:50:49.599081	7
6	Content marketing is a significant area of marketing, including video creation, email newsletters, social media posts, blog posts, and more. Content marketing focuses on providing value to the reader with high-quality content that solves pain points and answers questions without being overly promotional. Carefully crafted articles and blog posts can help build trust with your existing and potential customers. They can also help you rank higher in search engines so your target audience can find you, generating more leads and conversions.	2024-04-17 16:50:49.599081	8
7	Content marketing is a significant area of marketing, including video creation, email newsletters, social media posts, blog posts, and more. Content marketing focuses on providing value to the reader with high-quality content that solves pain points and answers questions without being overly promotional. Carefully crafted articles and blog posts can help build trust with your existing and potential customers. They can also help you rank higher in search engines so your target audience can find you, generating more leads and conversions.	2024-04-17 16:50:49.599081	9
8	Content marketing is a significant area of marketing, including video creation, email newsletters, social media posts, blog posts, and more. Content marketing focuses on providing value to the reader with high-quality content that solves pain points and answers questions without being overly promotional. Carefully crafted articles and blog posts can help build trust with your existing and potential customers. They can also help you rank higher in search engines so your target audience can find you, generating more leads and conversions.	2024-04-17 16:50:49.599081	10
9	Content marketing is a significant area of marketing, including video creation, email newsletters, social media posts, blog posts, and more. Content marketing focuses on providing value to the reader with high-quality content that solves pain points and answers questions without being overly promotional. Carefully crafted articles and blog posts can help build trust with your existing and potential customers. They can also help you rank higher in search engines so your target audience can find you, generating more leads and conversions.	2024-04-17 16:50:49.599081	11
10	Content marketing is a significant area of marketing, including video creation, email newsletters, social media posts, blog posts, and more. Content marketing focuses on providing value to the reader with high-quality content that solves pain points and answers questions without being overly promotional. Carefully crafted articles and blog posts can help build trust with your existing and potential customers. They can also help you rank higher in search engines so your target audience can find you, generating more leads and conversions.	2024-04-17 16:50:49.599081	12
11	Content marketing is a significant area of marketing, including video creation, email newsletters, social media posts, blog posts, and more. Content marketing focuses on providing value to the reader with high-quality content that solves pain points and answers questions without being overly promotional. Carefully crafted articles and blog posts can help build trust with your existing and potential customers. They can also help you rank higher in search engines so your target audience can find you, generating more leads and conversions.	2024-04-17 16:50:49.599081	13
12	Content marketing is a significant area of marketing, including video creation, email newsletters, social media posts, blog posts, and more. Content marketing focuses on providing value to the reader with high-quality content that solves pain points and answers questions without being overly promotional. Carefully crafted articles and blog posts can help build trust with your existing and potential customers. They can also help you rank higher in search engines so your target audience can find you, generating more leads and conversions.	2024-04-17 16:50:49.599081	14
13	Content marketing is a significant area of marketing, including video creation, email newsletters, social media posts, blog posts, and more. Content marketing focuses on providing value to the reader with high-quality content that solves pain points and answers questions without being overly promotional. Carefully crafted articles and blog posts can help build trust with your existing and potential customers. They can also help you rank higher in search engines so your target audience can find you, generating more leads and conversions.	2024-04-17 16:50:49.599081	15
14	Content marketing is a significant area of marketing, including video creation, email newsletters, social media posts, blog posts, and more. Content marketing focuses on providing value to the reader with high-quality content that solves pain points and answers questions without being overly promotional. Carefully crafted articles and blog posts can help build trust with your existing and potential customers. They can also help you rank higher in search engines so your target audience can find you, generating more leads and conversions.	2024-04-17 16:50:49.599081	16
15	Content marketing is a significant area of marketing, including video creation, email newsletters, social media posts, blog posts, and more. Content marketing focuses on providing value to the reader with high-quality content that solves pain points and answers questions without being overly promotional. Carefully crafted articles and blog posts can help build trust with your existing and potential customers. They can also help you rank higher in search engines so your target audience can find you, generating more leads and conversions.	2024-04-17 16:50:49.599081	17
16	Content marketing is a significant area of marketing, including video creation, email newsletters, social media posts, blog posts, and more. Content marketing focuses on providing value to the reader with high-quality content that solves pain points and answers questions without being overly promotional. Carefully crafted articles and blog posts can help build trust with your existing and potential customers. They can also help you rank higher in search engines so your target audience can find you, generating more leads and conversions.	2024-04-17 16:50:49.599081	18
17	Content marketing is a significant area of marketing, including video creation, email newsletters, social media posts, blog posts, and more. Content marketing focuses on providing value to the reader with high-quality content that solves pain points and answers questions without being overly promotional. Carefully crafted articles and blog posts can help build trust with your existing and potential customers. They can also help you rank higher in search engines so your target audience can find you, generating more leads and conversions.	2024-04-17 16:50:49.599081	19
18	Content marketing is a significant area of marketing, including video creation, email newsletters, social media posts, blog posts, and more. Content marketing focuses on providing value to the reader with high-quality content that solves pain points and answers questions without being overly promotional. Carefully crafted articles and blog posts can help build trust with your existing and potential customers. They can also help you rank higher in search engines so your target audience can find you, generating more leads and conversions.	2024-04-17 16:50:49.599081	20
19	Content marketing is a significant area of marketing, including video creation, email newsletters, social media posts, blog posts, and more. Content marketing focuses on providing value to the reader with high-quality content that solves pain points and answers questions without being overly promotional. Carefully crafted articles and blog posts can help build trust with your existing and potential customers. They can also help you rank higher in search engines so your target audience can find you, generating more leads and conversions.	2024-04-17 16:50:49.599081	21
20	Content marketing is a significant area of marketing, including video creation, email newsletters, social media posts, blog posts, and more. Content marketing focuses on providing value to the reader with high-quality content that solves pain points and answers questions without being overly promotional. Carefully crafted articles and blog posts can help build trust with your existing and potential customers. They can also help you rank higher in search engines so your target audience can find you, generating more leads and conversions.	2024-04-17 16:50:49.599081	22
21	Content marketing is a significant area of marketing, including video creation, email newsletters, social media posts, blog posts, and more. Content marketing focuses on providing value to the reader with high-quality content that solves pain points and answers questions without being overly promotional. Carefully crafted articles and blog posts can help build trust with your existing and potential customers. They can also help you rank higher in search engines so your target audience can find you, generating more leads and conversions.	2024-04-17 16:50:49.599081	23
22	Content marketing is a significant area of marketing, including video creation, email newsletters, social media posts, blog posts, and more. Content marketing focuses on providing value to the reader with high-quality content that solves pain points and answers questions without being overly promotional. Carefully crafted articles and blog posts can help build trust with your existing and potential customers. They can also help you rank higher in search engines so your target audience can find you, generating more leads and conversions.	2024-04-17 16:50:49.599081	24
23	Content marketing is a significant area of marketing, including video creation, email newsletters, social media posts, blog posts, and more. Content marketing focuses on providing value to the reader with high-quality content that solves pain points and answers questions without being overly promotional. Carefully crafted articles and blog posts can help build trust with your existing and potential customers. They can also help you rank higher in search engines so your target audience can find you, generating more leads and conversions.	2024-04-17 16:50:49.599081	25
24	Content marketing is a significant area of marketing, including video creation, email newsletters, social media posts, blog posts, and more. Content marketing focuses on providing value to the reader with high-quality content that solves pain points and answers questions without being overly promotional. Carefully crafted articles and blog posts can help build trust with your existing and potential customers. They can also help you rank higher in search engines so your target audience can find you, generating more leads and conversions.	2024-04-17 16:50:49.599081	26
25	Content marketing is a significant area of marketing, including video creation, email newsletters, social media posts, blog posts, and more. Content marketing focuses on providing value to the reader with high-quality content that solves pain points and answers questions without being overly promotional. Carefully crafted articles and blog posts can help build trust with your existing and potential customers. They can also help you rank higher in search engines so your target audience can find you, generating more leads and conversions.	2024-04-17 16:50:49.599081	27
26	Content marketing is a significant area of marketing, including video creation, email newsletters, social media posts, blog posts, and more. Content marketing focuses on providing value to the reader with high-quality content that solves pain points and answers questions without being overly promotional. Carefully crafted articles and blog posts can help build trust with your existing and potential customers. They can also help you rank higher in search engines so your target audience can find you, generating more leads and conversions.	2024-04-17 16:50:49.599081	28
27	Content marketing is a significant area of marketing, including video creation, email newsletters, social media posts, blog posts, and more. Content marketing focuses on providing value to the reader with high-quality content that solves pain points and answers questions without being overly promotional. Carefully crafted articles and blog posts can help build trust with your existing and potential customers. They can also help you rank higher in search engines so your target audience can find you, generating more leads and conversions.	2024-04-17 16:50:49.599081	29
28	Content marketing is a significant area of marketing, including video creation, email newsletters, social media posts, blog posts, and more. Content marketing focuses on providing value to the reader with high-quality content that solves pain points and answers questions without being overly promotional. Carefully crafted articles and blog posts can help build trust with your existing and potential customers. They can also help you rank higher in search engines so your target audience can find you, generating more leads and conversions.	2024-04-17 16:50:49.599081	30
\.


--
-- Data for Name: article_comment; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.article_comment (id, text, commented_at, "commenterId", "articleId") FROM stdin;
1	well post	2024-04-21 17:59:33.625031	2	5
\.


--
-- Data for Name: article_image; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.article_image (id, name, "articleId") FROM stdin;
\.


--
-- Data for Name: article_reaction; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.article_reaction (id, type, reacted_at, "reactorId", "articleId") FROM stdin;
1	li	2024-04-17 18:07:40.518855	2	2
2	li	2024-04-17 18:08:29.548787	3	2
3	li	2024-04-17 18:07:40.518855	31	3
4	li	2024-04-17 18:07:40.518855	32	3
5	li	2024-04-17 18:07:40.518855	33	3
6	li	2024-04-17 18:07:40.518855	34	3
7	li	2024-04-17 18:07:40.518855	35	3
8	li	2024-04-17 18:07:40.518855	36	3
9	li	2024-04-17 18:07:40.518855	37	3
10	li	2024-04-17 18:07:40.518855	38	3
11	li	2024-04-17 18:07:40.518855	39	3
12	li	2024-04-17 18:07:40.518855	40	3
13	li	2024-04-17 18:07:40.518855	41	3
14	li	2024-04-17 18:07:40.518855	42	3
15	li	2024-04-17 18:07:40.518855	43	3
16	li	2024-04-17 18:07:40.518855	44	3
17	li	2024-04-17 18:07:40.518855	45	3
18	li	2024-04-17 18:07:40.518855	46	3
19	li	2024-04-17 18:07:40.518855	31	4
20	li	2024-04-17 18:07:40.518855	32	4
21	li	2024-04-17 18:07:40.518855	33	4
22	li	2024-04-17 18:07:40.518855	34	4
23	li	2024-04-17 18:07:40.518855	35	4
24	li	2024-04-17 18:07:40.518855	36	4
25	li	2024-04-17 18:07:40.518855	37	4
26	li	2024-04-17 18:07:40.518855	38	4
27	li	2024-04-17 18:07:40.518855	39	4
28	li	2024-04-17 18:07:40.518855	40	4
29	li	2024-04-17 18:07:40.518855	41	4
30	li	2024-04-17 18:07:40.518855	42	4
31	li	2024-04-17 18:07:40.518855	43	4
32	li	2024-04-17 18:07:40.518855	44	4
33	li	2024-04-17 18:07:40.518855	45	4
34	li	2024-04-17 18:07:40.518855	46	4
35	li	2024-04-17 18:07:40.518855	31	5
36	li	2024-04-17 18:07:40.518855	32	5
37	li	2024-04-17 18:07:40.518855	33	5
38	li	2024-04-17 18:07:40.518855	34	5
39	li	2024-04-17 18:07:40.518855	35	5
40	li	2024-04-17 18:07:40.518855	36	5
41	li	2024-04-17 18:07:40.518855	37	5
42	li	2024-04-17 18:07:40.518855	38	5
43	li	2024-04-17 18:07:40.518855	39	5
44	li	2024-04-17 18:07:40.518855	40	5
45	li	2024-04-17 18:07:40.518855	41	5
46	li	2024-04-17 18:07:40.518855	42	5
47	li	2024-04-17 18:07:40.518855	43	5
48	li	2024-04-17 18:07:40.518855	44	5
49	li	2024-04-17 18:07:40.518855	45	5
50	li	2024-04-17 18:07:40.518855	46	5
51	li	2024-04-17 18:07:40.518855	31	6
52	li	2024-04-17 18:07:40.518855	32	6
53	li	2024-04-17 18:07:40.518855	33	6
54	li	2024-04-17 18:07:40.518855	34	6
55	li	2024-04-17 18:07:40.518855	35	6
56	li	2024-04-17 18:07:40.518855	36	6
57	li	2024-04-17 18:07:40.518855	37	6
58	li	2024-04-17 18:07:40.518855	38	6
59	li	2024-04-17 18:07:40.518855	39	6
60	li	2024-04-17 18:07:40.518855	40	6
61	li	2024-04-17 18:07:40.518855	41	6
62	li	2024-04-17 18:07:40.518855	42	6
63	li	2024-04-17 18:07:40.518855	43	6
64	li	2024-04-17 18:07:40.518855	44	6
65	li	2024-04-17 18:07:40.518855	45	6
66	li	2024-04-17 18:07:40.518855	46	6
67	li	2024-04-17 18:07:40.518855	31	7
68	li	2024-04-17 18:07:40.518855	32	7
69	li	2024-04-17 18:07:40.518855	33	7
70	li	2024-04-17 18:07:40.518855	34	7
71	li	2024-04-17 18:07:40.518855	35	7
72	li	2024-04-17 18:07:40.518855	36	7
73	li	2024-04-17 18:07:40.518855	37	7
74	li	2024-04-17 18:07:40.518855	38	7
75	li	2024-04-17 18:07:40.518855	39	7
76	li	2024-04-17 18:07:40.518855	40	7
77	li	2024-04-17 18:07:40.518855	41	7
78	li	2024-04-17 18:07:40.518855	42	7
79	li	2024-04-17 18:07:40.518855	43	7
80	li	2024-04-17 18:07:40.518855	44	7
81	li	2024-04-17 18:07:40.518855	45	7
82	li	2024-04-17 18:07:40.518855	46	7
83	li	2024-04-17 18:07:40.518855	31	8
84	li	2024-04-17 18:07:40.518855	32	8
85	li	2024-04-17 18:07:40.518855	33	8
86	li	2024-04-17 18:07:40.518855	34	8
87	li	2024-04-17 18:07:40.518855	35	8
88	li	2024-04-17 18:07:40.518855	36	8
89	li	2024-04-17 18:07:40.518855	37	8
90	li	2024-04-17 18:07:40.518855	38	8
91	li	2024-04-17 18:07:40.518855	39	8
92	li	2024-04-17 18:07:40.518855	40	8
93	li	2024-04-17 18:07:40.518855	41	8
94	li	2024-04-17 18:07:40.518855	42	8
95	li	2024-04-17 18:07:40.518855	43	8
96	li	2024-04-17 18:07:40.518855	44	8
97	li	2024-04-17 18:07:40.518855	45	8
98	li	2024-04-17 18:07:40.518855	46	8
99	li	2024-04-17 18:07:40.518855	31	9
100	li	2024-04-17 18:07:40.518855	32	9
101	li	2024-04-17 18:07:40.518855	33	9
102	li	2024-04-17 18:07:40.518855	34	9
103	li	2024-04-17 18:07:40.518855	35	9
104	li	2024-04-17 18:07:40.518855	36	9
105	li	2024-04-17 18:07:40.518855	37	9
106	li	2024-04-17 18:07:40.518855	38	9
107	li	2024-04-17 18:07:40.518855	39	9
108	li	2024-04-17 18:07:40.518855	40	9
109	li	2024-04-17 18:07:40.518855	41	9
110	li	2024-04-17 18:07:40.518855	42	9
111	li	2024-04-17 18:07:40.518855	43	9
112	li	2024-04-17 18:07:40.518855	44	9
113	li	2024-04-17 18:07:40.518855	45	9
114	li	2024-04-17 18:07:40.518855	46	9
115	li	2024-04-17 18:07:40.518855	31	10
116	li	2024-04-17 18:07:40.518855	32	10
117	li	2024-04-17 18:07:40.518855	33	10
118	li	2024-04-17 18:07:40.518855	34	10
119	li	2024-04-17 18:07:40.518855	35	10
120	li	2024-04-17 18:07:40.518855	36	10
121	li	2024-04-17 18:07:40.518855	37	10
122	li	2024-04-17 18:07:40.518855	38	10
123	li	2024-04-17 18:07:40.518855	39	10
124	li	2024-04-17 18:07:40.518855	40	10
125	li	2024-04-17 18:07:40.518855	41	10
126	li	2024-04-17 18:07:40.518855	42	10
127	li	2024-04-17 18:07:40.518855	43	10
128	li	2024-04-17 18:07:40.518855	44	10
129	li	2024-04-17 18:07:40.518855	45	10
130	li	2024-04-17 18:07:40.518855	46	10
131	li	2024-04-17 18:07:40.518855	31	11
132	li	2024-04-17 18:07:40.518855	32	11
133	li	2024-04-17 18:07:40.518855	33	11
134	li	2024-04-17 18:07:40.518855	34	11
135	li	2024-04-17 18:07:40.518855	35	11
136	li	2024-04-17 18:07:40.518855	36	11
137	li	2024-04-17 18:07:40.518855	37	11
138	li	2024-04-17 18:07:40.518855	38	11
139	li	2024-04-17 18:07:40.518855	39	11
140	li	2024-04-17 18:07:40.518855	40	11
141	li	2024-04-17 18:07:40.518855	41	11
142	li	2024-04-17 18:07:40.518855	42	11
143	li	2024-04-17 18:07:40.518855	43	11
144	li	2024-04-17 18:07:40.518855	44	11
145	li	2024-04-17 18:07:40.518855	45	11
146	li	2024-04-17 18:07:40.518855	46	11
147	li	2024-04-17 18:07:40.518855	31	12
148	li	2024-04-17 18:07:40.518855	32	12
149	li	2024-04-17 18:07:40.518855	33	12
150	li	2024-04-17 18:07:40.518855	34	12
151	li	2024-04-17 18:07:40.518855	35	12
152	li	2024-04-17 18:07:40.518855	36	12
153	li	2024-04-17 18:07:40.518855	37	12
154	li	2024-04-17 18:07:40.518855	38	12
155	li	2024-04-17 18:07:40.518855	39	12
156	li	2024-04-17 18:07:40.518855	40	12
157	li	2024-04-17 18:07:40.518855	41	12
158	li	2024-04-17 18:07:40.518855	42	12
159	li	2024-04-17 18:07:40.518855	43	12
160	li	2024-04-17 18:07:40.518855	44	12
161	li	2024-04-17 18:07:40.518855	45	12
162	li	2024-04-17 18:07:40.518855	46	12
163	li	2024-04-17 18:07:40.518855	31	13
164	li	2024-04-17 18:07:40.518855	32	13
165	li	2024-04-17 18:07:40.518855	33	13
166	li	2024-04-17 18:07:40.518855	34	13
167	li	2024-04-17 18:07:40.518855	35	13
168	li	2024-04-17 18:07:40.518855	36	13
169	li	2024-04-17 18:07:40.518855	37	13
170	li	2024-04-17 18:07:40.518855	38	13
171	li	2024-04-17 18:07:40.518855	39	13
172	li	2024-04-17 18:07:40.518855	40	13
173	li	2024-04-17 18:07:40.518855	41	13
174	li	2024-04-17 18:07:40.518855	42	13
175	li	2024-04-17 18:07:40.518855	43	13
176	li	2024-04-17 18:07:40.518855	44	13
177	li	2024-04-17 18:07:40.518855	45	13
178	li	2024-04-17 18:07:40.518855	46	13
179	li	2024-04-17 18:07:40.518855	31	14
180	li	2024-04-17 18:07:40.518855	32	14
181	li	2024-04-17 18:07:40.518855	33	14
182	li	2024-04-17 18:07:40.518855	34	14
183	li	2024-04-17 18:07:40.518855	35	14
184	li	2024-04-17 18:07:40.518855	36	14
185	li	2024-04-17 18:07:40.518855	37	14
186	li	2024-04-17 18:07:40.518855	38	14
187	li	2024-04-17 18:07:40.518855	39	14
188	li	2024-04-17 18:07:40.518855	40	14
189	li	2024-04-17 18:07:40.518855	41	14
190	li	2024-04-17 18:07:40.518855	42	14
191	li	2024-04-17 18:07:40.518855	43	14
192	li	2024-04-17 18:07:40.518855	44	14
193	li	2024-04-17 18:07:40.518855	45	14
194	li	2024-04-17 18:07:40.518855	46	14
195	li	2024-04-17 18:07:40.518855	31	15
196	li	2024-04-17 18:07:40.518855	32	15
197	li	2024-04-17 18:07:40.518855	33	15
198	li	2024-04-17 18:07:40.518855	34	15
199	li	2024-04-17 18:07:40.518855	35	15
200	li	2024-04-17 18:07:40.518855	36	15
201	li	2024-04-17 18:07:40.518855	37	15
202	li	2024-04-17 18:07:40.518855	38	15
203	li	2024-04-17 18:07:40.518855	39	15
204	li	2024-04-17 18:07:40.518855	40	15
205	li	2024-04-17 18:07:40.518855	41	15
206	li	2024-04-17 18:07:40.518855	42	15
207	li	2024-04-17 18:07:40.518855	43	15
208	li	2024-04-17 18:07:40.518855	44	15
209	li	2024-04-17 18:07:40.518855	45	15
210	li	2024-04-17 18:07:40.518855	46	15
211	li	2024-04-17 18:07:40.518855	31	16
212	li	2024-04-17 18:07:40.518855	32	16
213	li	2024-04-17 18:07:40.518855	33	16
214	li	2024-04-17 18:07:40.518855	34	16
215	li	2024-04-17 18:07:40.518855	35	16
216	li	2024-04-17 18:07:40.518855	36	16
217	li	2024-04-17 18:07:40.518855	37	16
218	li	2024-04-17 18:07:40.518855	38	16
219	li	2024-04-17 18:07:40.518855	39	16
220	li	2024-04-17 18:07:40.518855	40	16
221	li	2024-04-17 18:07:40.518855	41	16
222	li	2024-04-17 18:07:40.518855	42	16
223	li	2024-04-17 18:07:40.518855	43	16
224	li	2024-04-17 18:07:40.518855	44	16
225	li	2024-04-17 18:07:40.518855	45	16
226	li	2024-04-17 18:07:40.518855	46	16
227	li	2024-04-17 18:07:40.518855	31	17
228	li	2024-04-17 18:07:40.518855	32	17
229	li	2024-04-17 18:07:40.518855	33	17
230	li	2024-04-17 18:07:40.518855	34	17
231	li	2024-04-17 18:07:40.518855	35	17
232	li	2024-04-17 18:07:40.518855	36	17
233	li	2024-04-17 18:07:40.518855	37	17
234	li	2024-04-17 18:07:40.518855	38	17
235	li	2024-04-17 18:07:40.518855	39	17
236	li	2024-04-17 18:07:40.518855	40	17
237	li	2024-04-17 18:07:40.518855	41	17
238	li	2024-04-17 18:07:40.518855	42	17
239	li	2024-04-17 18:07:40.518855	43	17
240	li	2024-04-17 18:07:40.518855	44	17
241	li	2024-04-17 18:07:40.518855	45	17
242	li	2024-04-17 18:07:40.518855	46	17
243	li	2024-04-17 18:07:40.518855	31	18
244	li	2024-04-17 18:07:40.518855	32	18
245	li	2024-04-17 18:07:40.518855	33	18
246	li	2024-04-17 18:07:40.518855	34	18
247	li	2024-04-17 18:07:40.518855	35	18
248	li	2024-04-17 18:07:40.518855	36	18
249	li	2024-04-17 18:07:40.518855	37	18
250	li	2024-04-17 18:07:40.518855	38	18
251	li	2024-04-17 18:07:40.518855	39	18
252	li	2024-04-17 18:07:40.518855	40	18
253	li	2024-04-17 18:07:40.518855	41	18
254	li	2024-04-17 18:07:40.518855	42	18
255	li	2024-04-17 18:07:40.518855	43	18
256	li	2024-04-17 18:07:40.518855	44	18
257	li	2024-04-17 18:07:40.518855	45	18
258	li	2024-04-17 18:07:40.518855	46	18
259	li	2024-04-17 18:07:40.518855	31	19
260	li	2024-04-17 18:07:40.518855	32	19
261	li	2024-04-17 18:07:40.518855	33	19
262	li	2024-04-17 18:07:40.518855	34	19
263	li	2024-04-17 18:07:40.518855	35	19
264	li	2024-04-17 18:07:40.518855	36	19
265	li	2024-04-17 18:07:40.518855	37	19
266	li	2024-04-17 18:07:40.518855	38	19
267	li	2024-04-17 18:07:40.518855	39	19
268	li	2024-04-17 18:07:40.518855	40	19
269	li	2024-04-17 18:07:40.518855	41	19
270	li	2024-04-17 18:07:40.518855	42	19
271	li	2024-04-17 18:07:40.518855	43	19
272	li	2024-04-17 18:07:40.518855	44	19
273	li	2024-04-17 18:07:40.518855	45	19
274	li	2024-04-17 18:07:40.518855	46	19
275	li	2024-04-17 18:07:40.518855	31	20
276	li	2024-04-17 18:07:40.518855	32	20
277	li	2024-04-17 18:07:40.518855	33	20
278	li	2024-04-17 18:07:40.518855	34	20
279	li	2024-04-17 18:07:40.518855	35	20
280	li	2024-04-17 18:07:40.518855	36	20
281	li	2024-04-17 18:07:40.518855	37	20
282	li	2024-04-17 18:07:40.518855	38	20
283	li	2024-04-17 18:07:40.518855	39	20
284	li	2024-04-17 18:07:40.518855	40	20
285	li	2024-04-17 18:07:40.518855	41	20
286	li	2024-04-17 18:07:40.518855	42	20
287	li	2024-04-17 18:07:40.518855	43	20
288	li	2024-04-17 18:07:40.518855	44	20
289	li	2024-04-17 18:07:40.518855	45	20
290	li	2024-04-17 18:07:40.518855	46	20
291	li	2024-04-17 18:07:40.518855	31	21
292	li	2024-04-17 18:07:40.518855	32	21
293	li	2024-04-17 18:07:40.518855	33	21
294	li	2024-04-17 18:07:40.518855	34	21
295	li	2024-04-17 18:07:40.518855	35	21
296	li	2024-04-17 18:07:40.518855	36	21
297	li	2024-04-17 18:07:40.518855	37	21
298	li	2024-04-17 18:07:40.518855	38	21
299	li	2024-04-17 18:07:40.518855	39	21
300	li	2024-04-17 18:07:40.518855	40	21
301	li	2024-04-17 18:07:40.518855	41	21
302	li	2024-04-17 18:07:40.518855	42	21
303	li	2024-04-17 18:07:40.518855	43	21
304	li	2024-04-17 18:07:40.518855	44	21
305	li	2024-04-17 18:07:40.518855	45	21
306	li	2024-04-17 18:07:40.518855	46	21
307	li	2024-04-17 18:07:40.518855	31	22
308	li	2024-04-17 18:07:40.518855	32	22
309	li	2024-04-17 18:07:40.518855	33	22
310	li	2024-04-17 18:07:40.518855	34	22
311	li	2024-04-17 18:07:40.518855	35	22
312	li	2024-04-17 18:07:40.518855	36	22
313	li	2024-04-17 18:07:40.518855	37	22
314	li	2024-04-17 18:07:40.518855	38	22
315	li	2024-04-17 18:07:40.518855	39	22
316	li	2024-04-17 18:07:40.518855	40	22
317	li	2024-04-17 18:07:40.518855	41	22
318	li	2024-04-17 18:07:40.518855	42	22
319	li	2024-04-17 18:07:40.518855	43	22
320	li	2024-04-17 18:07:40.518855	44	22
321	li	2024-04-17 18:07:40.518855	45	22
322	li	2024-04-17 18:07:40.518855	46	22
323	li	2024-04-17 18:07:40.518855	31	23
324	li	2024-04-17 18:07:40.518855	32	23
325	li	2024-04-17 18:07:40.518855	33	23
326	li	2024-04-17 18:07:40.518855	34	23
327	li	2024-04-17 18:07:40.518855	35	23
328	li	2024-04-17 18:07:40.518855	36	23
329	li	2024-04-17 18:07:40.518855	37	23
330	li	2024-04-17 18:07:40.518855	38	23
331	li	2024-04-17 18:07:40.518855	39	23
332	li	2024-04-17 18:07:40.518855	40	23
333	li	2024-04-17 18:07:40.518855	41	23
334	li	2024-04-17 18:07:40.518855	42	23
335	li	2024-04-17 18:07:40.518855	43	23
336	li	2024-04-17 18:07:40.518855	44	23
337	li	2024-04-17 18:07:40.518855	45	23
338	li	2024-04-17 18:07:40.518855	46	23
339	li	2024-04-17 18:07:40.518855	31	24
340	li	2024-04-17 18:07:40.518855	32	24
341	li	2024-04-17 18:07:40.518855	33	24
342	li	2024-04-17 18:07:40.518855	34	24
343	li	2024-04-17 18:07:40.518855	35	24
344	li	2024-04-17 18:07:40.518855	36	24
345	li	2024-04-17 18:07:40.518855	37	24
346	li	2024-04-17 18:07:40.518855	38	24
347	li	2024-04-17 18:07:40.518855	39	24
348	li	2024-04-17 18:07:40.518855	40	24
349	li	2024-04-17 18:07:40.518855	41	24
350	li	2024-04-17 18:07:40.518855	42	24
351	li	2024-04-17 18:07:40.518855	43	24
352	li	2024-04-17 18:07:40.518855	44	24
353	li	2024-04-17 18:07:40.518855	45	24
354	li	2024-04-17 18:07:40.518855	46	24
355	li	2024-04-17 18:07:40.518855	31	25
356	li	2024-04-17 18:07:40.518855	32	25
357	li	2024-04-17 18:07:40.518855	33	25
358	li	2024-04-17 18:07:40.518855	34	25
359	li	2024-04-17 18:07:40.518855	35	25
360	li	2024-04-17 18:07:40.518855	36	25
361	li	2024-04-17 18:07:40.518855	37	25
362	li	2024-04-17 18:07:40.518855	38	25
363	li	2024-04-17 18:07:40.518855	39	25
364	li	2024-04-17 18:07:40.518855	40	25
365	li	2024-04-17 18:07:40.518855	41	25
366	li	2024-04-17 18:07:40.518855	42	25
367	li	2024-04-17 18:07:40.518855	43	25
368	li	2024-04-17 18:07:40.518855	44	25
369	li	2024-04-17 18:07:40.518855	45	25
370	li	2024-04-17 18:07:40.518855	46	25
371	li	2024-04-17 18:07:40.518855	31	26
372	li	2024-04-17 18:07:40.518855	32	26
373	li	2024-04-17 18:07:40.518855	33	26
374	li	2024-04-17 18:07:40.518855	34	26
375	li	2024-04-17 18:07:40.518855	35	26
376	li	2024-04-17 18:07:40.518855	36	26
377	li	2024-04-17 18:07:40.518855	37	26
378	li	2024-04-17 18:07:40.518855	38	26
379	li	2024-04-17 18:07:40.518855	39	26
380	li	2024-04-17 18:07:40.518855	40	26
381	li	2024-04-17 18:07:40.518855	41	26
382	li	2024-04-17 18:07:40.518855	42	26
383	li	2024-04-17 18:07:40.518855	43	26
384	li	2024-04-17 18:07:40.518855	44	26
385	li	2024-04-17 18:07:40.518855	45	26
386	li	2024-04-17 18:07:40.518855	46	26
387	li	2024-04-17 18:07:40.518855	31	27
388	li	2024-04-17 18:07:40.518855	32	27
389	li	2024-04-17 18:07:40.518855	33	27
390	li	2024-04-17 18:07:40.518855	34	27
391	li	2024-04-17 18:07:40.518855	35	27
392	li	2024-04-17 18:07:40.518855	36	27
393	li	2024-04-17 18:07:40.518855	37	27
394	li	2024-04-17 18:07:40.518855	38	27
395	li	2024-04-17 18:07:40.518855	39	27
396	li	2024-04-17 18:07:40.518855	40	27
397	li	2024-04-17 18:07:40.518855	41	27
398	li	2024-04-17 18:07:40.518855	42	27
399	li	2024-04-17 18:07:40.518855	43	27
400	li	2024-04-17 18:07:40.518855	44	27
401	li	2024-04-17 18:07:40.518855	45	27
402	li	2024-04-17 18:07:40.518855	46	27
403	li	2024-04-17 18:07:40.518855	31	28
404	li	2024-04-17 18:07:40.518855	32	28
405	li	2024-04-17 18:07:40.518855	33	28
406	li	2024-04-17 18:07:40.518855	34	28
407	li	2024-04-17 18:07:40.518855	35	28
408	li	2024-04-17 18:07:40.518855	36	28
409	li	2024-04-17 18:07:40.518855	37	28
410	li	2024-04-17 18:07:40.518855	38	28
411	li	2024-04-17 18:07:40.518855	39	28
412	li	2024-04-17 18:07:40.518855	40	28
413	li	2024-04-17 18:07:40.518855	41	28
414	li	2024-04-17 18:07:40.518855	42	28
415	li	2024-04-17 18:07:40.518855	43	28
416	li	2024-04-17 18:07:40.518855	44	28
417	li	2024-04-17 18:07:40.518855	45	28
418	li	2024-04-17 18:07:40.518855	46	28
419	li	2024-04-20 23:42:07.308536	2	5
420	li	2024-04-21 18:00:03.71608	2	3
\.


--
-- Data for Name: article_video; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.article_video (id, name, "articleId") FROM stdin;
\.


--
-- Data for Name: chat; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.chat (id, last_message) FROM stdin;
2	2024-04-20 15:01:00.901
3	2024-04-21 16:32:35.509
1	2024-04-21 17:42:56.802
\.


--
-- Data for Name: chat_users_user; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.chat_users_user ("chatId", "userId") FROM stdin;
1	3
1	2
2	2
2	6
3	2
3	8
\.


--
-- Data for Name: company; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.company (id, name) FROM stdin;
1	CareerBuilder
2	Amazon
3	Indeed
4	Google
5	Microsoft
6	Orange
7	ABC
8	IBM
9	Apple
10	Tata Technologies
\.


--
-- Data for Name: contributor_levels; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.contributor_levels (id, level_name) FROM stdin;
1	Contributor
2	Facilitator
3	Mentor
4	Role Model
5	Executive Role Model
\.


--
-- Data for Name: education; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.education (id, school, degree, "fieldOfStudy", "startDate", "endDate", grade, description, "userId") FROM stdin;
1	International School of US	High School Diploma	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			2
2	International School of US	High School Diploma	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			3
3	International School of US	High School Diploma	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			94
4	International School of US	High School Diploma	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			5
5	International School of US	High School Diploma	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			6
6	International School of US	High School Diploma	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			7
7	International School of US	Bachelor of Science in Business Administration	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			8
8	International School of US	High School Diploma	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			9
9	International School of US	High School Diploma	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			10
10	International School of US	High School Diploma	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			11
11	International School of US	Bachelor of Science in Computer Science	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			12
12	International School of US	High School Diploma	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			13
13	International School of US	Bachelor of Science in Business Administration	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			14
14	International School of US	High School Diploma	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			15
15	International School of US	High School Diploma	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			16
16	International School of US	Bachelor of Science in Computer Science	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			17
17	International School of US	High School Diploma	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			18
18	International School of US	Bachelor of Science in Business Administration	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			19
19	International School of US	High School Diploma	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			20
20	International School of US	High School Diploma	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			21
21	International School of US	Bachelor of Science in Computer Science	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			22
22	International School of US	High School Diploma	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			23
23	International School of US	Bachelor of Science in Business Administration	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			24
24	International School of US	High School Diploma	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			25
25	International School of US	High School Diploma	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			26
26	International School of US	Bachelor of Science in Computer Science	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			27
27	International School of US	High School Diploma	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			28
28	International School of US	Bachelor of Science in Business Administration	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			29
29	International School of US	High School Diploma	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			30
30	International School of US	High School Diploma	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			31
31	International School of US	Bachelor of Science in Computer Science	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			32
32	International School of US	High School Diploma	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			33
33	International School of US	Bachelor of Science in Business Administration	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			34
34	International School of US	High School Diploma	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			35
35	International School of US	High School Diploma	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			36
36	International School of US	Bachelor of Science in Computer Science	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			37
37	International School of US	High School Diploma	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			38
38	International School of US	Bachelor of Science in Business Administration	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			39
39	International School of US	High School Diploma	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			40
40	International School of US	High School Diploma	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			41
41	International School of US	Bachelor of Science in Computer Science	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			42
42	International School of US	High School Diploma	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			43
43	International School of US	Bachelor of Science in Business Administration	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			44
44	International School of US	High School Diploma	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			45
45	International School of US	High School Diploma	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			46
46	International School of US	High School Diploma	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			47
47	International School of US	Bachelor of Science in Computer Science	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			48
48	International School of US	High School Diploma	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			49
49	International School of US	High School Diploma	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			50
50	International School of US	Bachelor of Arts in Marketing	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			51
51	International School of US	High School Diploma	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			52
52	International School of US	High School Diploma	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			53
53	International School of US	Bachelor of Science in Computer Science	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			54
54	International School of US	High School Diploma	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			55
55	International School of US	Bachelor of Science in Business Administration	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			56
56	International School of US	High School Diploma	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			57
57	International School of US	High School Diploma	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			58
58	International School of US	Bachelor of Science in Computer Science	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			59
59	International School of US	High School Diploma	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			60
60	International School of US	Bachelor of Science in Business Administration	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			61
61	International School of US	High School Diploma	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			62
62	International School of US	High School Diploma	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			63
63	International School of US	Bachelor of Science in Computer Science	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			64
64	International School of US	High School Diploma	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			65
65	International School of US	Bachelor of Science in Business Administration	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			66
66	International School of US	High School Diploma	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			67
67	International School of US	High School Diploma	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			68
68	International School of US	Bachelor of Science in Computer Science	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			69
69	International School of US	Bachelor of Science in Business Administration	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			70
70	International School of US	High School Diploma	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			71
71	International School of US	High School Diploma	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			72
72	International School of US	Bachelor of Science in Computer Science	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			73
73	International School of US	High School Diploma	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			74
74	International School of US	Bachelor of Science in Business Administration	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			75
75	International School of US	High School Diploma	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			76
76	International School of US	High School Diploma	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			77
77	International School of US	Bachelor of Science in Computer Science	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			78
78	International School of US	High School Diploma	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			79
79	International School of US	High School Diploma	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			80
80	International School of US	Bachelor of Science in Computer Science	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			81
81	International School of US	High School Diploma	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			82
82	International School of US	Bachelor of Science in Business Administration	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			83
83	International School of US	High School Diploma	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			84
84	International School of US	High School Diploma	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			85
85	International School of US	Bachelor of Science in Computer Science	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			86
86	International School of US	High School Diploma	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			87
87	International School of US	High School Diploma	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			88
88	International School of US	Bachelor of Science in Computer Science	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			89
89	International School of US	High School Diploma	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			90
90	International School of US	Bachelor of Science in Business Administration	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			91
91	International School of US	High School Diploma	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			92
92	International School of US	High School Diploma	Education	2013-04-17 17:27:06.159088	2017-04-17 17:27:06.159088			93
\.


--
-- Data for Name: experience; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.experience (id, title, "employmentType", location, "startDate", "endDate", description, "userId", "companyId") FROM stdin;
107	Customer Service Representative	co	Austin, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Provided excellent customer service via phone and email.	2	1
108	Customer Service Representative	co	Houston, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Handled customer inquiries and resolved issues efficiently.	3	1
109	Customer Service Representative	co	San Antonio, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Provided friendly and efficient customer service via phone and chat.	94	1
110	Customer Service Representative	co	Dallas, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Resolved customer inquiries and issues with professionalism and empathy.	5	1
111	Customer Service Representative	co	Austin, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Assisted customers with inquiries and provided solutions.	6	1
112	Customer Service Representative	co	Houston, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Provided prompt and courteous assistance to customers via phone and email.	7	1
113	Customer Service Representative	co	Dallas, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Provided exceptional customer service and resolved issues.	8	1
114	Customer Service Representative	co	Austin, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Assisted customers with inquiries and provided solutions.	9	1
115	Customer Service Representative	co	San Antonio, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Provided friendly and efficient customer service via phone and chat.	10	1
116	Customer Service Representative	co	Austin, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Handled customer inquiries and resolved issues efficiently.	11	1
117	Customer Service Representative	co	Dallas, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Resolved customer inquiries and technical issues with professionalism.	12	1
118	Customer Service Representative	co	Austin, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Provided exceptional customer service and resolved issues.	13	1
119	Customer Service Representative	co	Austin, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Assisted customers with inquiries and provided solutions.	14	1
120	Customer Service Representative	co	San Antonio, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Provided friendly and efficient customer service via phone and chat.	15	1
121	Customer Service Representative	co	Austin, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Handled customer inquiries and resolved issues efficiently.	16	1
122	Customer Service Representative	co	Dallas, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Resolved customer inquiries and technical issues with professionalism.	17	1
123	Customer Service Representative	co	Austin, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Provided exceptional customer service and resolved issues.	18	1
124	Customer Service Representative	co	Austin, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Assisted customers with inquiries and provided solutions.	19	1
125	Customer Service Representative	co	San Antonio, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Provided friendly and efficient customer service via phone and chat.	20	1
126	Customer Service Representative	co	Austin, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Handled customer inquiries and resolved issues efficiently.	21	1
127	Customer Service Representative	co	Dallas, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Resolved customer inquiries and technical issues with professionalism.	22	1
128	Customer Service Representative	co	Austin, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Provided exceptional customer service and resolved issues.	23	1
129	Customer Service Representative	co	Austin, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Assisted customers with inquiries and provided solutions.	24	1
130	Customer Service Representative	co	San Antonio, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Provided friendly and efficient customer service via phone and chat.	25	1
131	Customer Service Representative	co	Austin, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Handled customer inquiries and resolved issues efficiently.	26	1
132	Customer Service Representative	co	Dallas, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Resolved customer inquiries and technical issues with professionalism.	27	1
133	Customer Service Representative	co	Austin, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Provided exceptional customer service and resolved issues.	28	1
134	Customer Service Representative	co	Austin, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Assisted customers with inquiries and provided solutions.	29	1
135	Customer Service Representative	co	San Antonio, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Provided friendly and efficient customer service via phone and chat.	30	1
136	Customer Service Representative	co	Austin, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Handled customer inquiries and resolved issues efficiently.	31	1
137	Customer Service Representative	co	Dallas, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Resolved customer inquiries and technical issues with professionalism.	32	1
138	Customer Service Representative	co	Austin, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Provided exceptional customer service and resolved issues.	33	1
139	Customer Service Representative	co	Austin, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Assisted customers with inquiries and provided solutions.	34	1
140	Customer Service Representative	co	San Antonio, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Provided friendly and efficient customer service via phone and chat.	35	1
141	Customer Service Representative	co	Austin, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Handled customer inquiries and resolved issues efficiently.	36	1
142	Customer Service Representative	co	Dallas, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Resolved customer inquiries and technical issues with professionalism.	37	1
143	Customer Service Representative	co	Austin, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Provided exceptional customer service and resolved issues.	38	1
144	Customer Service Representative	co	Austin, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Assisted customers with inquiries and provided solutions.	39	1
145	Customer Service Representative	co	San Antonio, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Provided friendly and efficient customer service via phone and chat.	40	1
146	Customer Service Representative	co	Austin, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Handled customer inquiries and resolved issues efficiently.	41	1
147	Customer Service Representative	co	Dallas, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Resolved customer inquiries and technical issues with professionalism.	42	1
148	Customer Service Representative	co	Austin, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Provided exceptional customer service and resolved issues.	43	1
149	Customer Service Representative	co	Austin, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Provided exceptional customer service via phone and email.	44	1
150	Customer Service Representative	co	Dallas, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Assisted customers with inquiries and provided solutions.	45	1
151	Customer Service Representative	co	San Antonio, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Provided friendly and efficient customer service via phone and chat.	46	1
152	Customer Service Representative	co	Austin, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Handled customer inquiries and resolved issues efficiently.	47	1
153	Customer Service Representative	co	Dallas, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Resolved customer inquiries and technical issues with professionalism.	48	1
154	Customer Service Representative	co	Austin, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Assisted customers with inquiries and provided solutions.	49	1
155	Customer Service Representative	co	Dallas, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Resolved customer inquiries and issues with professionalism and empathy.	50	1
156	Customer Service Representative	co	Houston, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Provided exceptional customer service and resolved issues.	51	1
157	Customer Service Representative	co	Dallas, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Assisted customers with inquiries and provided solutions.	52	1
158	Customer Service Representative	co	San Antonio, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Provided friendly and efficient customer service via phone and chat.	53	1
159	Customer Service Representative	co	Dallas, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Resolved customer inquiries and technical issues with professionalism.	54	1
160	Customer Service Representative	co	Austin, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Provided exceptional customer service via phone and email.	55	1
161	Customer Service Representative	co	Austin, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Assisted customers with inquiries and provided solutions.	56	1
162	Customer Service Representative	co	San Antonio, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Provided friendly and efficient customer service via phone and chat.	57	1
163	Customer Service Representative	co	Austin, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Handled customer inquiries and resolved issues efficiently.	58	1
164	Customer Service Representative	co	Dallas, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Resolved customer inquiries and technical issues with professionalism.	59	1
165	Customer Service Representative	co	Austin, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Provided exceptional customer service and resolved issues.	60	1
166	Customer Service Representative	co	Austin, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Assisted customers with inquiries and provided solutions.	61	1
167	Customer Service Representative	co	San Antonio, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Provided friendly and efficient customer service via phone and chat.	62	1
168	Customer Service Representative	co	Austin, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Handled customer inquiries and resolved issues efficiently.	63	1
169	Customer Service Representative	co	Dallas, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Resolved customer inquiries and technical issues with professionalism.	64	1
170	Customer Service Representative	co	Austin, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Provided exceptional customer service and resolved issues.	65	1
171	Customer Service Representative	co	Austin, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Assisted customers with inquiries and provided solutions.	66	1
172	Customer Service Representative	co	San Antonio, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Provided friendly and efficient customer service via phone and chat.	67	1
173	Customer Service Representative	co	Austin, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Handled customer inquiries and resolved issues efficiently.	68	1
174	Customer Service Representative	co	Dallas, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Resolved customer inquiries and technical issues with professionalism.	69	1
175	Customer Service Representative	co	Austin, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Assisted customers with inquiries and provided solutions.	70	1
176	Customer Service Representative	co	San Antonio, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Provided friendly and efficient customer service via phone and chat.	71	1
177	Customer Service Representative	co	Austin, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Handled customer inquiries and resolved issues efficiently.	72	1
178	Customer Service Representative	co	Dallas, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Resolved customer inquiries and technical issues with professionalism.	73	1
179	Customer Service Representative	co	Austin, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Provided exceptional customer service and resolved issues.	74	1
180	Customer Service Representative	co	Austin, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Assisted customers with inquiries and provided solutions.	75	1
181	Customer Service Representative	co	San Antonio, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Provided friendly and efficient customer service via phone and chat.	76	1
182	Customer Service Representative	co	Austin, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Handled customer inquiries and resolved issues efficiently.	77	1
183	Customer Service Representative	co	Dallas, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Resolved customer inquiries and technical issues with professionalism.	78	1
184	Customer Service Representative	co	San Antonio, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Provided friendly and efficient customer service via phone and chat.	79	1
185	Customer Service Representative	co	Austin, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Handled customer inquiries and resolved issues efficiently.	80	1
186	Customer Service Representative	co	Dallas, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Resolved customer inquiries and technical issues with professionalism.	81	1
187	Customer Service Representative	co	Austin, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Provided exceptional customer service and resolved issues.	82	1
188	Customer Service Representative	co	Austin, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Assisted customers with inquiries and provided solutions.	83	1
189	Customer Service Representative	co	San Antonio, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Provided friendly and efficient customer service via phone and chat.	84	1
190	Customer Service Representative	co	Austin, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Handled customer inquiries and resolved issues efficiently.	85	1
191	Customer Service Representative	co	Dallas, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Resolved customer inquiries and technical issues with professionalism.	86	1
192	Customer Service Representative	co	San Antonio, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Provided friendly and efficient customer service via phone and chat.	87	1
193	Customer Service Representative	co	Austin, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Handled customer inquiries and resolved issues efficiently.	88	1
194	Customer Service Representative	co	Dallas, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Resolved customer inquiries and technical issues with professionalism.	89	1
195	Customer Service Representative	co	Austin, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Provided exceptional customer service and resolved issues.	90	1
196	Customer Service Representative	co	Austin, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Assisted customers with inquiries and provided solutions.	91	1
197	Customer Service Representative	co	San Antonio, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Provided friendly and efficient customer service via phone and chat.	92	1
198	Customer Service Representative	co	Austin, TX	2022-01-01 00:00:00	2022-06-30 00:00:00	Handled customer inquiries and resolved issues efficiently.	93	1
200	Data Entry Clerk	co	Austin, TX	2022-07-01 00:00:00	2022-12-31 00:00:00	Entered and maintained data accurately in company databases.	3	1
201	Graphic Designer	co	Austin, TX	2022-07-01 00:00:00	2022-12-31 00:00:00	Created visual content for marketing materials and online platforms.	94	1
202	Web Developer	co	Austin, TX	2022-07-01 00:00:00	2022-12-31 00:00:00	Designed and developed responsive websites and web applications.	5	1
203	Accounting Assistant	co	Dallas, TX	2022-07-01 00:00:00	2022-12-31 00:00:00	Assisted with accounts payable and receivable tasks and reconciled accounts.	6	1
204	Social Media Specialist	co	Austin, TX	2022-07-01 00:00:00	2022-12-31 00:00:00	Managed social media accounts and implemented social media marketing strategies.	7	1
205	Marketing Coordinator	co	Austin, TX	2022-07-01 00:00:00	2023-01-31 00:00:00	Assisted in developing marketing strategies and campaigns.	8	1
206	IT Support Specialist	co	Dallas, TX	2022-07-01 00:00:00	2023-01-31 00:00:00	Provided technical support and troubleshooting for IT issues.	9	1
207	Graphic Designer	co	Austin, TX	2022-07-01 00:00:00	2023-01-31 00:00:00	Designed visual content for online platforms and marketing materials.	10	1
208	Data Entry Clerk	co	Dallas, TX	2022-07-01 00:00:00	2023-01-31 00:00:00	Entered and maintained data accurately in company databases.	11	1
209	Technical Support Specialist	co	Austin, TX	2022-07-01 00:00:00	2023-01-31 00:00:00	Provided technical support and troubleshooting for software and hardware.	12	1
210	Marketing Coordinator	co	Dallas, TX	2022-07-01 00:00:00	2023-01-31 00:00:00	Assisted in developing marketing strategies and campaigns.	13	1
211	IT Support Specialist	co	Dallas, TX	2022-07-01 00:00:00	2023-01-31 00:00:00	Provided technical support and troubleshooting for IT issues.	14	1
212	Graphic Designer	co	Austin, TX	2022-07-01 00:00:00	2023-01-31 00:00:00	Designed visual content for online platforms and marketing materials.	15	1
213	Data Entry Clerk	co	Dallas, TX	2022-07-01 00:00:00	2023-01-31 00:00:00	Entered and maintained data accurately in company databases.	16	1
214	Technical Support Specialist	co	Austin, TX	2022-07-01 00:00:00	2023-01-31 00:00:00	Provided technical support and troubleshooting for software and hardware.	17	1
215	Marketing Coordinator	co	Dallas, TX	2022-07-01 00:00:00	2023-01-31 00:00:00	Assisted in developing marketing strategies and campaigns.	18	1
216	IT Support Specialist	co	Dallas, TX	2022-07-01 00:00:00	2023-01-31 00:00:00	Provided technical support and troubleshooting for IT issues.	19	1
217	Graphic Designer	co	Austin, TX	2022-07-01 00:00:00	2023-01-31 00:00:00	Designed visual content for online platforms and marketing materials.	20	1
218	Data Entry Clerk	co	Dallas, TX	2022-07-01 00:00:00	2023-01-31 00:00:00	Entered and maintained data accurately in company databases.	21	1
219	Technical Support Specialist	co	Austin, TX	2022-07-01 00:00:00	2023-01-31 00:00:00	Provided technical support and troubleshooting for software and hardware.	22	1
220	Marketing Coordinator	co	Dallas, TX	2022-07-01 00:00:00	2023-01-31 00:00:00	Assisted in developing marketing strategies and campaigns.	23	1
221	IT Support Specialist	co	Dallas, TX	2022-07-01 00:00:00	2023-01-31 00:00:00	Provided technical support and troubleshooting for IT issues.	24	1
222	Graphic Designer	co	Austin, TX	2022-07-01 00:00:00	2023-01-31 00:00:00	Designed visual content for online platforms and marketing materials.	25	1
223	Data Entry Clerk	co	Dallas, TX	2022-07-01 00:00:00	2023-01-31 00:00:00	Entered and maintained data accurately in company databases.	26	1
224	Technical Support Specialist	co	Austin, TX	2022-07-01 00:00:00	2023-01-31 00:00:00	Provided technical support and troubleshooting for software and hardware.	27	1
225	Marketing Coordinator	co	Dallas, TX	2022-07-01 00:00:00	2023-01-31 00:00:00	Assisted in developing marketing strategies and campaigns.	28	1
226	IT Support Specialist	co	Dallas, TX	2022-07-01 00:00:00	2023-01-31 00:00:00	Provided technical support and troubleshooting for IT issues.	29	1
227	Graphic Designer	co	Austin, TX	2022-07-01 00:00:00	2023-01-31 00:00:00	Designed visual content for online platforms and marketing materials.	30	1
228	Data Entry Clerk	co	Dallas, TX	2022-07-01 00:00:00	2023-01-31 00:00:00	Entered and maintained data accurately in company databases.	31	1
229	Technical Support Specialist	co	Austin, TX	2022-07-01 00:00:00	2023-01-31 00:00:00	Provided technical support and troubleshooting for software and hardware.	32	1
230	Marketing Coordinator	co	Dallas, TX	2022-07-01 00:00:00	2023-01-31 00:00:00	Assisted in developing marketing strategies and campaigns.	33	1
231	IT Support Specialist	co	Dallas, TX	2022-07-01 00:00:00	2023-01-31 00:00:00	Provided technical support and troubleshooting for IT issues.	34	1
232	Graphic Designer	co	Austin, TX	2022-07-01 00:00:00	2023-01-31 00:00:00	Designed visual content for online platforms and marketing materials.	35	1
233	Data Entry Clerk	co	Dallas, TX	2022-07-01 00:00:00	2023-01-31 00:00:00	Entered and maintained data accurately in company databases.	36	1
234	Technical Support Specialist	co	Austin, TX	2022-07-01 00:00:00	2023-01-31 00:00:00	Provided technical support and troubleshooting for software and hardware.	37	1
235	Marketing Coordinator	co	Dallas, TX	2022-07-01 00:00:00	2023-01-31 00:00:00	Assisted in developing marketing strategies and campaigns.	38	1
236	IT Support Specialist	co	Dallas, TX	2022-07-01 00:00:00	2023-01-31 00:00:00	Provided technical support and troubleshooting for IT issues.	39	1
237	Graphic Designer	co	Austin, TX	2022-07-01 00:00:00	2023-01-31 00:00:00	Designed visual content for online platforms and marketing materials.	40	1
238	Data Entry Clerk	co	Dallas, TX	2022-07-01 00:00:00	2023-01-31 00:00:00	Entered and maintained data accurately in company databases.	41	1
239	Technical Support Specialist	co	Austin, TX	2022-07-01 00:00:00	2023-01-31 00:00:00	Provided technical support and troubleshooting for software and hardware.	42	1
240	Marketing Coordinator	co	Dallas, TX	2022-07-01 00:00:00	2023-01-31 00:00:00	Assisted in developing marketing strategies and campaigns.	43	1
241	Marketing Coordinator	co	Dallas, TX	2022-07-01 00:00:00	2023-01-31 00:00:00	Assisted in developing marketing strategies and campaigns.	44	1
242	IT Support Specialist	co	Austin, TX	2022-07-01 00:00:00	2023-01-31 00:00:00	Provided technical support and troubleshooting for IT issues.	45	1
243	Graphic Designer	co	Austin, TX	2022-07-01 00:00:00	2023-01-31 00:00:00	Designed visual content for online platforms and marketing materials.	46	1
244	Data Entry Clerk	co	Dallas, TX	2022-07-01 00:00:00	2023-01-31 00:00:00	Entered and maintained data accurately in company databases.	47	1
245	Technical Support Specialist	co	Austin, TX	2022-07-01 00:00:00	2023-01-31 00:00:00	Provided technical support and troubleshooting for software and hardware.	48	1
246	Accounting Assistant	co	Dallas, TX	2022-07-01 00:00:00	2023-01-31 00:00:00	Assisted with accounts payable and receivable tasks and reconciled accounts.	49	1
247	Web Developer	co	Austin, TX	2022-07-01 00:00:00	2023-01-31 00:00:00	Designed and developed responsive websites and web applications.	50	1
248	Project Coordinator	co	Austin, TX	2022-07-01 00:00:00	2023-01-31 00:00:00	Coordinated project tasks and timelines.	51	1
249	IT Support Specialist	co	Austin, TX	2022-07-01 00:00:00	2023-01-31 00:00:00	Provided technical support and troubleshooting for IT issues.	52	1
250	Graphic Designer	co	Austin, TX	2022-07-01 00:00:00	2023-01-31 00:00:00	Designed visual content for online platforms and marketing materials.	53	1
251	Technical Support Specialist	co	Austin, TX	2022-07-01 00:00:00	2023-01-31 00:00:00	Provided technical support and troubleshooting for software and hardware.	54	1
252	Marketing Coordinator	co	Dallas, TX	2022-07-01 00:00:00	2023-01-31 00:00:00	Assisted in developing marketing strategies and campaigns.	55	1
253	IT Support Specialist	co	Dallas, TX	2022-07-01 00:00:00	2023-01-31 00:00:00	Provided technical support and troubleshooting for IT issues.	56	1
254	Graphic Designer	co	Austin, TX	2022-07-01 00:00:00	2023-01-31 00:00:00	Designed visual content for online platforms and marketing materials.	57	1
255	Data Entry Clerk	co	Dallas, TX	2022-07-01 00:00:00	2023-01-31 00:00:00	Entered and maintained data accurately in company databases.	58	1
256	Technical Support Specialist	co	Austin, TX	2022-07-01 00:00:00	2023-01-31 00:00:00	Provided technical support and troubleshooting for software and hardware.	59	1
257	Marketing Coordinator	co	Dallas, TX	2022-07-01 00:00:00	2023-01-31 00:00:00	Assisted in developing marketing strategies and campaigns.	60	1
258	IT Support Specialist	co	Dallas, TX	2022-07-01 00:00:00	2023-01-31 00:00:00	Provided technical support and troubleshooting for IT issues.	61	1
259	Graphic Designer	co	Austin, TX	2022-07-01 00:00:00	2023-01-31 00:00:00	Designed visual content for online platforms and marketing materials.	62	1
260	Data Entry Clerk	co	Dallas, TX	2022-07-01 00:00:00	2023-01-31 00:00:00	Entered and maintained data accurately in company databases.	63	1
261	Technical Support Specialist	co	Austin, TX	2022-07-01 00:00:00	2023-01-31 00:00:00	Provided technical support and troubleshooting for software and hardware.	64	1
262	Marketing Coordinator	co	Dallas, TX	2022-07-01 00:00:00	2023-01-31 00:00:00	Assisted in developing marketing strategies and campaigns.	65	1
263	IT Support Specialist	co	Dallas, TX	2022-07-01 00:00:00	2023-01-31 00:00:00	Provided technical support and troubleshooting for IT issues.	66	1
264	Graphic Designer	co	Austin, TX	2022-07-01 00:00:00	2023-01-31 00:00:00	Designed visual content for online platforms and marketing materials.	67	1
265	Data Entry Clerk	co	Dallas, TX	2022-07-01 00:00:00	2023-01-31 00:00:00	Entered and maintained data accurately in company databases.	68	1
266	Technical Support Specialist	co	Austin, TX	2022-07-01 00:00:00	2023-01-31 00:00:00	Provided technical support and troubleshooting for software and hardware.	69	1
267	IT Support Specialist	co	Dallas, TX	2022-07-01 00:00:00	2023-01-31 00:00:00	Provided technical support and troubleshooting for IT issues.	70	1
268	Graphic Designer	co	Austin, TX	2022-07-01 00:00:00	2023-01-31 00:00:00	Designed visual content for online platforms and marketing materials.	71	1
269	Data Entry Clerk	co	Dallas, TX	2022-07-01 00:00:00	2023-01-31 00:00:00	Entered and maintained data accurately in company databases.	72	1
270	Technical Support Specialist	co	Austin, TX	2022-07-01 00:00:00	2023-01-31 00:00:00	Provided technical support and troubleshooting for software and hardware.	73	1
271	Marketing Coordinator	co	Dallas, TX	2022-07-01 00:00:00	2023-01-31 00:00:00	Assisted in developing marketing strategies and campaigns.	74	1
272	IT Support Specialist	co	Dallas, TX	2022-07-01 00:00:00	2023-01-31 00:00:00	Provided technical support and troubleshooting for IT issues.	75	1
273	Graphic Designer	co	Austin, TX	2022-07-01 00:00:00	2023-01-31 00:00:00	Designed visual content for online platforms and marketing materials.	76	1
274	Data Entry Clerk	co	Dallas, TX	2022-07-01 00:00:00	2023-01-31 00:00:00	Entered and maintained data accurately in company databases.	77	1
275	Technical Support Specialist	co	Austin, TX	2022-07-01 00:00:00	2023-01-31 00:00:00	Provided technical support and troubleshooting for software and hardware.	78	1
276	Graphic Designer	co	Austin, TX	2022-07-01 00:00:00	2023-01-31 00:00:00	Designed visual content for online platforms and marketing materials.	79	1
277	Data Entry Clerk	co	Dallas, TX	2022-07-01 00:00:00	2023-01-31 00:00:00	Entered and maintained data accurately in company databases.	80	1
278	Technical Support Specialist	co	Austin, TX	2022-07-01 00:00:00	2023-01-31 00:00:00	Provided technical support and troubleshooting for software and hardware.	81	1
279	Marketing Coordinator	co	Dallas, TX	2022-07-01 00:00:00	2023-01-31 00:00:00	Assisted in developing marketing strategies and campaigns.	82	1
280	IT Support Specialist	co	Dallas, TX	2022-07-01 00:00:00	2023-01-31 00:00:00	Provided technical support and troubleshooting for IT issues.	83	1
281	Graphic Designer	co	Austin, TX	2022-07-01 00:00:00	2023-01-31 00:00:00	Designed visual content for online platforms and marketing materials.	84	1
282	Data Entry Clerk	co	Dallas, TX	2022-07-01 00:00:00	2023-01-31 00:00:00	Entered and maintained data accurately in company databases.	85	1
283	Technical Support Specialist	co	Austin, TX	2022-07-01 00:00:00	2023-01-31 00:00:00	Provided technical support and troubleshooting for software and hardware.	86	1
284	Graphic Designer	co	Austin, TX	2022-07-01 00:00:00	2023-01-31 00:00:00	Designed visual content for online platforms and marketing materials.	87	1
285	Data Entry Clerk	co	Dallas, TX	2022-07-01 00:00:00	2023-01-31 00:00:00	Entered and maintained data accurately in company databases.	88	1
286	Technical Support Specialist	co	Austin, TX	2022-07-01 00:00:00	2023-01-31 00:00:00	Provided technical support and troubleshooting for software and hardware.	89	1
287	Marketing Coordinator	co	Dallas, TX	2022-07-01 00:00:00	2023-01-31 00:00:00	Assisted in developing marketing strategies and campaigns.	90	1
288	IT Support Specialist	co	Dallas, TX	2022-07-01 00:00:00	2023-01-31 00:00:00	Provided technical support and troubleshooting for IT issues.	91	1
289	Graphic Designer	co	Austin, TX	2022-07-01 00:00:00	2023-01-31 00:00:00	Designed visual content for online platforms and marketing materials.	92	1
290	Data Entry Clerk	co	Dallas, TX	2022-07-01 00:00:00	2023-01-31 00:00:00	Entered and maintained data accurately in company databases.	93	1
292	Administrative Assistant	co	Dallas, TX	2023-01-01 00:00:00	2023-06-30 00:00:00	Provided administrative support to office staff and management.	3	1
293	Event Coordinator	co	Dallas, TX	2023-01-01 00:00:00	2023-06-30 00:00:00	Planned and executed corporate events and meetings.	94	1
294	Digital Marketer	co	Houston, TX	2023-01-01 00:00:00	2023-06-30 00:00:00	Managed digital marketing campaigns and analyzed performance metrics.	5	1
295	HR Assistant	co	Houston, TX	2023-01-01 00:00:00	2023-06-30 00:00:00	Supported HR department in recruitment and onboarding processes.	6	1
296	Data Analyst	co	Dallas, TX	2023-01-01 00:00:00	2023-06-30 00:00:00	Analyzed data to identify trends and make recommendations for improvement.	7	1
297	Project Manager	co	Houston, TX	2023-02-01 00:00:00	2023-08-31 00:00:00	Managed cross-functional projects and coordinated project teams.	8	1
298	Network Administrator	co	Houston, TX	2023-02-01 00:00:00	2023-08-31 00:00:00	Managed company network infrastructure and security.	9	1
299	Web Developer	co	Dallas, TX	2023-02-01 00:00:00	2023-08-31 00:00:00	Developed websites and web applications to meet client needs.	10	1
300	Administrative Assistant	co	Houston, TX	2023-02-01 00:00:00	2023-08-31 00:00:00	Provided administrative support to office staff and management.	11	1
301	Network Security Engineer	co	Houston, TX	2023-02-01 00:00:00	2023-08-31 00:00:00	Implemented and maintained network security measures.	12	1
302	Project Manager	co	Houston, TX	2023-02-01 00:00:00	2023-08-31 00:00:00	Managed cross-functional projects and coordinated project teams.	13	1
303	Network Administrator	co	Houston, TX	2023-02-01 00:00:00	2023-08-31 00:00:00	Managed company network infrastructure and security.	14	1
304	Web Developer	co	Dallas, TX	2023-02-01 00:00:00	2023-08-31 00:00:00	Developed websites and web applications to meet client needs.	15	1
305	Administrative Assistant	co	Houston, TX	2023-02-01 00:00:00	2023-08-31 00:00:00	Provided administrative support to office staff and management.	16	1
306	Network Security Engineer	co	Houston, TX	2023-02-01 00:00:00	2023-08-31 00:00:00	Implemented and maintained network security measures.	17	1
307	Project Manager	co	Houston, TX	2023-02-01 00:00:00	2023-08-31 00:00:00	Managed cross-functional projects and coordinated project teams.	18	1
308	Network Administrator	co	Houston, TX	2023-02-01 00:00:00	2023-08-31 00:00:00	Managed company network infrastructure and security.	19	1
309	Web Developer	co	Dallas, TX	2023-02-01 00:00:00	2023-08-31 00:00:00	Developed websites and web applications to meet client needs.	20	1
310	Administrative Assistant	co	Houston, TX	2023-02-01 00:00:00	2023-08-31 00:00:00	Provided administrative support to office staff and management.	21	1
311	Network Security Engineer	co	Houston, TX	2023-02-01 00:00:00	2023-08-31 00:00:00	Implemented and maintained network security measures.	22	1
312	Project Manager	co	Houston, TX	2023-02-01 00:00:00	2023-08-31 00:00:00	Managed cross-functional projects and coordinated project teams.	23	1
313	Network Administrator	co	Houston, TX	2023-02-01 00:00:00	2023-08-31 00:00:00	Managed company network infrastructure and security.	24	1
314	Web Developer	co	Dallas, TX	2023-02-01 00:00:00	2023-08-31 00:00:00	Developed websites and web applications to meet client needs.	25	1
315	Administrative Assistant	co	Houston, TX	2023-02-01 00:00:00	2023-08-31 00:00:00	Provided administrative support to office staff and management.	26	1
316	Network Security Engineer	co	Houston, TX	2023-02-01 00:00:00	2023-08-31 00:00:00	Implemented and maintained network security measures.	27	1
317	Project Manager	co	Houston, TX	2023-02-01 00:00:00	2023-08-31 00:00:00	Managed cross-functional projects and coordinated project teams.	28	1
318	Network Administrator	co	Houston, TX	2023-02-01 00:00:00	2023-08-31 00:00:00	Managed company network infrastructure and security.	29	1
319	Web Developer	co	Dallas, TX	2023-02-01 00:00:00	2023-08-31 00:00:00	Developed websites and web applications to meet client needs.	30	1
320	Administrative Assistant	co	Houston, TX	2023-02-01 00:00:00	2023-08-31 00:00:00	Provided administrative support to office staff and management.	31	1
321	Network Security Engineer	co	Houston, TX	2023-02-01 00:00:00	2023-08-31 00:00:00	Implemented and maintained network security measures.	32	1
322	Project Manager	co	Houston, TX	2023-02-01 00:00:00	2023-08-31 00:00:00	Managed cross-functional projects and coordinated project teams.	33	1
323	Network Administrator	co	Houston, TX	2023-02-01 00:00:00	2023-08-31 00:00:00	Managed company network infrastructure and security.	34	1
324	Web Developer	co	Dallas, TX	2023-02-01 00:00:00	2023-08-31 00:00:00	Developed websites and web applications to meet client needs.	35	1
325	Administrative Assistant	co	Houston, TX	2023-02-01 00:00:00	2023-08-31 00:00:00	Provided administrative support to office staff and management.	36	1
326	Network Security Engineer	co	Houston, TX	2023-02-01 00:00:00	2023-08-31 00:00:00	Implemented and maintained network security measures.	37	1
327	Project Manager	co	Houston, TX	2023-02-01 00:00:00	2023-08-31 00:00:00	Managed cross-functional projects and coordinated project teams.	38	1
328	Network Administrator	co	Houston, TX	2023-02-01 00:00:00	2023-08-31 00:00:00	Managed company network infrastructure and security.	39	1
329	Web Developer	co	Dallas, TX	2023-02-01 00:00:00	2023-08-31 00:00:00	Developed websites and web applications to meet client needs.	40	1
330	Administrative Assistant	co	Houston, TX	2023-02-01 00:00:00	2023-08-31 00:00:00	Provided administrative support to office staff and management.	41	1
331	Network Security Engineer	co	Houston, TX	2023-02-01 00:00:00	2023-08-31 00:00:00	Implemented and maintained network security measures.	42	1
332	Project Manager	co	Houston, TX	2023-02-01 00:00:00	2023-08-31 00:00:00	Managed cross-functional projects and coordinated project teams.	43	1
333	Project Manager	co	Houston, TX	2023-02-01 00:00:00	2023-08-31 00:00:00	Managed cross-functional projects and coordinated project teams.	44	1
334	Network Administrator	co	Houston, TX	2023-02-01 00:00:00	2023-08-31 00:00:00	Managed company network infrastructure and security.	45	1
335	Web Developer	co	Dallas, TX	2023-02-01 00:00:00	2023-08-31 00:00:00	Developed websites and web applications to meet client needs.	46	1
336	Administrative Assistant	co	Houston, TX	2023-02-01 00:00:00	2023-08-31 00:00:00	Provided administrative support to office staff and management.	47	1
337	Network Security Engineer	co	Houston, TX	2023-02-01 00:00:00	2023-08-31 00:00:00	Implemented and maintained network security measures.	48	1
338	HR Assistant	co	Houston, TX	2023-02-01 00:00:00	2023-08-31 00:00:00	Supported HR department in recruitment and onboarding processes.	49	1
339	Digital Marketer	co	Houston, TX	2023-02-01 00:00:00	2023-08-31 00:00:00	Managed digital marketing campaigns and analyzed performance metrics.	50	1
340	Marketing Analyst	co	Dallas, TX	2023-02-01 00:00:00	2023-08-31 00:00:00	Analyzed marketing data to inform strategic decisions.	51	1
341	Network Administrator	co	Houston, TX	2023-02-01 00:00:00	2023-08-31 00:00:00	Managed company network infrastructure and security.	52	1
342	Web Developer	co	Dallas, TX	2023-02-01 00:00:00	2023-08-31 00:00:00	Developed websites and web applications to meet client needs.	53	1
343	Network Security Engineer	co	Houston, TX	2023-02-01 00:00:00	2023-08-31 00:00:00	Implemented and maintained network security measures.	54	1
344	Project Manager	co	Houston, TX	2023-02-01 00:00:00	2023-08-31 00:00:00	Managed cross-functional projects and coordinated project teams.	55	1
345	Network Administrator	co	Houston, TX	2023-02-01 00:00:00	2023-08-31 00:00:00	Managed company network infrastructure and security.	56	1
346	Web Developer	co	Dallas, TX	2023-02-01 00:00:00	2023-08-31 00:00:00	Developed websites and web applications to meet client needs.	57	1
347	Administrative Assistant	co	Houston, TX	2023-02-01 00:00:00	2023-08-31 00:00:00	Provided administrative support to office staff and management.	58	1
348	Network Security Engineer	co	Houston, TX	2023-02-01 00:00:00	2023-08-31 00:00:00	Implemented and maintained network security measures.	59	1
349	Project Manager	co	Houston, TX	2023-02-01 00:00:00	2023-08-31 00:00:00	Managed cross-functional projects and coordinated project teams.	60	1
350	Network Administrator	co	Houston, TX	2023-02-01 00:00:00	2023-08-31 00:00:00	Managed company network infrastructure and security.	61	1
351	Web Developer	co	Dallas, TX	2023-02-01 00:00:00	2023-08-31 00:00:00	Developed websites and web applications to meet client needs.	62	1
352	Administrative Assistant	co	Houston, TX	2023-02-01 00:00:00	2023-08-31 00:00:00	Provided administrative support to office staff and management.	63	1
353	Network Security Engineer	co	Houston, TX	2023-02-01 00:00:00	2023-08-31 00:00:00	Implemented and maintained network security measures.	64	1
354	Project Manager	co	Houston, TX	2023-02-01 00:00:00	2023-08-31 00:00:00	Managed cross-functional projects and coordinated project teams.	65	1
355	Network Administrator	co	Houston, TX	2023-02-01 00:00:00	2023-08-31 00:00:00	Managed company network infrastructure and security.	66	1
356	Web Developer	co	Dallas, TX	2023-02-01 00:00:00	2023-08-31 00:00:00	Developed websites and web applications to meet client needs.	67	1
357	Administrative Assistant	co	Houston, TX	2023-02-01 00:00:00	2023-08-31 00:00:00	Provided administrative support to office staff and management.	68	1
358	Network Security Engineer	co	Houston, TX	2023-02-01 00:00:00	2023-08-31 00:00:00	Implemented and maintained network security measures.	69	1
359	Network Administrator	co	Houston, TX	2023-02-01 00:00:00	2023-08-31 00:00:00	Managed company network infrastructure and security.	70	1
360	Web Developer	co	Dallas, TX	2023-02-01 00:00:00	2023-08-31 00:00:00	Developed websites and web applications to meet client needs.	71	1
361	Administrative Assistant	co	Houston, TX	2023-02-01 00:00:00	2023-08-31 00:00:00	Provided administrative support to office staff and management.	72	1
362	Network Security Engineer	co	Houston, TX	2023-02-01 00:00:00	2023-08-31 00:00:00	Implemented and maintained network security measures.	73	1
363	Project Manager	co	Houston, TX	2023-02-01 00:00:00	2023-08-31 00:00:00	Managed cross-functional projects and coordinated project teams.	74	1
364	Network Administrator	co	Houston, TX	2023-02-01 00:00:00	2023-08-31 00:00:00	Managed company network infrastructure and security.	75	1
365	Web Developer	co	Dallas, TX	2023-02-01 00:00:00	2023-08-31 00:00:00	Developed websites and web applications to meet client needs.	76	1
366	Administrative Assistant	co	Houston, TX	2023-02-01 00:00:00	2023-08-31 00:00:00	Provided administrative support to office staff and management.	77	1
367	Network Security Engineer	co	Houston, TX	2023-02-01 00:00:00	2023-08-31 00:00:00	Implemented and maintained network security measures.	78	1
368	Web Developer	co	Dallas, TX	2023-02-01 00:00:00	2023-08-31 00:00:00	Developed websites and web applications to meet client needs.	79	1
369	Administrative Assistant	co	Houston, TX	2023-02-01 00:00:00	2023-08-31 00:00:00	Provided administrative support to office staff and management.	80	1
370	Network Security Engineer	co	Houston, TX	2023-02-01 00:00:00	2023-08-31 00:00:00	Implemented and maintained network security measures.	81	1
371	Project Manager	co	Houston, TX	2023-02-01 00:00:00	2023-08-31 00:00:00	Managed cross-functional projects and coordinated project teams.	82	1
372	Network Administrator	co	Houston, TX	2023-02-01 00:00:00	2023-08-31 00:00:00	Managed company network infrastructure and security.	83	1
373	Web Developer	co	Dallas, TX	2023-02-01 00:00:00	2023-08-31 00:00:00	Developed websites and web applications to meet client needs.	84	1
374	Administrative Assistant	co	Houston, TX	2023-02-01 00:00:00	2023-08-31 00:00:00	Provided administrative support to office staff and management.	85	1
375	Network Security Engineer	co	Houston, TX	2023-02-01 00:00:00	2023-08-31 00:00:00	Implemented and maintained network security measures.	86	1
376	Web Developer	co	Dallas, TX	2023-02-01 00:00:00	2023-08-31 00:00:00	Developed websites and web applications to meet client needs.	87	1
377	Administrative Assistant	co	Houston, TX	2023-02-01 00:00:00	2023-08-31 00:00:00	Provided administrative support to office staff and management.	88	1
378	Network Security Engineer	co	Houston, TX	2023-02-01 00:00:00	2023-08-31 00:00:00	Implemented and maintained network security measures.	89	1
379	Project Manager	co	Houston, TX	2023-02-01 00:00:00	2023-08-31 00:00:00	Managed cross-functional projects and coordinated project teams.	90	1
380	Network Administrator	co	Houston, TX	2023-02-01 00:00:00	2023-08-31 00:00:00	Managed company network infrastructure and security.	91	1
381	Web Developer	co	Dallas, TX	2023-02-01 00:00:00	2023-08-31 00:00:00	Developed websites and web applications to meet client needs.	92	1
382	Administrative Assistant	co	Houston, TX	2023-02-01 00:00:00	2023-08-31 00:00:00	Provided administrative support to office staff and management.	93	1
384	Bookkeeper	co	San Antonio, TX	2023-07-01 00:00:00	2023-12-31 00:00:00	Managed financial records and reconciled accounts.	3	1
385	Public Speaker	co	Houston, TX	2023-07-01 00:00:00	2023-12-31 00:00:00	Delivered presentations on various topics to audiences.	94	1
386	Content Writer	co	San Antonio, TX	2023-07-01 00:00:00	2023-12-31 00:00:00	Produced engaging content for websites, blogs, and social media.	5	1
387	Team Leader	co	San Antonio, TX	2023-07-01 00:00:00	2023-12-31 00:00:00	Led a team of customer service representatives and monitored performance.	6	1
388	Project Coordinator	co	San Antonio, TX	2023-07-01 00:00:00	2023-12-31 00:00:00	Assisted in project planning and execution.	7	1
389	Marketing Manager	co	San Antonio, TX	2023-09-01 00:00:00	2024-03-31 00:00:00	Led marketing initiatives and developed marketing plans.	8	1
390	Database Administrator	co	San Antonio, TX	2023-09-01 00:00:00	2024-03-31 00:00:00	Administered and maintained company databases.	9	1
391	Digital Marketer	co	Houston, TX	2023-09-01 00:00:00	2024-03-31 00:00:00	Executed digital marketing campaigns to drive brand awareness.	10	1
392	Bookkeeper	co	San Antonio, TX	2023-09-01 00:00:00	2024-03-31 00:00:00	Managed financial records and reconciled accounts.	11	1
393	Cloud Solutions Architect	co	San Antonio, TX	2023-09-01 00:00:00	2024-03-31 00:00:00	Designed and implemented cloud-based solutions for clients.	12	1
394	Marketing Manager	co	San Antonio, TX	2023-09-01 00:00:00	2024-03-31 00:00:00	Led marketing initiatives and developed marketing plans.	13	1
395	Database Administrator	co	San Antonio, TX	2023-09-01 00:00:00	2024-03-31 00:00:00	Administered and maintained company databases.	14	1
396	Digital Marketer	co	Houston, TX	2023-09-01 00:00:00	2024-03-31 00:00:00	Executed digital marketing campaigns to drive brand awareness.	15	1
397	Bookkeeper	co	San Antonio, TX	2023-09-01 00:00:00	2024-03-31 00:00:00	Managed financial records and reconciled accounts.	16	1
398	Cloud Solutions Architect	co	San Antonio, TX	2023-09-01 00:00:00	2024-03-31 00:00:00	Designed and implemented cloud-based solutions for clients.	17	1
399	Marketing Manager	co	San Antonio, TX	2023-09-01 00:00:00	2024-03-31 00:00:00	Led marketing initiatives and developed marketing plans.	18	1
400	Database Administrator	co	San Antonio, TX	2023-09-01 00:00:00	2024-03-31 00:00:00	Administered and maintained company databases.	19	1
401	Digital Marketer	co	Houston, TX	2023-09-01 00:00:00	2024-03-31 00:00:00	Executed digital marketing campaigns to drive brand awareness.	20	1
402	Bookkeeper	co	San Antonio, TX	2023-09-01 00:00:00	2024-03-31 00:00:00	Managed financial records and reconciled accounts.	21	1
403	Cloud Solutions Architect	co	San Antonio, TX	2023-09-01 00:00:00	2024-03-31 00:00:00	Designed and implemented cloud-based solutions for clients.	22	1
404	Marketing Manager	co	San Antonio, TX	2023-09-01 00:00:00	2024-03-31 00:00:00	Led marketing initiatives and developed marketing plans.	23	1
405	Database Administrator	co	San Antonio, TX	2023-09-01 00:00:00	2024-03-31 00:00:00	Administered and maintained company databases.	24	1
406	Digital Marketer	co	Houston, TX	2023-09-01 00:00:00	2024-03-31 00:00:00	Executed digital marketing campaigns to drive brand awareness.	25	1
407	Bookkeeper	co	San Antonio, TX	2023-09-01 00:00:00	2024-03-31 00:00:00	Managed financial records and reconciled accounts.	26	1
408	Cloud Solutions Architect	co	San Antonio, TX	2023-09-01 00:00:00	2024-03-31 00:00:00	Designed and implemented cloud-based solutions for clients.	27	1
409	Marketing Manager	co	San Antonio, TX	2023-09-01 00:00:00	2024-03-31 00:00:00	Led marketing initiatives and developed marketing plans.	28	1
410	Database Administrator	co	San Antonio, TX	2023-09-01 00:00:00	2024-03-31 00:00:00	Administered and maintained company databases.	29	1
411	Digital Marketer	co	Houston, TX	2023-09-01 00:00:00	2024-03-31 00:00:00	Executed digital marketing campaigns to drive brand awareness.	30	1
412	Bookkeeper	co	San Antonio, TX	2023-09-01 00:00:00	2024-03-31 00:00:00	Managed financial records and reconciled accounts.	31	1
413	Cloud Solutions Architect	co	San Antonio, TX	2023-09-01 00:00:00	2024-03-31 00:00:00	Designed and implemented cloud-based solutions for clients.	32	1
414	Marketing Manager	co	San Antonio, TX	2023-09-01 00:00:00	2024-03-31 00:00:00	Led marketing initiatives and developed marketing plans.	33	1
415	Database Administrator	co	San Antonio, TX	2023-09-01 00:00:00	2024-03-31 00:00:00	Administered and maintained company databases.	34	1
416	Digital Marketer	co	Houston, TX	2023-09-01 00:00:00	2024-03-31 00:00:00	Executed digital marketing campaigns to drive brand awareness.	35	1
417	Bookkeeper	co	San Antonio, TX	2023-09-01 00:00:00	2024-03-31 00:00:00	Managed financial records and reconciled accounts.	36	1
418	Cloud Solutions Architect	co	San Antonio, TX	2023-09-01 00:00:00	2024-03-31 00:00:00	Designed and implemented cloud-based solutions for clients.	37	1
419	Marketing Manager	co	San Antonio, TX	2023-09-01 00:00:00	2024-03-31 00:00:00	Led marketing initiatives and developed marketing plans.	38	1
420	Database Administrator	co	San Antonio, TX	2023-09-01 00:00:00	2024-03-31 00:00:00	Administered and maintained company databases.	39	1
421	Digital Marketer	co	Houston, TX	2023-09-01 00:00:00	2024-03-31 00:00:00	Executed digital marketing campaigns to drive brand awareness.	40	1
422	Bookkeeper	co	San Antonio, TX	2023-09-01 00:00:00	2024-03-31 00:00:00	Managed financial records and reconciled accounts.	41	1
423	Cloud Solutions Architect	co	San Antonio, TX	2023-09-01 00:00:00	2024-03-31 00:00:00	Designed and implemented cloud-based solutions for clients.	42	1
424	Marketing Manager	co	San Antonio, TX	2023-09-01 00:00:00	2024-03-31 00:00:00	Led marketing initiatives and developed marketing plans.	43	1
425	Marketing Manager	co	San Antonio, TX	2023-09-01 00:00:00	2024-03-31 00:00:00	Led marketing initiatives and developed marketing plans.	44	1
426	Database Administrator	co	San Antonio, TX	2023-09-01 00:00:00	2024-03-31 00:00:00	Administered and maintained company databases.	45	1
427	Digital Marketer	co	Houston, TX	2023-09-01 00:00:00	2024-03-31 00:00:00	Executed digital marketing campaigns to drive brand awareness.	46	1
428	Bookkeeper	co	San Antonio, TX	2023-09-01 00:00:00	2024-03-31 00:00:00	Managed financial records and reconciled accounts.	47	1
429	Cloud Solutions Architect	co	San Antonio, TX	2023-09-01 00:00:00	2024-03-31 00:00:00	Designed and implemented cloud-based solutions for clients.	48	1
430	Team Leader	co	San Antonio, TX	2023-09-01 00:00:00	2024-03-31 00:00:00	Led a team of customer service representatives and monitored performance.	49	1
431	Content Writer	co	San Antonio, TX	2023-09-01 00:00:00	2024-03-31 00:00:00	Produced engaging content for websites, blogs, and social media.	50	1
432	Marketing Manager	co	San Antonio, TX	2023-09-01 00:00:00	2024-03-31 00:00:00	Led marketing campaigns and managed team.	51	1
433	Database Administrator	co	San Antonio, TX	2023-09-01 00:00:00	2024-03-31 00:00:00	Administered and maintained company databases.	52	1
434	Digital Marketer	co	Houston, TX	2023-09-01 00:00:00	2024-03-31 00:00:00	Executed digital marketing campaigns to drive brand awareness.	53	1
435	Cloud Solutions Architect	co	San Antonio, TX	2023-09-01 00:00:00	2024-03-31 00:00:00	Designed and implemented cloud-based solutions for clients.	54	1
436	Marketing Manager	co	San Antonio, TX	2023-09-01 00:00:00	2024-03-31 00:00:00	Led marketing initiatives and developed marketing plans.	55	1
437	Database Administrator	co	San Antonio, TX	2023-09-01 00:00:00	2024-03-31 00:00:00	Administered and maintained company databases.	56	1
438	Digital Marketer	co	Houston, TX	2023-09-01 00:00:00	2024-03-31 00:00:00	Executed digital marketing campaigns to drive brand awareness.	57	1
439	Bookkeeper	co	San Antonio, TX	2023-09-01 00:00:00	2024-03-31 00:00:00	Managed financial records and reconciled accounts.	58	1
440	Cloud Solutions Architect	co	San Antonio, TX	2023-09-01 00:00:00	2024-03-31 00:00:00	Designed and implemented cloud-based solutions for clients.	59	1
441	Marketing Manager	co	San Antonio, TX	2023-09-01 00:00:00	2024-03-31 00:00:00	Led marketing initiatives and developed marketing plans.	60	1
442	Database Administrator	co	San Antonio, TX	2023-09-01 00:00:00	2024-03-31 00:00:00	Administered and maintained company databases.	61	1
443	Digital Marketer	co	Houston, TX	2023-09-01 00:00:00	2024-03-31 00:00:00	Executed digital marketing campaigns to drive brand awareness.	62	1
444	Bookkeeper	co	San Antonio, TX	2023-09-01 00:00:00	2024-03-31 00:00:00	Managed financial records and reconciled accounts.	63	1
445	Cloud Solutions Architect	co	San Antonio, TX	2023-09-01 00:00:00	2024-03-31 00:00:00	Designed and implemented cloud-based solutions for clients.	64	1
446	Marketing Manager	co	San Antonio, TX	2023-09-01 00:00:00	2024-03-31 00:00:00	Led marketing initiatives and developed marketing plans.	65	1
447	Database Administrator	co	San Antonio, TX	2023-09-01 00:00:00	2024-03-31 00:00:00	Administered and maintained company databases.	66	1
448	Digital Marketer	co	Houston, TX	2023-09-01 00:00:00	2024-03-31 00:00:00	Executed digital marketing campaigns to drive brand awareness.	67	1
449	Bookkeeper	co	San Antonio, TX	2023-09-01 00:00:00	2024-03-31 00:00:00	Managed financial records and reconciled accounts.	68	1
450	Cloud Solutions Architect	co	San Antonio, TX	2023-09-01 00:00:00	2024-03-31 00:00:00	Designed and implemented cloud-based solutions for clients.	69	1
451	Database Administrator	co	San Antonio, TX	2023-09-01 00:00:00	2024-03-31 00:00:00	Administered and maintained company databases.	70	1
452	Digital Marketer	co	Houston, TX	2023-09-01 00:00:00	2024-03-31 00:00:00	Executed digital marketing campaigns to drive brand awareness.	71	1
453	Bookkeeper	co	San Antonio, TX	2023-09-01 00:00:00	2024-03-31 00:00:00	Managed financial records and reconciled accounts.	72	1
454	Cloud Solutions Architect	co	San Antonio, TX	2023-09-01 00:00:00	2024-03-31 00:00:00	Designed and implemented cloud-based solutions for clients.	73	1
455	Marketing Manager	co	San Antonio, TX	2023-09-01 00:00:00	2024-03-31 00:00:00	Led marketing initiatives and developed marketing plans.	74	1
456	Database Administrator	co	San Antonio, TX	2023-09-01 00:00:00	2024-03-31 00:00:00	Administered and maintained company databases.	75	1
457	Digital Marketer	co	Houston, TX	2023-09-01 00:00:00	2024-03-31 00:00:00	Executed digital marketing campaigns to drive brand awareness.	76	1
458	Bookkeeper	co	San Antonio, TX	2023-09-01 00:00:00	2024-03-31 00:00:00	Managed financial records and reconciled accounts.	77	1
459	Cloud Solutions Architect	co	San Antonio, TX	2023-09-01 00:00:00	2024-03-31 00:00:00	Designed and implemented cloud-based solutions for clients.	78	1
460	Digital Marketer	co	Houston, TX	2023-09-01 00:00:00	2024-03-31 00:00:00	Executed digital marketing campaigns to drive brand awareness.	79	1
461	Bookkeeper	co	San Antonio, TX	2023-09-01 00:00:00	2024-03-31 00:00:00	Managed financial records and reconciled accounts.	80	1
462	Cloud Solutions Architect	co	San Antonio, TX	2023-09-01 00:00:00	2024-03-31 00:00:00	Designed and implemented cloud-based solutions for clients.	81	1
463	Marketing Manager	co	San Antonio, TX	2023-09-01 00:00:00	2024-03-31 00:00:00	Led marketing initiatives and developed marketing plans.	82	1
464	Database Administrator	co	San Antonio, TX	2023-09-01 00:00:00	2024-03-31 00:00:00	Administered and maintained company databases.	83	1
465	Digital Marketer	co	Houston, TX	2023-09-01 00:00:00	2024-03-31 00:00:00	Executed digital marketing campaigns to drive brand awareness.	84	1
466	Bookkeeper	co	San Antonio, TX	2023-09-01 00:00:00	2024-03-31 00:00:00	Managed financial records and reconciled accounts.	85	1
467	Cloud Solutions Architect	co	San Antonio, TX	2023-09-01 00:00:00	2024-03-31 00:00:00	Designed and implemented cloud-based solutions for clients.	86	1
468	Digital Marketer	co	Houston, TX	2023-09-01 00:00:00	2024-03-31 00:00:00	Executed digital marketing campaigns to drive brand awareness.	87	1
469	Bookkeeper	co	San Antonio, TX	2023-09-01 00:00:00	2024-03-31 00:00:00	Managed financial records and reconciled accounts.	88	1
470	Cloud Solutions Architect	co	San Antonio, TX	2023-09-01 00:00:00	2024-03-31 00:00:00	Designed and implemented cloud-based solutions for clients.	89	1
471	Marketing Manager	co	San Antonio, TX	2023-09-01 00:00:00	2024-03-31 00:00:00	Led marketing initiatives and developed marketing plans.	90	1
472	Database Administrator	co	San Antonio, TX	2023-09-01 00:00:00	2024-03-31 00:00:00	Administered and maintained company databases.	91	1
473	Digital Marketer	co	Houston, TX	2023-09-01 00:00:00	2024-03-31 00:00:00	Executed digital marketing campaigns to drive brand awareness.	92	1
474	Bookkeeper	co	San Antonio, TX	2023-09-01 00:00:00	2024-03-31 00:00:00	Managed financial records and reconciled accounts.	93	1
476	Office Manager	co	Plano, TX	2024-01-01 00:00:00	2024-06-30 00:00:00	Oversaw office operations and managed administrative staff.	3	1
477	Marketing Specialist	co	Plano, TX	2024-01-01 00:00:00	2024-06-30 00:00:00	Assisted in developing marketing campaigns and analyzing market trends.	94	1
478	Marketing Manager	co	Plano, TX	2024-01-01 00:00:00	2024-06-30 00:00:00	Managed marketing team and implemented marketing strategies.	5	1
479	Operations Manager	co	Plano, TX	2024-01-01 00:00:00	2024-06-30 00:00:00	Managed day-to-day operations and supervised staff.	6	1
480	Marketing Manager	co	Plano, TX	2024-01-01 00:00:00	2024-06-30 00:00:00	Developed marketing strategies to drive brand awareness and sales.	7	1
481	Director of Marketing	co	Plano, TX	2024-04-01 00:00:00	2024-10-31 00:00:00	Provided strategic direction for marketing department.	8	1
482	IT Manager	co	Plano, TX	2024-04-01 00:00:00	2024-10-31 00:00:00	Managed IT department and implemented IT strategies.	9	1
483	Marketing Manager	co	Plano, TX	2024-04-01 00:00:00	2024-10-31 00:00:00	Managed marketing team and implemented marketing strategies.	10	1
484	Office Manager	co	Plano, TX	2024-04-01 00:00:00	2024-10-31 00:00:00	Oversaw office operations and managed administrative staff.	11	1
485	IT Director	co	Plano, TX	2024-04-01 00:00:00	2024-10-31 00:00:00	Provided leadership and direction for IT department.	12	1
486	Director of Marketing	co	Plano, TX	2024-04-01 00:00:00	2024-10-31 00:00:00	Provided strategic direction for marketing department.	13	1
487	IT Manager	co	Plano, TX	2024-04-01 00:00:00	2024-10-31 00:00:00	Managed IT department and implemented IT strategies.	14	1
488	Marketing Manager	co	Plano, TX	2024-04-01 00:00:00	2024-10-31 00:00:00	Managed marketing team and implemented marketing strategies.	15	1
489	Office Manager	co	Plano, TX	2024-04-01 00:00:00	2024-10-31 00:00:00	Oversaw office operations and managed administrative staff.	16	1
490	IT Director	co	Plano, TX	2024-04-01 00:00:00	2024-10-31 00:00:00	Provided leadership and direction for IT department.	17	1
491	Director of Marketing	co	Plano, TX	2024-04-01 00:00:00	2024-10-31 00:00:00	Provided strategic direction for marketing department.	18	1
492	IT Manager	co	Plano, TX	2024-04-01 00:00:00	2024-10-31 00:00:00	Managed IT department and implemented IT strategies.	19	1
493	Marketing Manager	co	Plano, TX	2024-04-01 00:00:00	2024-10-31 00:00:00	Managed marketing team and implemented marketing strategies.	20	1
494	Office Manager	co	Plano, TX	2024-04-01 00:00:00	2024-10-31 00:00:00	Oversaw office operations and managed administrative staff.	21	1
495	IT Director	co	Plano, TX	2024-04-01 00:00:00	2024-10-31 00:00:00	Provided leadership and direction for IT department.	22	1
496	Director of Marketing	co	Plano, TX	2024-04-01 00:00:00	2024-10-31 00:00:00	Provided strategic direction for marketing department.	23	1
497	IT Manager	co	Plano, TX	2024-04-01 00:00:00	2024-10-31 00:00:00	Managed IT department and implemented IT strategies.	24	1
498	Marketing Manager	co	Plano, TX	2024-04-01 00:00:00	2024-10-31 00:00:00	Managed marketing team and implemented marketing strategies.	25	1
499	Office Manager	co	Plano, TX	2024-04-01 00:00:00	2024-10-31 00:00:00	Oversaw office operations and managed administrative staff.	26	1
500	IT Director	co	Plano, TX	2024-04-01 00:00:00	2024-10-31 00:00:00	Provided leadership and direction for IT department.	27	1
501	Director of Marketing	co	Plano, TX	2024-04-01 00:00:00	2024-10-31 00:00:00	Provided strategic direction for marketing department.	28	1
502	IT Manager	co	Plano, TX	2024-04-01 00:00:00	2024-10-31 00:00:00	Managed IT department and implemented IT strategies.	29	1
503	Marketing Manager	co	Plano, TX	2024-04-01 00:00:00	2024-10-31 00:00:00	Managed marketing team and implemented marketing strategies.	30	1
504	Office Manager	co	Plano, TX	2024-04-01 00:00:00	2024-10-31 00:00:00	Oversaw office operations and managed administrative staff.	31	1
505	IT Director	co	Plano, TX	2024-04-01 00:00:00	2024-10-31 00:00:00	Provided leadership and direction for IT department.	32	1
506	Director of Marketing	co	Plano, TX	2024-04-01 00:00:00	2024-10-31 00:00:00	Provided strategic direction for marketing department.	33	1
507	IT Manager	co	Plano, TX	2024-04-01 00:00:00	2024-10-31 00:00:00	Managed IT department and implemented IT strategies.	34	1
508	Marketing Manager	co	Plano, TX	2024-04-01 00:00:00	2024-10-31 00:00:00	Managed marketing team and implemented marketing strategies.	35	1
509	Office Manager	co	Plano, TX	2024-04-01 00:00:00	2024-10-31 00:00:00	Oversaw office operations and managed administrative staff.	36	1
510	IT Director	co	Plano, TX	2024-04-01 00:00:00	2024-10-31 00:00:00	Provided leadership and direction for IT department.	37	1
511	Director of Marketing	co	Plano, TX	2024-04-01 00:00:00	2024-10-31 00:00:00	Provided strategic direction for marketing department.	38	1
512	IT Manager	co	Plano, TX	2024-04-01 00:00:00	2024-10-31 00:00:00	Managed IT department and implemented IT strategies.	39	1
513	Marketing Manager	co	Plano, TX	2024-04-01 00:00:00	2024-10-31 00:00:00	Managed marketing team and implemented marketing strategies.	40	1
514	Office Manager	co	Plano, TX	2024-04-01 00:00:00	2024-10-31 00:00:00	Oversaw office operations and managed administrative staff.	41	1
515	IT Director	co	Plano, TX	2024-04-01 00:00:00	2024-10-31 00:00:00	Provided leadership and direction for IT department.	42	1
516	Director of Marketing	co	Plano, TX	2024-04-01 00:00:00	2024-10-31 00:00:00	Provided strategic direction for marketing department.	43	1
517	Director of Marketing	co	Plano, TX	2024-04-01 00:00:00	2024-10-31 00:00:00	Provided strategic direction for marketing department.	44	1
518	IT Manager	co	Plano, TX	2024-04-01 00:00:00	2024-10-31 00:00:00	Managed IT department and implemented IT strategies.	45	1
519	Marketing Manager	co	Plano, TX	2024-04-01 00:00:00	2024-10-31 00:00:00	Managed marketing team and implemented marketing strategies.	46	1
520	Office Manager	co	Plano, TX	2024-04-01 00:00:00	2024-10-31 00:00:00	Oversaw office operations and managed administrative staff.	47	1
521	IT Director	co	Plano, TX	2024-04-01 00:00:00	2024-10-31 00:00:00	Provided leadership and direction for IT department.	48	1
522	Operations Manager	co	Plano, TX	2024-04-01 00:00:00	2024-10-31 00:00:00	Managed day-to-day operations and supervised staff.	49	1
523	Marketing Manager	co	Plano, TX	2024-04-01 00:00:00	2024-10-31 00:00:00	Managed marketing team and implemented marketing strategies.	50	1
524	Director of Marketing	co	Plano, TX	2024-04-01 00:00:00	2024-10-31 00:00:00	Developed and executed marketing strategy.	51	1
525	IT Manager	co	Plano, TX	2024-04-01 00:00:00	2024-10-31 00:00:00	Managed IT department and implemented IT strategies.	52	1
526	Marketing Manager	co	Plano, TX	2024-04-01 00:00:00	2024-10-31 00:00:00	Managed marketing team and implemented marketing strategies.	53	1
527	IT Director	co	Plano, TX	2024-04-01 00:00:00	2024-10-31 00:00:00	Provided leadership and direction for IT department.	54	1
528	Director of Marketing	co	Plano, TX	2024-04-01 00:00:00	2024-10-31 00:00:00	Provided strategic direction for marketing department.	55	1
529	IT Manager	co	Plano, TX	2024-04-01 00:00:00	2024-10-31 00:00:00	Managed IT department and implemented IT strategies.	56	1
530	Marketing Manager	co	Plano, TX	2024-04-01 00:00:00	2024-10-31 00:00:00	Managed marketing team and implemented marketing strategies.	57	1
531	Office Manager	co	Plano, TX	2024-04-01 00:00:00	2024-10-31 00:00:00	Oversaw office operations and managed administrative staff.	58	1
532	IT Director	co	Plano, TX	2024-04-01 00:00:00	2024-10-31 00:00:00	Provided leadership and direction for IT department.	59	1
533	Director of Marketing	co	Plano, TX	2024-04-01 00:00:00	2024-10-31 00:00:00	Provided strategic direction for marketing department.	60	1
534	IT Manager	co	Plano, TX	2024-04-01 00:00:00	2024-10-31 00:00:00	Managed IT department and implemented IT strategies.	61	1
535	Marketing Manager	co	Plano, TX	2024-04-01 00:00:00	2024-10-31 00:00:00	Managed marketing team and implemented marketing strategies.	62	1
536	Office Manager	co	Plano, TX	2024-04-01 00:00:00	2024-10-31 00:00:00	Oversaw office operations and managed administrative staff.	63	1
537	IT Director	co	Plano, TX	2024-04-01 00:00:00	2024-10-31 00:00:00	Provided leadership and direction for IT department.	64	1
538	Director of Marketing	co	Plano, TX	2024-04-01 00:00:00	2024-10-31 00:00:00	Provided strategic direction for marketing department.	65	1
539	IT Manager	co	Plano, TX	2024-04-01 00:00:00	2024-10-31 00:00:00	Managed IT department and implemented IT strategies.	66	1
540	Marketing Manager	co	Plano, TX	2024-04-01 00:00:00	2024-10-31 00:00:00	Managed marketing team and implemented marketing strategies.	67	1
541	Office Manager	co	Plano, TX	2024-04-01 00:00:00	2024-10-31 00:00:00	Oversaw office operations and managed administrative staff.	68	1
542	IT Director	co	Plano, TX	2024-04-01 00:00:00	2024-10-31 00:00:00	Provided leadership and direction for IT department.	69	1
543	IT Manager	co	Plano, TX	2024-04-01 00:00:00	2024-10-31 00:00:00	Managed IT department and implemented IT strategies.	70	1
544	Marketing Manager	co	Plano, TX	2024-04-01 00:00:00	2024-10-31 00:00:00	Managed marketing team and implemented marketing strategies.	71	1
545	Office Manager	co	Plano, TX	2024-04-01 00:00:00	2024-10-31 00:00:00	Oversaw office operations and managed administrative staff.	72	1
546	IT Director	co	Plano, TX	2024-04-01 00:00:00	2024-10-31 00:00:00	Provided leadership and direction for IT department.	73	1
547	Director of Marketing	co	Plano, TX	2024-04-01 00:00:00	2024-10-31 00:00:00	Provided strategic direction for marketing department.	74	1
548	IT Manager	co	Plano, TX	2024-04-01 00:00:00	2024-10-31 00:00:00	Managed IT department and implemented IT strategies.	75	1
549	Marketing Manager	co	Plano, TX	2024-04-01 00:00:00	2024-10-31 00:00:00	Managed marketing team and implemented marketing strategies.	76	1
550	Office Manager	co	Plano, TX	2024-04-01 00:00:00	2024-10-31 00:00:00	Oversaw office operations and managed administrative staff.	77	1
551	IT Director	co	Plano, TX	2024-04-01 00:00:00	2024-10-31 00:00:00	Provided leadership and direction for IT department.	78	1
552	Marketing Manager	co	Plano, TX	2024-04-01 00:00:00	2024-10-31 00:00:00	Managed marketing team and implemented marketing strategies.	79	1
553	Office Manager	co	Plano, TX	2024-04-01 00:00:00	2024-10-31 00:00:00	Oversaw office operations and managed administrative staff.	80	1
554	IT Director	co	Plano, TX	2024-04-01 00:00:00	2024-10-31 00:00:00	Provided leadership and direction for IT department.	81	1
555	Director of Marketing	co	Plano, TX	2024-04-01 00:00:00	2024-10-31 00:00:00	Provided strategic direction for marketing department.	82	1
556	IT Manager	co	Plano, TX	2024-04-01 00:00:00	2024-10-31 00:00:00	Managed IT department and implemented IT strategies.	83	1
557	Marketing Manager	co	Plano, TX	2024-04-01 00:00:00	2024-10-31 00:00:00	Managed marketing team and implemented marketing strategies.	84	1
558	Office Manager	co	Plano, TX	2024-04-01 00:00:00	2024-10-31 00:00:00	Oversaw office operations and managed administrative staff.	85	1
559	IT Director	co	Plano, TX	2024-04-01 00:00:00	2024-10-31 00:00:00	Provided leadership and direction for IT department.	86	1
560	Marketing Manager	co	Plano, TX	2024-04-01 00:00:00	2024-10-31 00:00:00	Managed marketing team and implemented marketing strategies.	87	1
561	Office Manager	co	Plano, TX	2024-04-01 00:00:00	2024-10-31 00:00:00	Oversaw office operations and managed administrative staff.	88	1
562	IT Director	co	Plano, TX	2024-04-01 00:00:00	2024-10-31 00:00:00	Provided leadership and direction for IT department.	89	1
563	Director of Marketing	co	Plano, TX	2024-04-01 00:00:00	2024-10-31 00:00:00	Provided strategic direction for marketing department.	90	1
564	IT Manager	co	Plano, TX	2024-04-01 00:00:00	2024-10-31 00:00:00	Managed IT department and implemented IT strategies.	91	1
565	Marketing Manager	co	Plano, TX	2024-04-01 00:00:00	2024-10-31 00:00:00	Managed marketing team and implemented marketing strategies.	92	1
566	Office Manager	co	Plano, TX	2024-04-01 00:00:00	2024-10-31 00:00:00	Oversaw office operations and managed administrative staff.	93	1
\.


--
-- Data for Name: follower; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.follower (id, since, "user1Id", "user2Id") FROM stdin;
1	2024-04-20 10:52:58.353932	2	6
2	2024-04-20 10:52:58.353932	5	31
3	2024-04-20 10:52:58.353932	5	32
4	2024-04-20 10:52:58.353932	5	33
5	2024-04-20 10:52:58.353932	5	34
6	2024-04-20 10:52:58.353932	5	35
7	2024-04-20 10:52:58.353932	5	36
8	2024-04-20 10:52:58.353932	5	37
9	2024-04-20 10:52:58.353932	5	38
10	2024-04-20 10:52:58.353932	5	39
11	2024-04-20 10:52:58.353932	5	40
12	2024-04-20 10:52:58.353932	5	41
13	2024-04-20 10:52:58.353932	5	42
14	2024-04-20 10:52:58.353932	5	43
15	2024-04-20 10:52:58.353932	5	44
16	2024-04-20 10:52:58.353932	5	45
17	2024-04-20 10:52:58.353932	5	46
18	2024-04-20 10:52:58.353932	6	31
19	2024-04-20 10:52:58.353932	6	32
20	2024-04-20 10:52:58.353932	6	33
21	2024-04-20 10:52:58.353932	6	34
22	2024-04-20 10:52:58.353932	6	35
23	2024-04-20 10:52:58.353932	6	36
24	2024-04-20 10:52:58.353932	6	37
25	2024-04-20 10:52:58.353932	6	38
26	2024-04-20 10:52:58.353932	6	39
27	2024-04-20 10:52:58.353932	6	40
28	2024-04-20 10:52:58.353932	6	41
29	2024-04-20 10:52:58.353932	6	42
30	2024-04-20 10:52:58.353932	6	43
31	2024-04-20 10:52:58.353932	6	44
32	2024-04-20 10:52:58.353932	6	45
33	2024-04-20 10:52:58.353932	6	46
34	2024-04-20 10:52:58.353932	7	31
35	2024-04-20 10:52:58.353932	7	32
36	2024-04-20 10:52:58.353932	7	33
37	2024-04-20 10:52:58.353932	7	34
38	2024-04-20 10:52:58.353932	7	35
39	2024-04-20 10:52:58.353932	7	36
40	2024-04-20 10:52:58.353932	7	37
41	2024-04-20 10:52:58.353932	7	38
42	2024-04-20 10:52:58.353932	7	39
43	2024-04-20 10:52:58.353932	7	40
44	2024-04-20 10:52:58.353932	7	41
45	2024-04-20 10:52:58.353932	7	42
46	2024-04-20 10:52:58.353932	7	43
47	2024-04-20 10:52:58.353932	7	44
48	2024-04-20 10:52:58.353932	7	45
49	2024-04-20 10:52:58.353932	7	46
50	2024-04-20 10:52:58.353932	8	31
51	2024-04-20 10:52:58.353932	8	32
52	2024-04-20 10:52:58.353932	8	33
53	2024-04-20 10:52:58.353932	8	34
54	2024-04-20 10:52:58.353932	8	35
55	2024-04-20 10:52:58.353932	8	36
56	2024-04-20 10:52:58.353932	8	37
57	2024-04-20 10:52:58.353932	8	38
58	2024-04-20 10:52:58.353932	8	39
59	2024-04-20 10:52:58.353932	8	40
60	2024-04-20 10:52:58.353932	8	41
61	2024-04-20 10:52:58.353932	8	42
62	2024-04-20 10:52:58.353932	8	43
63	2024-04-20 10:52:58.353932	8	44
64	2024-04-20 10:52:58.353932	8	45
65	2024-04-20 10:52:58.353932	8	46
66	2024-04-20 10:52:58.353932	9	31
67	2024-04-20 10:52:58.353932	9	32
68	2024-04-20 10:52:58.353932	9	33
69	2024-04-20 10:52:58.353932	9	34
70	2024-04-20 10:52:58.353932	9	35
71	2024-04-20 10:52:58.353932	9	36
72	2024-04-20 10:52:58.353932	9	37
73	2024-04-20 10:52:58.353932	9	38
74	2024-04-20 10:52:58.353932	9	39
75	2024-04-20 10:52:58.353932	9	40
76	2024-04-20 10:52:58.353932	9	41
77	2024-04-20 10:52:58.353932	9	42
78	2024-04-20 10:52:58.353932	9	43
79	2024-04-20 10:52:58.353932	9	44
80	2024-04-20 10:52:58.353932	9	45
81	2024-04-20 10:52:58.353932	9	46
82	2024-04-20 10:52:58.353932	10	31
83	2024-04-20 10:52:58.353932	10	32
84	2024-04-20 10:52:58.353932	10	33
85	2024-04-20 10:52:58.353932	10	34
86	2024-04-20 10:52:58.353932	10	35
87	2024-04-20 10:52:58.353932	10	36
88	2024-04-20 10:52:58.353932	10	37
89	2024-04-20 10:52:58.353932	10	38
90	2024-04-20 10:52:58.353932	10	39
91	2024-04-20 10:52:58.353932	10	40
92	2024-04-20 10:52:58.353932	10	41
93	2024-04-20 10:52:58.353932	10	42
94	2024-04-20 10:52:58.353932	10	43
95	2024-04-20 10:52:58.353932	10	44
96	2024-04-20 10:52:58.353932	10	45
97	2024-04-20 10:52:58.353932	10	46
98	2024-04-20 10:52:58.353932	11	31
99	2024-04-20 10:52:58.353932	11	32
100	2024-04-20 10:52:58.353932	11	33
101	2024-04-20 10:52:58.353932	11	34
102	2024-04-20 10:52:58.353932	11	35
103	2024-04-20 10:52:58.353932	11	36
104	2024-04-20 10:52:58.353932	11	37
105	2024-04-20 10:52:58.353932	11	38
106	2024-04-20 10:52:58.353932	11	39
107	2024-04-20 10:52:58.353932	11	40
108	2024-04-20 10:52:58.353932	11	41
109	2024-04-20 10:52:58.353932	11	42
110	2024-04-20 10:52:58.353932	11	43
111	2024-04-20 10:52:58.353932	11	44
112	2024-04-20 10:52:58.353932	11	45
113	2024-04-20 10:52:58.353932	11	46
114	2024-04-20 10:52:58.353932	12	31
115	2024-04-20 10:52:58.353932	12	32
116	2024-04-20 10:52:58.353932	12	33
117	2024-04-20 10:52:58.353932	12	34
118	2024-04-20 10:52:58.353932	12	35
119	2024-04-20 10:52:58.353932	12	36
120	2024-04-20 10:52:58.353932	12	37
121	2024-04-20 10:52:58.353932	12	38
122	2024-04-20 10:52:58.353932	12	39
123	2024-04-20 10:52:58.353932	12	40
124	2024-04-20 10:52:58.353932	12	41
125	2024-04-20 10:52:58.353932	12	42
126	2024-04-20 10:52:58.353932	12	43
127	2024-04-20 10:52:58.353932	12	44
128	2024-04-20 10:52:58.353932	12	45
129	2024-04-20 10:52:58.353932	12	46
130	2024-04-20 10:52:58.353932	13	31
131	2024-04-20 10:52:58.353932	13	32
132	2024-04-20 10:52:58.353932	13	33
133	2024-04-20 10:52:58.353932	13	34
134	2024-04-20 10:52:58.353932	13	35
135	2024-04-20 10:52:58.353932	13	36
136	2024-04-20 10:52:58.353932	13	37
137	2024-04-20 10:52:58.353932	13	38
138	2024-04-20 10:52:58.353932	13	39
139	2024-04-20 10:52:58.353932	13	40
140	2024-04-20 10:52:58.353932	13	41
141	2024-04-20 10:52:58.353932	13	42
142	2024-04-20 10:52:58.353932	13	43
143	2024-04-20 10:52:58.353932	13	44
144	2024-04-20 10:52:58.353932	13	45
145	2024-04-20 10:52:58.353932	13	46
146	2024-04-20 10:52:58.353932	14	31
147	2024-04-20 10:52:58.353932	14	32
148	2024-04-20 10:52:58.353932	14	33
149	2024-04-20 10:52:58.353932	14	34
150	2024-04-20 10:52:58.353932	14	35
151	2024-04-20 10:52:58.353932	14	36
152	2024-04-20 10:52:58.353932	14	37
153	2024-04-20 10:52:58.353932	14	38
154	2024-04-20 10:52:58.353932	14	39
155	2024-04-20 10:52:58.353932	14	40
156	2024-04-20 10:52:58.353932	14	41
157	2024-04-20 10:52:58.353932	14	42
158	2024-04-20 10:52:58.353932	14	43
159	2024-04-20 10:52:58.353932	14	44
160	2024-04-20 10:52:58.353932	14	45
161	2024-04-20 10:52:58.353932	14	46
162	2024-04-20 10:52:58.353932	15	31
163	2024-04-20 10:52:58.353932	15	32
164	2024-04-20 10:52:58.353932	15	33
165	2024-04-20 10:52:58.353932	15	34
166	2024-04-20 10:52:58.353932	15	35
167	2024-04-20 10:52:58.353932	15	36
168	2024-04-20 10:52:58.353932	15	37
169	2024-04-20 10:52:58.353932	15	38
170	2024-04-20 10:52:58.353932	15	39
171	2024-04-20 10:52:58.353932	15	40
172	2024-04-20 10:52:58.353932	15	41
173	2024-04-20 10:52:58.353932	15	42
174	2024-04-20 10:52:58.353932	15	43
175	2024-04-20 10:52:58.353932	15	44
176	2024-04-20 10:52:58.353932	15	45
177	2024-04-20 10:52:58.353932	15	46
178	2024-04-20 10:52:58.353932	16	31
179	2024-04-20 10:52:58.353932	16	32
180	2024-04-20 10:52:58.353932	16	33
181	2024-04-20 10:52:58.353932	16	34
182	2024-04-20 10:52:58.353932	16	35
183	2024-04-20 10:52:58.353932	16	36
184	2024-04-20 10:52:58.353932	16	37
185	2024-04-20 10:52:58.353932	16	38
186	2024-04-20 10:52:58.353932	16	39
187	2024-04-20 10:52:58.353932	16	40
188	2024-04-20 10:52:58.353932	16	41
189	2024-04-20 10:52:58.353932	16	42
190	2024-04-20 10:52:58.353932	16	43
191	2024-04-20 10:52:58.353932	16	44
192	2024-04-20 10:52:58.353932	16	45
193	2024-04-20 10:52:58.353932	16	46
194	2024-04-20 10:52:58.353932	17	31
195	2024-04-20 10:52:58.353932	17	32
196	2024-04-20 10:52:58.353932	17	33
197	2024-04-20 10:52:58.353932	17	34
198	2024-04-20 10:52:58.353932	17	35
199	2024-04-20 10:52:58.353932	17	36
200	2024-04-20 10:52:58.353932	17	37
201	2024-04-20 10:52:58.353932	17	38
202	2024-04-20 10:52:58.353932	17	39
203	2024-04-20 10:52:58.353932	17	40
204	2024-04-20 10:52:58.353932	17	41
205	2024-04-20 10:52:58.353932	17	42
206	2024-04-20 10:52:58.353932	17	43
207	2024-04-20 10:52:58.353932	17	44
208	2024-04-20 10:52:58.353932	17	45
209	2024-04-20 10:52:58.353932	17	46
210	2024-04-20 10:52:58.353932	18	31
211	2024-04-20 10:52:58.353932	18	32
212	2024-04-20 10:52:58.353932	18	33
213	2024-04-20 10:52:58.353932	18	34
214	2024-04-20 10:52:58.353932	18	35
215	2024-04-20 10:52:58.353932	18	36
216	2024-04-20 10:52:58.353932	18	37
217	2024-04-20 10:52:58.353932	18	38
218	2024-04-20 10:52:58.353932	18	39
219	2024-04-20 10:52:58.353932	18	40
220	2024-04-20 10:52:58.353932	18	41
221	2024-04-20 10:52:58.353932	18	42
222	2024-04-20 10:52:58.353932	18	43
223	2024-04-20 10:52:58.353932	18	44
224	2024-04-20 10:52:58.353932	18	45
225	2024-04-20 10:52:58.353932	18	46
226	2024-04-20 10:52:58.353932	19	31
227	2024-04-20 10:52:58.353932	19	32
228	2024-04-20 10:52:58.353932	19	33
229	2024-04-20 10:52:58.353932	19	34
230	2024-04-20 10:52:58.353932	19	35
231	2024-04-20 10:52:58.353932	19	36
232	2024-04-20 10:52:58.353932	19	37
233	2024-04-20 10:52:58.353932	19	38
234	2024-04-20 10:52:58.353932	19	39
235	2024-04-20 10:52:58.353932	19	40
236	2024-04-20 10:52:58.353932	19	41
237	2024-04-20 10:52:58.353932	19	42
238	2024-04-20 10:52:58.353932	19	43
239	2024-04-20 10:52:58.353932	19	44
240	2024-04-20 10:52:58.353932	19	45
241	2024-04-20 10:52:58.353932	19	46
242	2024-04-20 10:52:58.353932	20	31
243	2024-04-20 10:52:58.353932	20	32
244	2024-04-20 10:52:58.353932	20	33
245	2024-04-20 10:52:58.353932	20	34
246	2024-04-20 10:52:58.353932	20	35
247	2024-04-20 10:52:58.353932	20	36
248	2024-04-20 10:52:58.353932	20	37
249	2024-04-20 10:52:58.353932	20	38
250	2024-04-20 10:52:58.353932	20	39
251	2024-04-20 10:52:58.353932	20	40
252	2024-04-20 10:52:58.353932	20	41
253	2024-04-20 10:52:58.353932	20	42
254	2024-04-20 10:52:58.353932	20	43
255	2024-04-20 10:52:58.353932	20	44
256	2024-04-20 10:52:58.353932	20	45
257	2024-04-20 10:52:58.353932	20	46
258	2024-04-20 10:52:58.353932	21	31
259	2024-04-20 10:52:58.353932	21	32
260	2024-04-20 10:52:58.353932	21	33
261	2024-04-20 10:52:58.353932	21	34
262	2024-04-20 10:52:58.353932	21	35
263	2024-04-20 10:52:58.353932	21	36
264	2024-04-20 10:52:58.353932	21	37
265	2024-04-20 10:52:58.353932	21	38
266	2024-04-20 10:52:58.353932	21	39
267	2024-04-20 10:52:58.353932	21	40
268	2024-04-20 10:52:58.353932	21	41
269	2024-04-20 10:52:58.353932	21	42
270	2024-04-20 10:52:58.353932	21	43
271	2024-04-20 10:52:58.353932	21	44
272	2024-04-20 10:52:58.353932	21	45
273	2024-04-20 10:52:58.353932	21	46
274	2024-04-20 10:52:58.353932	22	31
275	2024-04-20 10:52:58.353932	22	32
276	2024-04-20 10:52:58.353932	22	33
277	2024-04-20 10:52:58.353932	22	34
278	2024-04-20 10:52:58.353932	22	35
279	2024-04-20 10:52:58.353932	22	36
280	2024-04-20 10:52:58.353932	22	37
281	2024-04-20 10:52:58.353932	22	38
282	2024-04-20 10:52:58.353932	22	39
283	2024-04-20 10:52:58.353932	22	40
284	2024-04-20 10:52:58.353932	22	41
285	2024-04-20 10:52:58.353932	22	42
286	2024-04-20 10:52:58.353932	22	43
287	2024-04-20 10:52:58.353932	22	44
288	2024-04-20 10:52:58.353932	22	45
289	2024-04-20 10:52:58.353932	22	46
290	2024-04-20 10:52:58.353932	23	31
291	2024-04-20 10:52:58.353932	23	32
292	2024-04-20 10:52:58.353932	23	33
293	2024-04-20 10:52:58.353932	23	34
294	2024-04-20 10:52:58.353932	23	35
295	2024-04-20 10:52:58.353932	23	36
296	2024-04-20 10:52:58.353932	23	37
297	2024-04-20 10:52:58.353932	23	38
298	2024-04-20 10:52:58.353932	23	39
299	2024-04-20 10:52:58.353932	23	40
300	2024-04-20 10:52:58.353932	23	41
301	2024-04-20 10:52:58.353932	23	42
302	2024-04-20 10:52:58.353932	23	43
303	2024-04-20 10:52:58.353932	23	44
304	2024-04-20 10:52:58.353932	23	45
305	2024-04-20 10:52:58.353932	23	46
306	2024-04-20 10:52:58.353932	24	31
307	2024-04-20 10:52:58.353932	24	32
308	2024-04-20 10:52:58.353932	24	33
309	2024-04-20 10:52:58.353932	24	34
310	2024-04-20 10:52:58.353932	24	35
311	2024-04-20 10:52:58.353932	24	36
312	2024-04-20 10:52:58.353932	24	37
313	2024-04-20 10:52:58.353932	24	38
314	2024-04-20 10:52:58.353932	24	39
315	2024-04-20 10:52:58.353932	24	40
316	2024-04-20 10:52:58.353932	24	41
317	2024-04-20 10:52:58.353932	24	42
318	2024-04-20 10:52:58.353932	24	43
319	2024-04-20 10:52:58.353932	24	44
320	2024-04-20 10:52:58.353932	24	45
321	2024-04-20 10:52:58.353932	24	46
322	2024-04-20 10:52:58.353932	25	31
323	2024-04-20 10:52:58.353932	25	32
324	2024-04-20 10:52:58.353932	25	33
325	2024-04-20 10:52:58.353932	25	34
326	2024-04-20 10:52:58.353932	25	35
327	2024-04-20 10:52:58.353932	25	36
328	2024-04-20 10:52:58.353932	25	37
329	2024-04-20 10:52:58.353932	25	38
330	2024-04-20 10:52:58.353932	25	39
331	2024-04-20 10:52:58.353932	25	40
332	2024-04-20 10:52:58.353932	25	41
333	2024-04-20 10:52:58.353932	25	42
334	2024-04-20 10:52:58.353932	25	43
335	2024-04-20 10:52:58.353932	25	44
336	2024-04-20 10:52:58.353932	25	45
337	2024-04-20 10:52:58.353932	25	46
338	2024-04-20 10:52:58.353932	26	31
339	2024-04-20 10:52:58.353932	26	32
340	2024-04-20 10:52:58.353932	26	33
341	2024-04-20 10:52:58.353932	26	34
342	2024-04-20 10:52:58.353932	26	35
343	2024-04-20 10:52:58.353932	26	36
344	2024-04-20 10:52:58.353932	26	37
345	2024-04-20 10:52:58.353932	26	38
346	2024-04-20 10:52:58.353932	26	39
347	2024-04-20 10:52:58.353932	26	40
348	2024-04-20 10:52:58.353932	26	41
349	2024-04-20 10:52:58.353932	26	42
350	2024-04-20 10:52:58.353932	26	43
351	2024-04-20 10:52:58.353932	26	44
352	2024-04-20 10:52:58.353932	26	45
353	2024-04-20 10:52:58.353932	26	46
354	2024-04-20 10:52:58.353932	27	31
355	2024-04-20 10:52:58.353932	27	32
356	2024-04-20 10:52:58.353932	27	33
357	2024-04-20 10:52:58.353932	27	34
358	2024-04-20 10:52:58.353932	27	35
359	2024-04-20 10:52:58.353932	27	36
360	2024-04-20 10:52:58.353932	27	37
361	2024-04-20 10:52:58.353932	27	38
362	2024-04-20 10:52:58.353932	27	39
363	2024-04-20 10:52:58.353932	27	40
364	2024-04-20 10:52:58.353932	27	41
365	2024-04-20 10:52:58.353932	27	42
366	2024-04-20 10:52:58.353932	27	43
367	2024-04-20 10:52:58.353932	27	44
368	2024-04-20 10:52:58.353932	27	45
369	2024-04-20 10:52:58.353932	27	46
370	2024-04-20 10:52:58.353932	28	31
371	2024-04-20 10:52:58.353932	28	32
372	2024-04-20 10:52:58.353932	28	33
373	2024-04-20 10:52:58.353932	28	34
374	2024-04-20 10:52:58.353932	28	35
375	2024-04-20 10:52:58.353932	28	36
376	2024-04-20 10:52:58.353932	28	37
377	2024-04-20 10:52:58.353932	28	38
378	2024-04-20 10:52:58.353932	28	39
379	2024-04-20 10:52:58.353932	28	40
380	2024-04-20 10:52:58.353932	28	41
381	2024-04-20 10:52:58.353932	28	42
382	2024-04-20 10:52:58.353932	28	43
383	2024-04-20 10:52:58.353932	28	44
384	2024-04-20 10:52:58.353932	28	45
385	2024-04-20 10:52:58.353932	28	46
386	2024-04-20 10:52:58.353932	29	31
387	2024-04-20 10:52:58.353932	29	32
388	2024-04-20 10:52:58.353932	29	33
389	2024-04-20 10:52:58.353932	29	34
390	2024-04-20 10:52:58.353932	29	35
391	2024-04-20 10:52:58.353932	29	36
392	2024-04-20 10:52:58.353932	29	37
393	2024-04-20 10:52:58.353932	29	38
394	2024-04-20 10:52:58.353932	29	39
395	2024-04-20 10:52:58.353932	29	40
396	2024-04-20 10:52:58.353932	29	41
397	2024-04-20 10:52:58.353932	29	42
398	2024-04-20 10:52:58.353932	29	43
399	2024-04-20 10:52:58.353932	29	44
400	2024-04-20 10:52:58.353932	29	45
401	2024-04-20 10:52:58.353932	29	46
402	2024-04-20 10:52:58.353932	30	31
403	2024-04-20 10:52:58.353932	30	32
404	2024-04-20 10:52:58.353932	30	33
405	2024-04-20 10:52:58.353932	30	34
406	2024-04-20 10:52:58.353932	30	35
407	2024-04-20 10:52:58.353932	30	36
408	2024-04-20 10:52:58.353932	30	37
409	2024-04-20 10:52:58.353932	30	38
410	2024-04-20 10:52:58.353932	30	39
411	2024-04-20 10:52:58.353932	30	40
412	2024-04-20 10:52:58.353932	30	41
413	2024-04-20 10:52:58.353932	30	42
414	2024-04-20 10:52:58.353932	30	43
415	2024-04-20 10:52:58.353932	30	44
416	2024-04-20 10:52:58.353932	30	45
417	2024-04-20 10:52:58.353932	30	46
\.


--
-- Data for Name: friend_request; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.friend_request (id, "sentAt", "senderId", "receiverId") FROM stdin;
3	2024-04-20 08:42:22.200919	2	49
4	2024-04-20 16:19:03.329466	2	9
5	2024-04-20 16:28:56.763285	2	7
\.


--
-- Data for Name: friendship; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.friendship (id, since, "user1Id", "user2Id") FROM stdin;
1	2024-04-17 17:42:03.432289	3	2
2	2024-04-20 13:55:54.745128	2	6
3	2024-04-21 16:30:23.715559	2	8
\.


--
-- Data for Name: job_alert; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.job_alert (id, created_at, title, location, description, type, "creatorId", "companyId") FROM stdin;
1	2024-04-17 17:27:06.159088	Java Developer	Florida	We need a Java Developr	co	3	1
2	2024-04-18 17:27:06.159088	Web Developer	Florida	Web Developer for front-end and backend API.	co	6	1
3	2024-04-20 13:59:55.883239	Customer Representative	New York	We need a representative for customer service who can manage the meetings and problem solving discussions with customers.	co	6	1
\.


--
-- Data for Name: job_alert_required_skills_skill; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.job_alert_required_skills_skill ("jobAlertId", "skillId") FROM stdin;
1	1
2	1
2	2
3	28
\.


--
-- Data for Name: job_application; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.job_application (id, created_at, "coverLetter", "jobAlertId", "applicantId") FROM stdin;
\.


--
-- Data for Name: message; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.message (id, "sentAt", text, "chatId", "senderId") FROM stdin;
1	2024-04-17 18:29:11.635154	Hi	1	2
2	2024-04-17 18:29:16.779415	Hi	1	3
3	2024-04-17 18:43:24.467145	I would like to discuss the new job opening.	1	2
4	2024-04-17 18:43:55.017222	Sure, just give me few minutes.	1	3
5	2024-04-20 15:01:00.949382	HI Amelia	2	2
6	2024-04-21 16:32:35.54651	Hi Olivia	3	2
7	2024-04-21 17:42:56.851199	I am a Customer Service Representative, It will be helpful if you can share a road map to prepare for Lead roles.	1	2
\.


--
-- Data for Name: notification; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.notification (id, type, "receivedAt", "refererEntity", read, "receiverId", "refererUserId") FROM stdin;
1	ac	2024-04-17 17:42:03.39279	0	t	3	2
2	re	2024-04-17 18:07:40.685078	1	f	1	2
3	re	2024-04-17 18:08:29.630779	2	f	1	3
4	ac	2024-04-20 13:55:54.744203	0	t	2	6
5	re	2024-04-20 23:42:07.367534	419	f	7	2
6	ac	2024-04-21 16:30:23.713821	0	t	2	8
7	cm	2024-04-21 17:59:33.644341	1	f	7	2
8	re	2024-04-21 18:00:03.735024	420	f	5	2
\.


--
-- Data for Name: skill; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.skill (id, name) FROM stdin;
1	Java
2	developer
3	Technical Skills
4	Data Entry Skills
5	Graphic Design Skills
6	Web Development Skills
7	Accounting Skills
8	Social Media Skills
9	Marketing Skills
10	IT Skills
11	Project Management Skills
12	Administrative Skills
13	Event Planning Skills
14	Digital Marketing Skills
15	Human Resources Skills
16	Data Analysis Skills
17	Networking Skills
18	Network Security Skills
19	Marketing Analytics Skills
20	Bookkeeping Skills
21	Public Speaking Skills
22	Content Writing Skills
23	Leadership Skills
24	Database Skills
25	Cloud Computing Skills
26	Communication Skills
27	Problem-solving Skills
28	Representative
\.


--
-- Data for Name: user; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."user" (id, firstname, lastname, email, phone, password, role, "profilePicName") FROM stdin;
2	James	Smith	onu.khatri@gmail.com	08570000751	123456	p	Face (2).jpg
5	Charlotte	SMITH	onu.khatri_1@gmail.com	8570000701	123456	p	Face (5).jpg
1	admin	admin	admin@admin.com	6900000000	123456	a	Face (1).jpg
3	Vasantha	Singh	onu.khatri1@gmail.com	08570000751	123456	p	Face (3).jpg
6	Amelia	JOHNSON	onu.khatri2@gmail.com	8570000702	123456	p	Face (6).jpg
7	Isla	WILLIAMS	onu.khatri3@gmail.com	8570000703	123456	p	Face (7).jpg
8	Olivia	BROWN	onu.khatri4@gmail.com	8570000704	123456	p	Face (8).jpg
9	Harper	JONES	onu.khatri5@gmail.com	8570000705	123456	p	Face (9).jpg
10	Willow	GARCIA	onu.khatri6@gmail.com	8570000706	123456	p	Face (10).jpg
11	Lily	MILLER	onu.khatri7@gmail.com	8570000707	123456	p	Face (11).jpg
12	Ava	DAVIS	onu.khatri8@gmail.com	8570000708	123456	p	Face (12).jpg
13	Ella	RODRIGUEZ	onu.khatri9@gmail.com	8570000709	123456	p	Face (13).jpg
14	Hazel	MARTINEZ	onu.khatri10@gmail.com	8570000710	123456	p	Face (14).jpg
15	Mila	HERNANDEZ	onu.khatri11@gmail.com	8570000711	123456	p	Face (15).jpg
16	Evelyn	LOPEZ	onu.khatri12@gmail.com	8570000712	123456	p	Face (16).jpg
17	Mia	GONZALEZ	onu.khatri13@gmail.com	8570000713	123456	p	Face (17).jpg
18	Sophie	WILSON	onu.khatri14@gmail.com	8570000714	123456	p	Face (18).jpg
19	Isabella	ANDERSON	onu.khatri15@gmail.com	8570000715	123456	p	Face (19).jpg
20	Aria	THOMAS	onu.khatri16@gmail.com	8570000716	123456	p	Face (20).jpg
21	Ruby	TAYLOR	onu.khatri17@gmail.com	8570000717	123456	p	Face (21).jpg
22	Grace	MOORE	onu.khatri18@gmail.com	8570000718	123456	p	Face (22).jpg
23	Millie	JACKSON	onu.khatri19@gmail.com	8570000719	123456	p	Face (23).jpg
24	Florence	MARTIN	onu.khatri20@gmail.com	8570000720	123456	p	Face (24).jpg
25	Lucy	LEE	onu.khatri21@gmail.com	8570000721	123456	p	Face (25).jpg
26	Ivy	PEREZ	onu.khatri22@gmail.com	8570000722	123456	p	Face (26).jpg
27	Chloe	THOMPSON	onu.khatri23@gmail.com	8570000723	123456	p	Face (27).jpg
28	Zoe	WHITE	onu.khatri24@gmail.com	8570000724	123456	p	Face (28).jpg
29	Maeve	HARRIS	onu.khatri25@gmail.com	8570000725	123456	p	Face (29).jpg
30	Daisy	SANCHEZ	onu.khatri26@gmail.com	8570000726	123456	p	Face (30).jpg
31	Matilda	CLARK	onu.khatri27@gmail.com	8570000727	123456	p	Face (31).jpg
32	Sadie	RAMIREZ	onu.khatri28@gmail.com	8570000728	123456	p	Face (32).jpg
33	Sophia	LEWIS	onu.khatri29@gmail.com	8570000729	123456	p	Face (33).jpg
34	Emily	ROBINSON	onu.khatri30@gmail.com	8570000730	123456	p	Face (34).jpg
35	Freya	WALKER	onu.khatri31@gmail.com	8570000731	123456	p	Face (35).jpg
36	Luna	YOUNG	onu.khatri32@gmail.com	8570000732	123456	p	Face (36).jpg
37	Olive	ALLEN	onu.khatri33@gmail.com	8570000733	123456	p	Face (37).jpg
38	Georgia	KING	onu.khatri34@gmail.com	8570000734	123456	p	Face (38).jpg
39	Maia	WRIGHT	onu.khatri35@gmail.com	8570000735	123456	p	Face (39).jpg
40	Poppy	SCOTT	onu.khatri36@gmail.com	8570000736	123456	p	Face (40).jpg
41	Frankie	TORRES	onu.khatri37@gmail.com	8570000737	123456	p	Face (41).jpg
42	Violet	NGUYEN	onu.khatri38@gmail.com	8570000738	123456	p	Face (42).jpg
43	Mackenzie	HILL	onu.khatri39@gmail.com	8570000739	123456	p	Face (43).jpg
44	Ellie	FLORES	onu.khatri40@gmail.com	8570000740	123456	p	Face (44).jpg
45	Riley	GREEN	onu.khatri41@gmail.com	8570000741	123456	p	Face (45).jpg
46	Aurora	ADAMS	onu.khatri42@gmail.com	8570000742	123456	p	Face (46).jpg
47	Bella	NELSON	onu.khatri43@gmail.com	8570000743	123456	p	Face (47).jpg
48	Madison	BAKER	onu.khatri44@gmail.com	8570000744	123456	p	Face (48).jpg
49	Penelope	HALL	onu.khatri45@gmail.com	8570000745	123456	p	Face (49).jpg
50	Kaia	RIVERA	onu.khatri46@gmail.com	8570000746	123456	p	Face (50).jpg
51	Zara	CAMPBELL	onu.khatri47@gmail.com	8570000747	123456	p	Face (51).jpg
52	Billie	MITCHELL	onu.khatri48@gmail.com	8570000748	123456	p	Face (52).jpg
53	Quinn	CARTER	onu.khatri49@gmail.com	8570000749	123456	p	Face (53).jpg
54	Layla	ROBERTS	onu.khatri50@gmail.com	8570000750	123456	p	Face (54).jpg
55	Amaia	GOMEZ	onu.khatri51@gmail.com	8570000751	123456	p	Face (55).jpg
56	Eleanor	PHILLIPS	onu.khatri52@gmail.com	8570000752	123456	p	Face (56).jpg
57	Sienna	EVANS	onu.khatri53@gmail.com	8570000753	123456	p	Face (57).jpg
58	Bonnie	TURNER	onu.khatri54@gmail.com	8570000754	123456	p	Face (58).jpg
59	Isabelle	DIAZ	onu.khatri55@gmail.com	8570000755	123456	p	Face (59).jpg
60	Phoebe	PARKER	onu.khatri56@gmail.com	8570000756	123456	p	Face (60).jpg
61	Abigail	CRUZ	onu.khatri57@gmail.com	8570000757	123456	p	Face (61).jpg
62	Eden	EDWARDS	onu.khatri58@gmail.com	8570000758	123456	p	Face (62).jpg
63	Emilia	COLLINS	onu.khatri59@gmail.com	8570000759	123456	p	Face (63).jpg
64	Eva	REYES	onu.khatri60@gmail.com	8570000760	123456	p	Face (64).jpg
65	Sofia	STEWART	onu.khatri61@gmail.com	8570000761	123456	p	Face (65).jpg
66	Stella	MORRIS	onu.khatri62@gmail.com	8570000762	123456	p	Face (66).jpg
67	Delilah	MORALES	onu.khatri63@gmail.com	8570000763	123456	p	Face (67).jpg
68	Aaliyah	MURPHY	onu.khatri64@gmail.com	8570000764	123456	p	Face (68).jpg
69	Scarlett	COOK	onu.khatri65@gmail.com	8570000765	123456	p	Face (69).jpg
70	Kiara	ROGERS	onu.khatri66@gmail.com	8570000766	123456	p	Face (70).jpg
71	Emma	GUTIERREZ	onu.khatri67@gmail.com	8570000767	123456	p	Face (71).jpg
72	Alice	ORTIZ	onu.khatri68@gmail.com	8570000768	123456	p	Face (72).jpg
73	Molly	MORGAN	onu.khatri69@gmail.com	8570000769	123456	p	Face (73).jpg
74	Thea	COOPER	onu.khatri70@gmail.com	8570000770	123456	p	Face (74).jpg
75	Indie	PETERSON	onu.khatri71@gmail.com	8570000771	123456	p	Face (75).jpg
76	Maya	BAILEY	onu.khatri72@gmail.com	8570000772	123456	p	Face (76).jpg
77	Ayla	REED	onu.khatri73@gmail.com	8570000773	123456	p	Face (77).jpg
78	Elsie	KELLY	onu.khatri74@gmail.com	8570000774	123456	p	Face (78).jpg
79	Evie	HOWARD	onu.khatri75@gmail.com	8570000775	123456	p	Face (79).jpg
80	Margot	RAMOS	onu.khatri76@gmail.com	8570000776	123456	p	Face (80).jpg
81	Hannah	KIM	onu.khatri77@gmail.com	8570000777	123456	p	Face (81).jpg
82	Ada	COX	onu.khatri78@gmail.com	8570000778	123456	p	Face (82).jpg
83	Esther	WARD	onu.khatri79@gmail.com	8570000779	123456	p	Face (83).jpg
84	Harlow	RICHARDSON	onu.khatri80@gmail.com	8570000780	123456	p	Face (84).jpg
85	Maddison	WATSON	onu.khatri81@gmail.com	8570000781	123456	p	Face (85).jpg
86	Cleo	BROOKS	onu.khatri82@gmail.com	8570000782	123456	p	Face (86).jpg
87	Harriet	CHAVEZ	onu.khatri83@gmail.com	8570000783	123456	p	Face (87).jpg
88	Manaia	WOOD	onu.khatri84@gmail.com	8570000784	123456	p	Face (88).jpg
89	Elizabeth	JAMES	onu.khatri85@gmail.com	8570000785	123456	p	Face (89).jpg
90	Iris	BENNETT	onu.khatri86@gmail.com	8570000786	123456	p	Face (90).jpg
91	Summer	GRAY	onu.khatri87@gmail.com	8570000787	123456	p	Face (91).jpg
92	Arabella	MENDOZA	onu.khatri88@gmail.com	8570000788	123456	p	Face (92).jpg
93	Maisie	RUIZ	onu.khatri89@gmail.com	8570000789	123456	p	Face (93).jpg
94	Amber	HUGHES	onu.khatri90@gmail.com	8570000790	123456	p	Face (94).jpg
95	Tilly	PRICE	onu.khatri91@gmail.com	8570000791	123456	p	Face (95).jpg
96	Addison	ALVAREZ	onu.khatri92@gmail.com	8570000792	123456	p	Face (96).jpg
97	Rehmat	CASTILLO	onu.khatri93@gmail.com	8570000793	123456	p	Face (97).jpg
98	Zoey	SANDERS	onu.khatri94@gmail.com	8570000794	123456	p	Face (98).jpg
99	Eliana	PATEL	onu.khatri95@gmail.com	8570000795	123456	p	Face (99).jpg
100	Marley	MYERS	onu.khatri96@gmail.com	8570000796	123456	p	Face (100).jpg
101	Skylar	LONG	onu.khatri97@gmail.com	8570000797	123456	p	Face (101).jpg
102	Faith	COX	onu.khatri98@gmail.com	8570000798	123456	p	Face (102).jpg
103	Clara	WARD	onu.khatri99@gmail.com	8570000799	123456	p	Face (103).jpg
104	Piper	RICHARDSON	onu.khatri100@gmail.com	8570000800	123456	p	Face (104).jpg
\.


--
-- Data for Name: user_contribute_level; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_contribute_level ("userId", "levelId") FROM stdin;
3	1
3	2
3	3
3	4
3	5
29	1
29	2
29	3
29	4
29	5
5	1
5	2
5	3
5	4
5	5
6	1
6	2
6	3
6	4
6	5
7	1
7	2
7	3
7	4
7	5
8	1
8	2
8	3
8	4
8	5
9	1
9	2
9	3
10	1
10	2
10	3
11	1
11	2
11	3
12	1
12	2
12	3
13	1
13	2
13	3
14	1
14	2
14	3
15	1
15	2
15	3
16	1
16	2
16	3
17	1
17	2
18	1
18	2
19	1
19	2
20	1
20	2
21	1
21	2
22	1
22	2
23	1
23	2
24	1
25	1
26	1
27	1
28	1
\.


--
-- Data for Name: user_skills_skill; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_skills_skill ("userId", "skillId") FROM stdin;
2	26
2	9
2	27
3	26
3	4
3	12
3	20
3	27
94	26
94	5
94	13
94	21
94	27
5	26
5	6
5	14
5	22
5	27
6	26
6	7
6	15
6	23
6	27
7	26
7	8
7	16
7	11
7	27
8	26
8	9
8	14
8	11
8	23
8	27
9	26
9	10
9	17
9	24
9	27
10	26
10	5
10	6
10	14
10	27
11	26
11	4
11	12
11	20
11	27
12	26
12	3
12	18
12	25
12	27
13	26
13	9
13	14
13	11
13	23
13	27
14	26
14	10
14	17
14	24
14	27
15	26
15	5
15	6
15	14
15	27
16	26
16	4
16	12
16	20
16	27
17	26
17	3
17	18
17	25
17	27
18	26
18	9
18	14
18	11
18	23
18	27
19	26
19	10
19	17
19	24
19	27
20	26
20	5
20	6
20	14
20	27
21	26
21	4
21	12
21	20
21	27
22	26
22	3
22	18
22	25
22	27
23	26
23	9
23	14
23	11
23	23
23	27
24	26
24	10
24	17
24	24
24	27
25	26
25	5
25	6
25	14
25	27
26	26
26	4
26	12
26	20
26	27
27	26
27	3
27	18
27	25
27	27
28	26
28	9
28	14
28	11
28	23
28	27
29	26
29	10
29	17
29	24
29	27
30	26
30	5
30	6
30	14
30	27
31	26
31	4
31	12
31	20
31	27
32	26
32	3
32	18
32	25
32	27
33	26
33	9
33	14
33	11
33	23
33	27
34	26
34	10
34	17
34	24
34	27
35	26
35	5
35	6
35	14
35	27
36	26
36	4
36	12
36	20
36	27
37	26
37	3
37	18
37	25
37	27
38	26
38	9
38	14
38	11
38	23
38	27
39	26
39	10
39	17
39	24
39	27
40	26
40	5
40	6
40	14
40	27
41	26
41	4
41	12
41	20
41	27
42	26
42	3
42	18
42	25
42	27
43	26
43	9
43	14
43	11
43	23
43	27
44	26
44	9
44	14
44	11
44	23
44	27
45	26
45	10
45	17
45	24
45	27
46	26
46	5
46	6
46	14
46	27
47	26
47	4
47	12
47	20
47	27
48	26
48	3
48	18
48	25
48	27
49	26
49	7
49	15
49	23
49	27
50	26
50	6
50	14
50	22
50	27
51	26
51	11
51	19
51	23
51	27
52	26
52	10
52	17
52	24
52	27
53	26
53	5
53	6
53	14
53	27
54	26
54	3
54	18
54	25
54	27
55	26
55	9
55	14
55	11
55	23
55	27
56	26
56	10
56	17
56	24
56	27
57	26
57	5
57	6
57	14
57	27
58	26
58	4
58	12
58	20
58	27
59	26
59	3
59	18
59	25
59	27
60	26
60	9
60	14
60	11
60	23
60	27
61	26
61	10
61	17
61	24
61	27
62	26
62	5
62	6
62	14
62	27
63	26
63	4
63	12
63	20
63	27
64	26
64	3
64	18
64	25
64	27
65	26
65	9
65	14
65	11
65	23
65	27
66	26
66	10
66	17
66	24
66	27
67	26
67	5
67	6
67	14
67	27
68	26
68	4
68	12
68	20
68	27
69	26
69	3
69	18
69	25
69	27
70	26
70	10
70	17
70	24
70	27
71	26
71	5
71	6
71	14
71	27
72	26
72	4
72	12
72	20
72	27
73	26
73	3
73	18
73	25
73	27
74	26
74	9
74	14
74	11
74	23
74	27
75	26
75	10
75	17
75	24
75	27
76	26
76	5
76	6
76	14
76	27
77	26
77	4
77	12
77	20
77	27
78	26
78	3
78	18
78	25
78	27
79	26
79	5
79	6
79	14
79	27
80	26
80	4
80	12
80	20
80	27
81	26
81	3
81	18
81	25
81	27
82	26
82	9
82	14
82	11
82	23
82	27
83	26
83	10
83	17
83	24
83	27
84	26
84	5
84	6
84	14
84	27
85	26
85	4
85	12
85	20
85	27
86	26
86	3
86	18
86	25
86	27
87	26
87	5
87	6
87	14
87	27
88	26
88	4
88	12
88	20
88	27
89	26
89	3
89	18
89	25
89	27
90	26
90	9
90	14
90	11
90	23
90	27
91	26
91	10
91	17
91	24
91	27
92	26
92	5
92	6
92	14
92	27
93	26
93	4
93	12
93	20
93	27
\.


--
-- Data for Name: visibility_settings; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.visibility_settings (id, "experienceVisible", "educationVisible", "skillsVisible", "userId") FROM stdin;
1	t	t	t	2
2	t	t	t	1
3	t	t	t	7
4	t	t	t	13
5	t	t	t	5
6	t	t	t	6
7	t	t	t	8
8	t	t	t	9
9	t	t	t	10
10	t	t	t	11
11	t	t	t	12
12	t	t	t	14
13	t	t	t	15
14	t	t	t	16
15	t	t	t	17
16	t	t	t	18
17	t	t	t	19
18	t	t	t	20
19	t	t	t	21
20	t	t	t	22
21	t	t	t	23
22	t	t	t	24
23	t	t	t	25
24	t	t	t	26
25	t	t	t	27
26	t	t	t	28
27	t	t	t	29
28	t	t	t	30
29	t	t	t	31
30	t	t	t	32
31	t	t	t	33
32	t	t	t	34
33	t	t	t	35
34	t	t	t	36
35	t	t	t	37
36	t	t	t	38
37	t	t	t	39
38	t	t	t	40
39	t	t	t	41
40	t	t	t	42
41	t	t	t	43
42	t	t	t	44
43	t	t	t	45
44	t	t	t	46
45	t	t	t	47
46	t	t	t	48
47	t	t	t	49
48	t	t	t	50
49	t	t	t	51
50	t	t	t	52
51	t	t	t	53
52	t	t	t	54
53	t	t	t	55
54	t	t	t	56
55	t	t	t	57
56	t	t	t	58
57	t	t	t	59
58	t	t	t	60
59	t	t	t	61
60	t	t	t	62
61	t	t	t	63
62	t	t	t	64
63	t	t	t	65
64	t	t	t	66
65	t	t	t	67
66	t	t	t	68
67	t	t	t	69
68	t	t	t	70
69	t	t	t	71
70	t	t	t	72
71	t	t	t	73
72	t	t	t	74
73	t	t	t	75
74	t	t	t	76
75	t	t	t	77
76	t	t	t	78
77	t	t	t	79
78	t	t	t	80
79	t	t	t	81
80	t	t	t	82
81	t	t	t	83
82	t	t	t	84
83	t	t	t	85
84	t	t	t	86
85	t	t	t	87
86	t	t	t	88
87	t	t	t	89
88	t	t	t	90
89	t	t	t	91
90	t	t	t	92
91	t	t	t	93
92	t	t	t	94
93	t	t	t	3
\.


--
-- Name: article_comment_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.article_comment_id_seq', 1, true);


--
-- Name: article_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.article_id_seq', 28, true);


--
-- Name: article_image_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.article_image_id_seq', 1, false);


--
-- Name: article_reaction_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.article_reaction_id_seq', 420, true);


--
-- Name: article_video_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.article_video_id_seq', 1, false);


--
-- Name: chat_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.chat_id_seq', 3, true);


--
-- Name: company_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.company_id_seq', 10, true);


--
-- Name: contributor_levels_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.contributor_levels_id_seq', 5, true);


--
-- Name: education_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.education_id_seq', 92, true);


--
-- Name: experience_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.experience_id_seq', 566, true);


--
-- Name: follower_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.follower_id_seq', 417, true);


--
-- Name: friend_request_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.friend_request_id_seq', 6, true);


--
-- Name: friendship_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.friendship_id_seq', 3, true);


--
-- Name: job_alert_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.job_alert_id_seq', 3, true);


--
-- Name: job_application_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.job_application_id_seq', 1, false);


--
-- Name: message_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.message_id_seq', 7, true);


--
-- Name: notification_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.notification_id_seq', 8, true);


--
-- Name: skill_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.skill_id_seq', 28, true);


--
-- Name: user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.user_id_seq', 104, true);


--
-- Name: visibility_settings_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.visibility_settings_id_seq', 93, true);


--
-- Name: company PK_056f7854a7afdba7cbd6d45fc20; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.company
    ADD CONSTRAINT "PK_056f7854a7afdba7cbd6d45fc20" PRIMARY KEY (id);


--
-- Name: article_comment PK_35f34db03db8f2c304a3bd1216d; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.article_comment
    ADD CONSTRAINT "PK_35f34db03db8f2c304a3bd1216d" PRIMARY KEY (id);


--
-- Name: job_alert_required_skills_skill PK_3c842f710064f80ebb4dc06e8da; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.job_alert_required_skills_skill
    ADD CONSTRAINT "PK_3c842f710064f80ebb4dc06e8da" PRIMARY KEY ("jobAlertId", "skillId");


--
-- Name: article PK_40808690eb7b915046558c0f81b; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.article
    ADD CONSTRAINT "PK_40808690eb7b915046558c0f81b" PRIMARY KEY (id);


--
-- Name: friend_request PK_4c9d23ff394888750cf66cac17c; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.friend_request
    ADD CONSTRAINT "PK_4c9d23ff394888750cf66cac17c" PRIMARY KEY (id);


--
-- Name: experience PK_5e8d5a534100e1b17ee2efa429a; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.experience
    ADD CONSTRAINT "PK_5e8d5a534100e1b17ee2efa429a" PRIMARY KEY (id);


--
-- Name: notification PK_705b6c7cdf9b2c2ff7ac7872cb7; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notification
    ADD CONSTRAINT "PK_705b6c7cdf9b2c2ff7ac7872cb7" PRIMARY KEY (id);


--
-- Name: user_skills_skill PK_972b9abaae51dbb33e482d81a26; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_skills_skill
    ADD CONSTRAINT "PK_972b9abaae51dbb33e482d81a26" PRIMARY KEY ("userId", "skillId");


--
-- Name: user_contribute_level PK_972b9abaae51dbb33e482d81a47; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_contribute_level
    ADD CONSTRAINT "PK_972b9abaae51dbb33e482d81a47" PRIMARY KEY ("userId", "levelId");


--
-- Name: article_image PK_9907c8dd69b933adbc0e5e9f37e; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.article_image
    ADD CONSTRAINT "PK_9907c8dd69b933adbc0e5e9f37e" PRIMARY KEY (id);


--
-- Name: chat PK_9d0b2ba74336710fd31154738a5; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat
    ADD CONSTRAINT "PK_9d0b2ba74336710fd31154738a5" PRIMARY KEY (id);


--
-- Name: visibility_settings PK_9d2d43efebc65440b2674d3ac39; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.visibility_settings
    ADD CONSTRAINT "PK_9d2d43efebc65440b2674d3ac39" PRIMARY KEY (id);


--
-- Name: skill PK_a0d33334424e64fb78dc3ce7196; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.skill
    ADD CONSTRAINT "PK_a0d33334424e64fb78dc3ce7196" PRIMARY KEY (id);


--
-- Name: article_video PK_a8c454a8ce8e09624fb2ece7337; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.article_video
    ADD CONSTRAINT "PK_a8c454a8ce8e09624fb2ece7337" PRIMARY KEY (id);


--
-- Name: job_alert PK_af0351e285e96d8b1720080a71d; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.job_alert
    ADD CONSTRAINT "PK_af0351e285e96d8b1720080a71d" PRIMARY KEY (id);


--
-- Name: message PK_ba01f0a3e0123651915008bc578; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.message
    ADD CONSTRAINT "PK_ba01f0a3e0123651915008bc578" PRIMARY KEY (id);


--
-- Name: education PK_bf3d38701b3030a8ad634d43bd6; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.education
    ADD CONSTRAINT "PK_bf3d38701b3030a8ad634d43bd6" PRIMARY KEY (id);


--
-- Name: job_application PK_c0b8f6b6341802967369b5d70f5; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.job_application
    ADD CONSTRAINT "PK_c0b8f6b6341802967369b5d70f5" PRIMARY KEY (id);


--
-- Name: chat_users_user PK_c6af481280fb886733ddbd73661; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_users_user
    ADD CONSTRAINT "PK_c6af481280fb886733ddbd73661" PRIMARY KEY ("chatId", "userId");


--
-- Name: user PK_cace4a159ff9f2512dd42373760; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."user"
    ADD CONSTRAINT "PK_cace4a159ff9f2512dd42373760" PRIMARY KEY (id);


--
-- Name: friendship PK_dbd6fb568cd912c5140307075cc; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.friendship
    ADD CONSTRAINT "PK_dbd6fb568cd912c5140307075cc" PRIMARY KEY (id);


--
-- Name: follower PK_dbd6fb568cd912c5140307075ee; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.follower
    ADD CONSTRAINT "PK_dbd6fb568cd912c5140307075ee" PRIMARY KEY (id);


--
-- Name: article_reaction PK_e684d83c590db814e04643d6158; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.article_reaction
    ADD CONSTRAINT "PK_e684d83c590db814e04643d6158" PRIMARY KEY (id);


--
-- Name: visibility_settings REL_da648acd3e9bd96929842f8e2a; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.visibility_settings
    ADD CONSTRAINT "REL_da648acd3e9bd96929842f8e2a" UNIQUE ("userId");


--
-- Name: skill UQ_0f49a593960360f6f85b692aca8; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.skill
    ADD CONSTRAINT "UQ_0f49a593960360f6f85b692aca8" UNIQUE (name);


--
-- Name: company UQ_a76c5cd486f7779bd9c319afd27; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.company
    ADD CONSTRAINT "UQ_a76c5cd486f7779bd9c319afd27" UNIQUE (name);


--
-- Name: user UQ_e12875dfb3b1d92d7d7c5377e22; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."user"
    ADD CONSTRAINT "UQ_e12875dfb3b1d92d7d7c5377e22" UNIQUE (email);


--
-- Name: contributor_levels contributor_levels_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.contributor_levels
    ADD CONSTRAINT contributor_levels_pkey PRIMARY KEY (id);


--
-- Name: IDX_0bd64af568c9611bb3d7418e93; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_0bd64af568c9611bb3d7418e93" ON public.job_alert_required_skills_skill USING btree ("skillId");


--
-- Name: IDX_2004be39e2b3044c392bfe3e61; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_2004be39e2b3044c392bfe3e61" ON public.chat_users_user USING btree ("userId");


--
-- Name: IDX_6a573fa22dfa3574496311588c; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_6a573fa22dfa3574496311588c" ON public.chat_users_user USING btree ("chatId");


--
-- Name: IDX_b5cce6242aae7bce521a76a3be; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_b5cce6242aae7bce521a76a3be" ON public.user_skills_skill USING btree ("userId");


--
-- Name: IDX_b5cce6242aae7bce521a76a3vb; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_b5cce6242aae7bce521a76a3vb" ON public.user_contribute_level USING btree ("userId");


--
-- Name: IDX_c7e4f0b8d58a56f71dd097d754; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_c7e4f0b8d58a56f71dd097d754" ON public.user_skills_skill USING btree ("skillId");


--
-- Name: IDX_c7e4f0b8d58a56f71dd097d794; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_c7e4f0b8d58a56f71dd097d794" ON public.user_contribute_level USING btree ("levelId");


--
-- Name: IDX_e94bcd8c4570e9283d798a13d3; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_e94bcd8c4570e9283d798a13d3" ON public.job_alert_required_skills_skill USING btree ("jobAlertId");


--
-- Name: article_reaction FK_04c402e15adb5faed6a59a522dc; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.article_reaction
    ADD CONSTRAINT "FK_04c402e15adb5faed6a59a522dc" FOREIGN KEY ("reactorId") REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: job_alert_required_skills_skill FK_0bd64af568c9611bb3d7418e931; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.job_alert_required_skills_skill
    ADD CONSTRAINT "FK_0bd64af568c9611bb3d7418e931" FOREIGN KEY ("skillId") REFERENCES public.skill(id);


--
-- Name: job_application FK_0f72681370346063768901281b6; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.job_application
    ADD CONSTRAINT "FK_0f72681370346063768901281b6" FOREIGN KEY ("applicantId") REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: friendship FK_19d92a79d938f4f61a27ca93dfb; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.friendship
    ADD CONSTRAINT "FK_19d92a79d938f4f61a27ca93dfb" FOREIGN KEY ("user1Id") REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: chat_users_user FK_2004be39e2b3044c392bfe3e617; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_users_user
    ADD CONSTRAINT "FK_2004be39e2b3044c392bfe3e617" FOREIGN KEY ("userId") REFERENCES public."user"(id);


--
-- Name: job_application FK_2840c03fbf24fc5211cd6b76245; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.job_application
    ADD CONSTRAINT "FK_2840c03fbf24fc5211cd6b76245" FOREIGN KEY ("jobAlertId") REFERENCES public.job_alert(id) ON DELETE CASCADE;


--
-- Name: article_video FK_29be3d31b65c8c356ca320f1c6f; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.article_video
    ADD CONSTRAINT "FK_29be3d31b65c8c356ca320f1c6f" FOREIGN KEY ("articleId") REFERENCES public.article(id) ON DELETE CASCADE;


--
-- Name: notification FK_3b25772ee2a14aa9748e8f7b8f5; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notification
    ADD CONSTRAINT "FK_3b25772ee2a14aa9748e8f7b8f5" FOREIGN KEY ("refererUserId") REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: article_comment FK_3bf13a01e32dc13f7ecf91aeebb; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.article_comment
    ADD CONSTRAINT "FK_3bf13a01e32dc13f7ecf91aeebb" FOREIGN KEY ("commenterId") REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: friend_request FK_470e723fdad9d6f4981ab2481eb; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.friend_request
    ADD CONSTRAINT "FK_470e723fdad9d6f4981ab2481eb" FOREIGN KEY ("receiverId") REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: article_comment FK_4d5ab30629a42bad659fe1d4da6; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.article_comment
    ADD CONSTRAINT "FK_4d5ab30629a42bad659fe1d4da6" FOREIGN KEY ("articleId") REFERENCES public.article(id) ON DELETE CASCADE;


--
-- Name: article FK_56dfc66267ad7e56902de738b03; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.article
    ADD CONSTRAINT "FK_56dfc66267ad7e56902de738b03" FOREIGN KEY ("publisherId") REFERENCES public."user"(id);


--
-- Name: message FK_619bc7b78eba833d2044153bacc; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.message
    ADD CONSTRAINT "FK_619bc7b78eba833d2044153bacc" FOREIGN KEY ("chatId") REFERENCES public.chat(id) ON DELETE CASCADE;


--
-- Name: job_alert FK_668118573e42861f32b088b75d2; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.job_alert
    ADD CONSTRAINT "FK_668118573e42861f32b088b75d2" FOREIGN KEY ("creatorId") REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: friendship FK_67e0cc82733694bb847a90ce723; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.friendship
    ADD CONSTRAINT "FK_67e0cc82733694bb847a90ce723" FOREIGN KEY ("user2Id") REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: chat_users_user FK_6a573fa22dfa3574496311588c7; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_users_user
    ADD CONSTRAINT "FK_6a573fa22dfa3574496311588c7" FOREIGN KEY ("chatId") REFERENCES public.chat(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: education FK_723e67bde13b73c5404305feb14; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.education
    ADD CONSTRAINT "FK_723e67bde13b73c5404305feb14" FOREIGN KEY ("userId") REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: notification FK_758d70a0e61243171e785989070; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notification
    ADD CONSTRAINT "FK_758d70a0e61243171e785989070" FOREIGN KEY ("receiverId") REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: article_image FK_904b50d2132065cbfa64da4fb18; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.article_image
    ADD CONSTRAINT "FK_904b50d2132065cbfa64da4fb18" FOREIGN KEY ("articleId") REFERENCES public.article(id) ON DELETE CASCADE;


--
-- Name: friend_request FK_9509b72f50f495668bae3c0171c; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.friend_request
    ADD CONSTRAINT "FK_9509b72f50f495668bae3c0171c" FOREIGN KEY ("senderId") REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: article_reaction FK_9dcad0db8c770ee72b1e6303976; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.article_reaction
    ADD CONSTRAINT "FK_9dcad0db8c770ee72b1e6303976" FOREIGN KEY ("articleId") REFERENCES public.article(id) ON DELETE CASCADE;


--
-- Name: follower FK_a443af5d21e7e89d14b21352c02; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.follower
    ADD CONSTRAINT "FK_a443af5d21e7e89d14b21352c02" FOREIGN KEY ("user1Id") REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: experience FK_b14d96aac32c32bb402417ca0a8; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.experience
    ADD CONSTRAINT "FK_b14d96aac32c32bb402417ca0a8" FOREIGN KEY ("companyId") REFERENCES public.company(id);


--
-- Name: user_contribute_level FK_b5cce6242aae7bce521a76a3b74; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_contribute_level
    ADD CONSTRAINT "FK_b5cce6242aae7bce521a76a3b74" FOREIGN KEY ("userId") REFERENCES public."user"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: user_skills_skill FK_b5cce6242aae7bce521a76a3be1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_skills_skill
    ADD CONSTRAINT "FK_b5cce6242aae7bce521a76a3be1" FOREIGN KEY ("userId") REFERENCES public."user"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: message FK_bc096b4e18b1f9508197cd98066; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.message
    ADD CONSTRAINT "FK_bc096b4e18b1f9508197cd98066" FOREIGN KEY ("senderId") REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: follower FK_bfb325d9888b2a369f8f1f9e3ce; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.follower
    ADD CONSTRAINT "FK_bfb325d9888b2a369f8f1f9e3ce" FOREIGN KEY ("user2Id") REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: job_alert FK_c52b326d09bb60fb2bb74cc7446; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.job_alert
    ADD CONSTRAINT "FK_c52b326d09bb60fb2bb74cc7446" FOREIGN KEY ("companyId") REFERENCES public.company(id) ON DELETE CASCADE;


--
-- Name: user_skills_skill FK_c7e4f0b8d58a56f71dd097d7546; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_skills_skill
    ADD CONSTRAINT "FK_c7e4f0b8d58a56f71dd097d7546" FOREIGN KEY ("skillId") REFERENCES public.skill(id);


--
-- Name: user_contribute_level FK_c7e4f0b8d58a56f71dd097d7579; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_contribute_level
    ADD CONSTRAINT "FK_c7e4f0b8d58a56f71dd097d7579" FOREIGN KEY ("levelId") REFERENCES public.contributor_levels(id);


--
-- Name: experience FK_cbfb1d1219454c9b45f1b3c4274; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.experience
    ADD CONSTRAINT "FK_cbfb1d1219454c9b45f1b3c4274" FOREIGN KEY ("userId") REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: visibility_settings FK_da648acd3e9bd96929842f8e2a2; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.visibility_settings
    ADD CONSTRAINT "FK_da648acd3e9bd96929842f8e2a2" FOREIGN KEY ("userId") REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: job_alert_required_skills_skill FK_e94bcd8c4570e9283d798a13d3e; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.job_alert_required_skills_skill
    ADD CONSTRAINT "FK_e94bcd8c4570e9283d798a13d3e" FOREIGN KEY ("jobAlertId") REFERENCES public.job_alert(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

