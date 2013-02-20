import config
import json


def wikischema():
    s = {}
    rows = config.WikiDB.query('SELECT table_name, column_name,
                               substring_index(column_type, " ", 1) as
                               data_type FROM information_schema.columns
                               WHERE table_schema="enwiki"')
    for row in rows:
        if row.table_name not in s:
            s[row.table_name] = {}
        s[row.table_name][row.column_name] = row.data_type
    return s


def save_review(r, b):
    review = json.dumps(r)
    banned = json.dumps(b)
    result = config.DB.query("REPLACE INTO gn_data VALUES
                             ('enwiki_review', '%s')" % (review))
    if result:
        result = config.DB.query("REPLACE INTO gn_data VALUES
                                 ('enwiki_banned', '%s')" % (banned))
    return result


def get_review():
    result = config.DB.select('gn_data', what="gnd_value",
                              where="gnd_key='enwiki_review'")
    if result:
        return json.loads(result[0]['gnd_value'])
    else:
        return False


def get_redact_list():
    result = config.DB.select('gn_data', what="gnd_value",
                              where="gnd_key='enwiki_banned'")
    if result:
        return json.loads(result[0]['gnd_value'])
    else:
        return False


def get_redaction(tcol):
    result = config.DB.select('gn_data', what="gnd_value",
                              where="gnd_key='%s'" % (tcol))
    if result:
        return result[0]['gnd_value']
    else:
        return None


def save_redaction(tcol):
    result = config.DB.query("REPLACE INTO gn_data VALUES
                             ('%s', '%s')" % (tcol.keys()[0],
                             tcol.values()[0]))
