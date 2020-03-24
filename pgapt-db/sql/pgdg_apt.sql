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
COMMENT ON TABLE architecture IS 'known architectures, including "all", excluding source';


CREATE TABLE srcdistribution (
	distribution text NOT NULL,
	component text NOT NULL,
	last_update timestamp with time zone,
	active boolean NOT NULL DEFAULT TRUE,

	PRIMARY KEY (distribution, component)
);
COMMENT ON TABLE srcdistribution IS 'known distributions by Sources files';


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
COMMENT ON TABLE distribution IS 'known distributions by Packages files';


-- PACKAGE DATA

CREATE TABLE src (
	source text PRIMARY KEY,
	upload boolean -- per-package index.html upload status: null = to do, t = done, f = error
);

CREATE TABLE source (
	source text NOT NULL REFERENCES src,
	srcversion debversion NOT NULL,
	control text NOT NULL,
	c jsonb,
	time timestamptz(0) NOT NULL,

	PRIMARY KEY (source, srcversion)
);
COMMENT ON TABLE source IS 'source packages including historic ones';

CREATE TABLE sourcefile (
	source text NOT NULL,
	srcversion debversion NOT NULL,
	directory text NOT NULL,
	filename text NOT NULL,
	upload boolean, -- null = to do, t = done, f = error

	PRIMARY KEY (filename),
	FOREIGN KEY (source, srcversion) REFERENCES source (source, srcversion)
);
COMMENT ON TABLE sourcefile IS 'files belonging to source packages including historic ones';

CREATE INDEX ON sourcefile (source, srcversion);
CREATE INDEX ON sourcefile (upload);


CREATE TABLE package (
	package text NOT NULL,
	version debversion NOT NULL,
	arch text NOT NULL
		REFERENCES architecture (architecture),
	control text NOT NULL,
	c jsonb,
	source text NOT NULL REFERENCES src,
	srcversion debversion NOT NULL,
	time timestamptz(0) NOT NULL,
	upload boolean, -- null = to do, t = done, f = error

	PRIMARY KEY (package, version, arch)
);
--ALTER TABLE package ADD FOREIGN KEY (source, srcversion) REFERENCES source (source, srcversion);
COMMENT ON TABLE package IS 'binary packages including historic ones';

CREATE INDEX ON package (source);
CREATE INDEX ON package (upload);


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
COMMENT ON TABLE sourcelist IS 'current Sources files';

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
COMMENT ON TABLE packagelist IS 'current Packages files';


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
COMMENT ON TABLE sourcehist IS 'current and historic Sources files';

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
COMMENT ON TABLE packagehist IS 'current and historic Packages files';


-- ACLs

GRANT USAGE ON SCHEMA apt TO PUBLIC;
GRANT SELECT ON ALL TABLES IN SCHEMA apt TO PUBLIC;
GRANT INSERT ON ALL TABLES IN SCHEMA apt TO aptuser;
GRANT DELETE ON sourcelist, packagelist TO aptuser;
GRANT UPDATE (last_update) ON srcdistribution, distribution TO aptuser;
GRANT UPDATE (upload) ON sourcefile, package TO aptuser;

COMMIT;
