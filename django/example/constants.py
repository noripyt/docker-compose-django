import os

DJANGO_ENVIRONMENT = os.environ['DJANGO_ENVIRONMENT']
DJANGO_ENVIRONMENT_CHOICES = {'dev', 'prod', 'staging'}
if DJANGO_ENVIRONMENT not in DJANGO_ENVIRONMENT_CHOICES:
    raise ValueError(
        'DJANGO_ENVIRONMENT=%s wrong value. Available choices: %s'
        % (DJANGO_ENVIRONMENT, DJANGO_ENVIRONMENT_CHOICES)
    )
