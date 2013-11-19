#!/bin/bash

host="$1"
port="$2"

if [ -z "$host" ] || [ -z "$port" ]; then
    echo "usage: <script> <host> <port>" 1>&2
    exit 1
fi

if [[ ! "$host" =~ ^db105[347]$ ]]; then
    echo "unexpected sanitarium host! $host" 2>&1
    exit 1
fi

if [[ ! "$port" =~ ^330[678]$ ]]; then
    echo "unexpected sanitarium port! $port" 2>&1
    exit 1
fi

dsn="-h $host -P $port"
query="mysql --skip-column-names $dsn -e "

for db in $($query "select schema_name from schemata where schema_name like '%wik%'" information_schema); do

    read -p "$db, go?" yn

    for tbl in $(egrep ',F' cols.txt | awk -F ',' '{print $1}' | uniq); do

        echo "-- $tbl"

        insert="CREATE TRIGGER ${tbl}_insert BEFORE INSERT ON ${tbl} FOR EACH ROW SET"
        update="CREATE TRIGGER ${tbl}_update BEFORE UPDATE ON ${tbl} FOR EACH ROW SET"
        remove="UPDATE ${tbl} SET"

        for col in $(egrep "${tbl},.*,F" cols.txt | awk -F ',' '{print $2}'); do

            datatype=$($query "select data_type from columns where table_schema = '${db}' and table_name = '${tbl}' and column_name = '${col}'" information_schema)

            if [ -n "$datatype" ]; then

                echo "-- -- $col found"

                if [[ "$datatype" =~ int ]]; then
                    insert="$insert NEW.${col} = 0,"
                    update="$update NEW.${col} = 0,"
                    remove="$remove ${col} = 0,"
                else
                    insert="$insert NEW.${col} = '',"
                    update="$update NEW.${col} = '',"
                    remove="$remove ${col} = '',"
                fi

            else
                echo "-- -- $col MISSING"
            fi
        
        done

        if [[ "$insert" =~ ^(.*),$ ]]; then
            insert="${BASH_REMATCH[1]}"
        fi

        if [[ "$update" =~ ^(.*),$ ]]; then
            update="${BASH_REMATCH[1]}"
        fi

        if [[ "$remove" =~ ^(.*),$ ]]; then
            remove="${BASH_REMATCH[1]}"
        fi

        $query "DROP TRIGGER IF EXISTS ${tbl}_insert" $db
        $query "DROP TRIGGER IF EXISTS ${tbl}_update" $db

        if [[ ! "$insert" =~ SET$ ]]; then 

            echo "-- -- -- $insert"
            $query "$insert;" $db
            echo "-- -- -- $update"
            $query "$update;" $db
            echo "-- -- -- $remove"
            $query "set session binlog_format = 'STATEMENT'; $remove;" $db

        fi

    done

done
