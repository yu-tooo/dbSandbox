CREATE TABLE IF NOT EXISTS non_agg_tbl(
    id varchar(64),
    data_type char(8),
    data_1 integer,
    data_2 integer,
    data_3 integer,
    data_4 integer,
    data_5 integer,
    data_6 integer,
    PRIMARY KEY(id, data_type)
);