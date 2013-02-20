redactatron
===========

An app for reviewing and redacting a mediawiki database schema for public consumption.  Intended for providing privacy redacted
wikipedia mysql replicas in wikimedia labs.

Reads the schema from a live wiki slave and provides for the review of every individual column, which must be either approved hidden
from public consumption.  For columns being redacted, default values can be provided.  Data cleanup scripts and mysql triggers will be
generated from this.

Todo
===========
This version currently just has basic CRUD functionality and lacks authentication (could use basic http auth, but needs csrf protection.)

Next step is to add generation of mysql triggers and data cleanup scripts.

Install
===========
For development:
1) install web.py (on ubuntu: apt-get install python-webpy)
2) python ./code.py
