-- SQLite version of the extension's sql/sanctions.tables.sql, which it applies only on MySQL
CREATE TABLE /*_*/sanctions (
  st_id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  st_author INTEGER UNSIGNED NOT NULL,
  st_topic BLOB NOT NULL,
  st_target INTEGER UNSIGNED NOT NULL,
  st_original_name BLOB DEFAULT '',
  -- TEXT affinity, because the extension compares this column with unquoted integer timestamps
  st_expiry TEXT NOT NULL,
  st_handled SMALLINT DEFAULT 0 NOT NULL,
  st_emergency SMALLINT DEFAULT 0 NOT NULL,
  st_last_update_timestamp BLOB NOT NULL
);

CREATE INDEX sanctions_st_target ON /*_*/sanctions (st_target);

CREATE INDEX sanctions_st_topic_id ON /*_*/sanctions (st_topic, st_id);

CREATE TABLE /*_*/sanctions_vote (
  stv_id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  stv_topic BLOB NOT NULL,
  stv_user INTEGER UNSIGNED NOT NULL,
  stv_period INTEGER UNSIGNED DEFAULT NULL,
  stv_last_update_timestamp BLOB NOT NULL
);

CREATE INDEX sanctions_vote_stv_topic_user ON /*_*/sanctions_vote (stv_topic, stv_user);
