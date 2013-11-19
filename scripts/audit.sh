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

for db in $($query "select schema_name from schemata where schema_name like '%wik%' and schema_name not like '%\_p'" information_schema); do

    for tbl in $(egrep ',F' cols.txt | awk -F ',' '{print $1}' | uniq); do

        count="SELECT COUNT(*) FROM ${tbl} WHERE"

        for col in $(egrep "${tbl},.*,F" cols.txt | awk -F ',' '{print $2}'); do

            datatype=$($query "select data_type from columns where table_schema = '${db}' and table_name = '${tbl}' and column_name = '${col}'" information_schema)

            if [ -n "$datatype" ]; then

                if [[ "$datatype" =~ int ]]; then
                    count="$count ${col} <> 0 OR"
                elif [[ "$datatype" =~ ^binary ]]; then
                    count="$count length(trim(trailing 0x00 from ${col})) <> 0 OR"
                else
                    count="$count trim(${col}) <> '' OR"
                fi

            fi
        
        done

        if [[ "$count" =~ ^(.*)OR$ ]]; then
            count="${BASH_REMATCH[1]}"
        fi

        if [[ ! "$count" =~ WHERE$ ]]; then

            hits=$($query "$count" $db)

            echo "$hits $db $tbl"
            echo "-- $count"
        fi

    done

done
