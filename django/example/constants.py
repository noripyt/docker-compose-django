import os

DJANGO_ENVIRONMENT = os.environ['DJANGO_ENVIRONMENT']
DJANGO_ENVIRONMENT_CHOICES = {'dev', 'prod', 'staging'}
if DJANGO_ENVIRONMENT not in DJANGO_ENVIRONMENT_CHOICES:
    raise ValueError(
        'DJANGO_ENVIRONMENT=%s wrong value. Available choices: %s'
        % (DJANGO_ENVIRONMENT, DJANGO_ENVIRONMENT_CHOICES)
    )

PROJECT = os.environ['PROJECT']
PROJECT_VERBOSE = os.environ.get('PROJECT_VERBOSE', PROJECT.replace('_', ' ').capitalize())
DOMAIN = os.environ['DOMAIN']
TZ = os.environ['TZ']
LOCALE = os.environ['LOCALE']
LANGUAGES_CODES = os.environ.get('LANGUAGES_CODES', LOCALE).split(',')
