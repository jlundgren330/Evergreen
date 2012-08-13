BEGIN;

INSERT INTO container.biblio_record_entry_bucket_type (code, label) VALUES ('url_verify', 'URL Verification Queue');

DROP SCHEMA IF EXISTS url_verify CASCADE;

CREATE SCHEMA url_verify;

CREATE TABLE url_verify.session (
    id          SERIAL                      PRIMARY KEY,
    name        TEXT                        NOT NULL,
    owning_lib  INT                         NOT NULL REFERENCES actor.org_unit (id) DEFERRABLE INITIALLY DEFERRED,
    creator     INT                         NOT NULL REFERENCES actor.usr (id) DEFERRABLE INITIALLY DEFERRED,
    container   INT                         NOT NULL REFERENCES container.biblio_record_entry_bucket (id) DEFERRABLE INITIALLY DEFERRED,
    create_time TIMESTAMP WITH TIME ZONE    NOT NULL DEFAULT NOW(),
    search      TEXT                        NOT NULL,
    CONSTRAINT uvs_name_once_per_lib UNIQUE (name, owning_lib)
);

CREATE TABLE url_verify.url_selector (
    id      SERIAL  PRIMARY KEY,
    xpath   TEXT    NOT NULL,
    session INT     NOT NULL REFERENCES url_verify.session (id) DEFERRABLE INITIALLY DEFERRED,
    CONSTRAINT tag_once_per_sess UNIQUE (xpath, session)
);

CREATE TABLE url_verify.url (
    id              SERIAL  PRIMARY KEY,
    redirect_from   INT     REFERENCES url_verify.url(id) DEFERRABLE INITIALLY DEFERRED,
    item            INT     REFERENCES container.biblio_record_entry_bucket_item (id) DEFERRABLE INITIALLY DEFERRED,
    url_selector    INT     REFERENCES url_verify.url_selector (id) DEFERRABLE INITIALLY DEFERRED,
    tag             TEXT,
    subfield        TEXT,
    ord             INT,
    full_url        TEXT    NOT NULL,
    scheme          TEXT,
    username        TEXT,
    password        TEXT,
    host            TEXT,
    domain          TEXT,
    tld             TEXT,
    port            TEXT,
    path            TEXT,
    page            TEXT,
    query           TEXT,
    fragment        TEXT,
    CONSTRAINT redirect_or_from_item CHECK (
        redirect_from IS NOT NULL OR (
            item         IS NOT NULL AND
            url_selector IS NOT NULL AND
            tag          IS NOT NULL AND
            subfield     IS NOT NULL AND
            ord          IS NOT NULL
        )
    )
);

CREATE TABLE url_verify.verification_attempt (
    id          SERIAL                      PRIMARY KEY,
    usr         INT                         NOT NULL REFERENCES actor.usr (id) DEFERRABLE INITIALLY DEFERRED,
    session     INT                         NOT NULL REFERENCES url_verify.session (id) DEFERRABLE INITIALLY DEFERRED,
    start_time  TIMESTAMP WITH TIME ZONE    NOT NULL DEFAULT NOW(),
    finish_time TIMESTAMP WITH TIME ZONE
);
 
CREATE TABLE url_verify.url_verification (
    id          SERIAL                      PRIMARY KEY,
    url         INT                         NOT NULL REFERENCES url_verify.url (id) DEFERRABLE INITIALLY DEFERRED,
    attempt     INT                         NOT NULL REFERENCES url_verify.verification_attempt (id) DEFERRABLE INITIALLY DEFERRED,
    req_time    TIMESTAMP WITH TIME ZONE    NOT NULL DEFAULT NOW(),
    res_time    TIMESTAMP WITH TIME ZONE, 
    res_code    INT                         CHECK (res_code BETWEEN 100 AND 999), -- we know > 599 will never be valid HTTP code, but we use 9XX for other stuff
    res_text    TEXT, 
    redirect_to INT                         REFERENCES url_verify.url (id) DEFERRABLE INITIALLY DEFERRED -- if redirected
);

CREATE TABLE url_verify.filter_set (
    id          SERIAL                      PRIMARY KEY,
    name        TEXT                        NOT NULL,
    owning_lib  INT                         NOT NULL REFERENCES actor.org_unit (id) DEFERRABLE INITIALLY DEFERRED,
    creator     INT                         NOT NULL REFERENCES actor.usr (id) DEFERRABLE INITIALLY DEFERRED,
    create_time TIMESTAMP WITH TIME ZONE    NOT NULL DEFAULT NOW(),
    filter      TEXT                        NOT NULL,
    CONSTRAINT uvfs_name_once_per_lib UNIQUE (name, owning_lib)
);
 
COMMIT;
