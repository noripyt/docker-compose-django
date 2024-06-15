import os

from .base import *

ALLOWED_HOSTS = [os.environ['DOMAIN'], 'django']
