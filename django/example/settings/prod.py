import os

from .base import *

ALLOWED_HOSTS = [os.environ['DOMAIN'], 'django']


TEMPLATES[0]['OPTIONS']['loaders'] = [  # type: ignore[index]
    (
        'django.template.loaders.cached.Loader',
        [
            'django.template.loaders.filesystem.Loader',
            'django.template.loaders.app_directories.Loader',
        ],
    ),
]
del TEMPLATES[0]['APP_DIRS']
