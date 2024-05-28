CREATE OR REPLACE PROCEDURE <Schema>.table_compare (
    database_name1 IN varchar(128),
    schema_name1 IN varchar(128),
    table_name1 IN varchar(128),
    database_name2 IN varchar(128),
    schema_name2 IN varchar(128),
    table_name2 IN varchar(128))
AS $$
DECLARE
    record_set record;
BEGIN
    SELECT *
    FROM(
        (SELECT NVL2(table_acl,table_acl,'') AS table_acl, NVL2(remarks,remarks,'') AS remarks
        INTO record_set
        FROM svv_all_tables WHERE database_name = database_name1 AND schema_name = schema_name1 AND table_name = table_name1

        EXCEPT

        SELECT NVL2(table_acl,table_acl,'') AS table_acl, NVL2(remarks,remarks,'') AS remarks
        FROM svv_all_tables WHERE database_name = database_name2 AND schema_name = schema_name2 AND table_name = table_name2)

        UNION ALL

        (SELECT NVL2(table_acl,table_acl,'') AS table_acl, NVL2(remarks,remarks,'') AS remarks
        FROM svv_all_tables WHERE database_name = database_name2 AND schema_name = schema_name2 AND table_name = table_name2

        EXCEPT

        SELECT NVL2(table_acl,table_acl,'') AS table_acl, NVL2(remarks,remarks,'') AS remarks
        FROM svv_all_tables WHERE database_name = database_name1 AND schema_name = schema_name1 AND table_name = table_name1
        ORDER BY table_acl ASC, remarks asc)) AS Rec;

    IF NOT FOUND THEN
        RAISE NOTICE 'Tables match';
    ELSE
        RAISE EXCEPTION 'Tables do not match. Table_acl: %, remarks: %', record_set.table_acl, record_set.remarks;
    END IF;
END;
$$ LANGUAGE plpgsql;

--CALL <schema_name>.column_compare ('<database>','<schema>','<table>','<database>','<schema>','<table>');