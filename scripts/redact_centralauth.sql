CREATE TRIGGER centralauth.globaluser_insert
BEFORE INSERT ON centralauth.globaluser
FOR EACH ROW SET
NEW.gu_email = '',
NEW.gu_email_authenticated = '',
NEW.gu_salt = '',
NEW.gu_password = '',
NEW.gu_password_reset_key = '',
NEW.gu_password_reset_expiration = '',
NEW.gu_auth_token = '',
NEW.gu_cas_token = 1;

CREATE TRIGGER centralauth.globaluser_update
BEFORE UPDATE ON centralauth.globaluser
FOR EACH ROW SET
NEW.gu_email = '',
NEW.gu_email_authenticated = '',
NEW.gu_salt = '',
NEW.gu_password = '',
NEW.gu_password_reset_key = '',
NEW.gu_password_reset_expiration = '',
NEW.gu_auth_token = '',
NEW.gu_cas_token = 1;

-- then UPDATE all records the first time
