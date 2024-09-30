from ipaddress import ip_interface
import socket

from .base import *

DEBUG = True


EMAIL_SUBJECT_PREFIX = ''

INSTALLED_APPS = [
    *INSTALLED_APPS,
    'debug_toolbar',
]

MIDDLEWARE = [
    *MIDDLEWARE,
    'debug_toolbar.middleware.DebugToolbarMiddleware',
]

INTERNAL_IPS = ['127.0.0.1']
try:
    DOCKER_INTERNAL_SUBNET = ip_interface(f"{socket.gethostbyname('django')}/255.255.0.0").network
    INTERNAL_IPS.extend([str(ip) for ip in DOCKER_INTERNAL_SUBNET])
except socket.gaierror:
    pass
