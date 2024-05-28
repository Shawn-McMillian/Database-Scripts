CREATE OR REPLACE PROCEDURE <Schema>.column_compare (
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
    FROM
        ((SELECT column_name,ordinal_position,NVL2(column_default,column_default,'') AS column_default,is_nullable,data_type,character_maximum_length, numeric_precision,numeric_scale
        INTO record_set
        FROM svv_all_columns WHERE database_name = database_name1 AND schema_name = schema_name1 AND table_name = table_name1

        EXCEPT

        SELECT column_name,ordinal_position,NVL2(column_default,column_default,'') AS column_default,is_nullable,data_type,character_maximum_length, numeric_precision,numeric_scale
        FROM svv_all_columns WHERE database_name = database_name2 AND schema_name = schema_name2 AND table_name = table_name2)

        UNION ALL

        (SELECT column_name,ordinal_position,NVL2(column_default,column_default,'') AS column_default,is_nullable,data_type,character_maximum_length, numeric_precision,numeric_scale
        FROM svv_all_columns WHERE database_name = database_name2 AND schema_name = schema_name2 AND table_name = table_name2

        EXCEPT

        SELECT column_name,ordinal_position,NVL2(column_default,column_default,'') AS column_default,is_nullable,data_type,character_maximum_length, numeric_precision,numeric_scale
        FROM svv_all_columns WHERE database_name = database_name1 AND schema_name = schema_name1 AND table_name = table_name1
        ORDER BY ordinal_position,column_name)) AS Rec;

    IF NOT FOUND THEN
        RAISE NOTICE 'Columns match';
    ELSE
        RAISE EXCEPTION 'Column: % Does not match', record_set.column_name;
    END IF;
END;
$$ LANGUAGE plpgsql;


--CALL <schema_name>.column_compare ('<database>','<schema>','<table>','<database>','<schema>','<table>');

