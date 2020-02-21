BEGIN;

CREATE SCHEMA apt;
SET search_path TO apt, public;

--CREATE EXTENSION debversion;


CREATE OR REPLACE FUNCTION list2jsonb (list text)
RETURNS jsonb LANGUAGE sql IMMUTABLE AS
$$SELECT jsonb_agg(m) from regexp_split_to_table($1, E'\n ') m$$;

CREATE OR REPLACE FUNCTION control2jsonb (control text)
RETURNS jsonb LANGUAGE sql IMMUTABLE AS
$$SELECT jsonb_object_agg(lower(m[1]),
  CASE WHEN m[1] IN ('Files', 'Checksums-Sha1', 'Checksums-Sha256') THEN
    list2jsonb(m[2])
  ELSE
    to_jsonb(m[2])
  END)
  FROM regexp_matches($1||E'\n', E'^([^ :]*): ((.|\n )*)\n?', 'gm') m$$;


-- ARCHIVE-WIDE DATA

CREATE TABLE architecture (
	architecture text PRIMARY KEY
);
COMMENT ON TABLE architecture IS 'All known architectures, including all, excluding source';


CREATE TABLE srcdistribution (
	distribution text NOT NULL,
	component text NOT NULL,
	last_update timestamp with time zone,
	active boolean NOT NULL DEFAULT TRUE,

	PRIMARY KEY (distribution, component)
);


CREATE TABLE distribution (
	distribution text NOT NULL,
	component text NOT NULL,
	architecture text NOT NULL
		REFERENCES architecture (architecture),
	last_update timestamp with time zone,
	active boolean NOT NULL DEFAULT TRUE,

	PRIMARY KEY (distribution, component, architecture),
	FOREIGN KEY (distribution, component) REFERENCES srcdistribution (distribution, component)
);


-- PACKAGE DATA

CREATE TABLE source (
	source text NOT NULL,
	srcversion debversion NOT NULL,
	control text NOT NULL,
	c jsonb,
	time timestamptz(0) NOT NULL,

	PRIMARY KEY (source, srcversion)
);

CREATE TABLE package (
	package text NOT NULL,
	version debversion NOT NULL,
	arch text NOT NULL
		REFERENCES architecture (architecture),
	control text NOT NULL,
	c jsonb,
	source text NOT NULL,
	srcversion debversion NOT NULL,
	time timestamptz(0) NOT NULL,

	PRIMARY KEY (package, version, arch)
);
--ALTER TABLE package ADD FOREIGN KEY (source, srcversion) REFERENCES source (source, srcversion);


-- SUITE DATA

CREATE TABLE sourcelist (
	distribution text NOT NULL,
	component text NOT NULL,
	source text NOT NULL,
	srcversion debversion NOT NULL,

	FOREIGN KEY (distribution, component) REFERENCES srcdistribution (distribution, component),
	FOREIGN KEY (source, srcversion) REFERENCES source (source, srcversion)
);
CREATE INDEX ON sourcelist (distribution, component);
CREATE INDEX ON sourcelist (source);

CREATE TABLE packagelist (
	distribution text NOT NULL,
	component text NOT NULL,
	architecture text NOT NULL,
	package text NOT NULL,
	version debversion NOT NULL,
	arch text NOT NULL,
	CHECK ((architecture = arch) OR (arch = 'all')),

	FOREIGN KEY (distribution, component, architecture)
		REFERENCES distribution (distribution, component, architecture),
	FOREIGN KEY (package, version, arch) REFERENCES package (package, version, arch)
);
CREATE INDEX ON packagelist (distribution, component, architecture);
CREATE INDEX ON packagelist (package);


-- HISTORY

CREATE TABLE sourcehist (
	distribution text NOT NULL,
	component text NOT NULL,
	source text NOT NULL,
	srcversion debversion NOT NULL,
	time timestamptz(0) NOT NULL,

	FOREIGN KEY (distribution, component) REFERENCES srcdistribution (distribution, component),
	FOREIGN KEY (source, srcversion) REFERENCES source (source, srcversion)
);
CREATE INDEX ON sourcehist (distribution, component);
CREATE INDEX ON sourcehist (source);

CREATE TABLE packagehist (
	distribution text NOT NULL,
	component text NOT NULL,
	architecture text NOT NULL,
	package text NOT NULL,
	version debversion NOT NULL,
	arch text NOT NULL,
	time timestamptz(0) NOT NULL,
	CHECK ((architecture = arch) OR (arch = 'all')),

	FOREIGN KEY (distribution, component, architecture)
		REFERENCES distribution (distribution, component, architecture),
	FOREIGN KEY (package, version, arch) REFERENCES package (package, version, arch)
);
CREATE INDEX ON packagehist (distribution, component, architecture);
CREATE INDEX ON packagehist (package);


-- ACLs

GRANT USAGE ON SCHEMA apt TO PUBLIC;
GRANT SELECT ON ALL TABLES IN SCHEMA apt TO PUBLIC;

COMMIT;
