import web
import db
import config
import json

t_globals = dict(
    datestr=web.datestr,
)

render = web.template.render('templates/', cache=config.cache,
                             globals=t_globals)
render._keywords['globals']['render'] = render


def menu(page=None):
    return render.menu(page)


def review(schema, tables, review):
    return render.schema(schema, tables, review)


def redacted(redact):
    return render.redacted(redact)
