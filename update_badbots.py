#!/usr/bin/env python3

from pathlib import Path
import re
from textwrap import dedent


BASE_DIR = Path(__file__).parent
LIST_PATH = BASE_DIR / 'badbots.txt'
ROBOTS_PATH = BASE_DIR / 'nginx/templates/robots.txt.template'
FAIL2BAN_FILTER_PATH = BASE_DIR / 'fail2ban/filter.d/nginx-badbots.conf'

ROBOTS_TXT_TEMPLATE = """
User-agent: *
Sitemap: https://${DOMAIN}/sitemap.xml
Allow: /
Crawl-delay: 10

Disallow: /*?*

%(user_agents)s
Disallow: /
""".lstrip()

FAIL2BAN_FILTER_TEMPLATE = r"""
[Definition]
failregex = (?mi)^<HOST> -[^"]*"(?:GET|HEAD|POST|PUT|DELETE|CONNECT|OPTIONS|TRACE|PATCH) \S+ HTTP[^"]+" \d+ \d+ "[^"]+" "[^"]*(?:%(escaped_badbots)s)[^"]*".*$
ignoreregex =
""".lstrip()

badbots = LIST_PATH.read_text().strip().splitlines()

print('(Hit Enter without typing a name to stop the script)')
while new_badbot := input('What piece of User-agent do you want to add to the bad bots? ').strip():
    if '\n' in new_badbot:
        raise ValueError(f'Bad bot {new_badbot!r} cannot contain a newline.')
    if new_badbot.lower() in {badbot.lower() for badbot in badbots}:
        print('Already in the list, skipping…')
    else:
        badbots.append(new_badbot)
    badbots = sorted(badbots, key=lambda s: s.lower())

    for badbot in badbots:
        if len(badbot) < 4:
            print(f'{badbot!r} is very short and might lead to false positives!')

    LIST_PATH.write_text('\n'.join(badbots) + '\n')

    user_agents = '\n'.join([f'User-agent: {badbot}' for badbot in badbots])
    ROBOTS_PATH.write_text(ROBOTS_TXT_TEMPLATE % {'user_agents': user_agents})

    escaped_badbots = '|'.join([re.escape(badbot) for badbot in badbots])
    FAIL2BAN_FILTER_PATH.write_text(FAIL2BAN_FILTER_TEMPLATE % {'escaped_badbots': escaped_badbots})
