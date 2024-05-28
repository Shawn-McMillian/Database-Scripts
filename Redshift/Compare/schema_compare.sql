CREATE OR REPLACE PROCEDURE <Schema>.schema_compare (
    database_name1 IN varchar(128),
    schema_name1 IN varchar(128),
    database_name2 IN varchar(128),
    schema_name2 IN varchar(128))
AS $$
DECLARE
    record_set record;
BEGIN
    SELECT *
    FROM(
        (SELECT NVL2(schema_owner,schema_owner,'') AS schema_owner, NVL2(schema_type,schema_type,'') AS schema_type, NVL2(schema_acl,schema_acl,'') AS schema_acl, NVL2(source_database,source_database,'') AS source_database, NVL2(schema_option,schema_option,'') AS schema_option
         INTO record_set
        FROM svv_all_schemas WHERE database_name = database_name1 AND schema_name = schema_name1

        EXCEPT

        SELECT NVL2(schema_owner,schema_owner,'') AS schema_owner, NVL2(schema_type,schema_type,'') AS schema_type, NVL2(schema_acl,schema_acl,'') AS schema_acl, NVL2(source_database,source_database,'') AS source_database, NVL2(schema_option,schema_option,'') AS schema_option
        FROM svv_all_schemas WHERE database_name = database_name2 AND schema_name = schema_name2)

        UNION ALL

        (SELECT NVL2(schema_owner,schema_owner,'') AS schema_owner, NVL2(schema_type,schema_type,'') AS schema_type, NVL2(schema_acl,schema_acl,'') AS schema_acl, NVL2(source_database,source_database,'') AS source_database, NVL2(schema_option,schema_option,'') AS schema_option
        FROM svv_all_schemas WHERE database_name = database_name2 AND schema_name = schema_name2

        EXCEPT

        SELECT NVL2(schema_owner,schema_owner,'') AS schema_owner, NVL2(schema_type,schema_type,'') AS schema_type, NVL2(schema_acl,schema_acl,'') AS schema_acl, NVL2(source_database,source_database,'') AS source_database, NVL2(schema_option,schema_option,'') AS schema_option
        FROM svv_all_schemas WHERE database_name = database_name1 AND schema_name = schema_name1)
        ORDER BY schema_owner ASC) AS Rec;

    IF NOT FOUND THEN
        RAISE NOTICE 'Schema match';
    ELSE
        RAISE EXCEPTION 'Schema do not match.';
    END IF;
END;
$$ LANGUAGE plpgsql;

--CALL <schema_name>.schema_compare ('<database>','<schema>','<database>','<schema>');