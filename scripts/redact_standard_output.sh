#!/bin/bash

host="$1"
port="$2"
db="$3"

if [ -z "$host" ] || [ -z "$port" ] || [ -z "$db" ]; then
    echo "usage: <script> <host> <port> <db>" 1>&2
    exit 1
fi

if [[ ! "$host" =~ ^db1069$ ]]; then
    echo "unexpected sanitarium host! $host" 2>&1
    exit 1
fi

if [[ ! "$port" =~ ^331[1234567]$ ]]; then
    echo "unexpected sanitarium port! $port" 2>&1
    exit 1
fi

dsn="-h $host -P $port"
query="mysql --skip-column-names $dsn -e "

for tbl in $(egrep ',F' cols.txt | awk -F ',' '{print $1}' | uniq); do

    echo "-- $tbl"

    insert="CREATE TRIGGER ${db}.${tbl}_insert BEFORE INSERT ON ${db}.${tbl} FOR EACH ROW SET"
    update="CREATE TRIGGER ${db}.${tbl}_update BEFORE UPDATE ON ${db}.${tbl} FOR EACH ROW SET"
    remove="UPDATE ${db}.${tbl} SET"

    for col in $(egrep "${tbl},.*,F" cols.txt | awk -F ',' '{print $2}'); do

        datatype=$($query "select data_type from columns where table_schema = '${db}' and table_name = '${tbl}' and column_name = '${col}'" information_schema)

        if [ -n "$datatype" ]; then

            echo "-- $col found"

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
            echo "-- $col MISSING"
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

    echo "DROP TRIGGER IF EXISTS ${db}.${tbl}_insert;"
    echo "DROP TRIGGER IF EXISTS ${db}.${tbl}_update;"

    if [[ ! "$insert" =~ SET$ ]]; then

        echo "-- $insert"
        echo "$insert;"
        echo "-- $update"
        echo "$update;"
        echo "-- $remove"
        echo "set session binlog_format = 'STATEMENT'; $remove;"

    fi

done
