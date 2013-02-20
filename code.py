import re
import web
import view
import config
from view import render
import db
import config
import json

web.config.debug = False

urls = (
    '/', 'root',
    '/review', 'review',
    '/redacted', 'redacted',
)


class root:
    def GET(self):
        raise web.seeother('/review')


class review:
    def GET(self):
        schema = db.wikischema()
        tables = sorted(schema)
        review = db.get_review()
        return render.base(view.menu('review'),
                           view.review(schema, tables, review))

    def POST(self):
        options = [0, 1, 2]
        review = db.get_review()
        schema = db.wikischema()
        data = web.input()
        banned = []

        for k, v in data.items():
            table, col = k.split('.')
            # validate all params and options against source schema
            if schema[table][col] and int(v) in options:
                if table not in review:
                    review[table] = {}
                review[table][col] = int(v)
                if int(v) == 2:
                    banned.append(k)
            else:
                # add a check for other allowed form post params here
                # instead of bailing
                raise web.HTTPError("400 Bad request",
                                    {'content-type': 'text/html'},
                                    "invalid option")
        db.save_review(review, banned)


class redacted:
    def GET(self):
        redact = {}
        schema = db.wikischema()
        block_list = db.get_redact_list()

        for tcol in block_list:
            redaction = db.get_redaction(tcol)
            table, col = tcol.split('.')
            if table not in redact:
                redact[table] = {}
            redact[table][col] = {}
            redact[table][col]['type'] = schema[table][col]
            redact[table][col]['redaction'] = redaction

            m = re.search('\d+', schema[table][col])
            if m and m.group(0):
                redact[table][col]['size'] = m.group(0)
            else:
                redact[table][col]['size'] = 64

        print redact
        return render.base(view.menu('redacted'), view.redacted(redact))

    def POST(self):
        data = web.input()
        schema = db.wikischema()

        for tcol in data:
            table, col = tcol.split('.')
            try:
                type = schema[table][col]
            except:
                raise web.HTTPError("400 Bad request",
                                    {'content-type': 'text/html'},
                                    "invalid option")
            m = re.search('\d+', type)
            if m and m.group(0):
                size = m.group(0)
            else:
                size = 128
            if len(data[tcol]) > size:
                raise web.HTTPError("400 Bad request",
                                    {'content-type': 'text/html'},
                                    "invalid option length")
            else:
                db.save_redaction({tcol: data[tcol]})

if __name__ == "__main__":
    app = web.application(urls, globals())
    session = web.session.Session(app, web.session.DiskStore('sessions'))
    app.internalerror = web.debugerror
    app.run()
