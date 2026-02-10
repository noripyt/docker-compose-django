#!/usr/bin/env python3

from pathlib import Path
import re
from textwrap import dedent


BASE_DIR = Path(__file__).parent
LIST_PATH = BASE_DIR / 'badbots.txt'
ROBOTS_PATH = BASE_DIR / 'nginx/templates/robots.txt.template'
FAIL2BAN_FILTER_PATH = BASE_DIR / 'fail2ban/filter.d/nginx-badbots.conf'

badbots = LIST_PATH.read_text().strip().splitlines()
while new_badbot := input('What piece of User-agent do you want to add to the bad bots? ').strip():
    if '\n' in new_badbot:
        raise ValueError(f'Bad bot {new_badbot!r} cannot contain a newline.')
    badbots.append(new_badbot)
badbots = sorted(badbots, key=lambda s: s.lower())

LIST_PATH.write_text('\n'.join(badbots) + '\n')


user_agents = '\n'.join([f'User-agent: {badbot}' for badbot in badbots])
robots_txt = f"""
User-agent: *
Sitemap: https://${{DOMAIN}}/sitemap.xml
Allow: /
Crawl-delay: 10

Disallow: /*?*

{user_agents}
Disallow: /
""".lstrip()
ROBOTS_PATH.write_text(robots_txt)


escaped_badbots = '|'.join([re.escape(badbot) for badbot in badbots])
fail2ban_filter = fr"""
[Definition]
badbots = {escaped_badbots}

failregex = (?m)^<HOST> -[^"]*"(?:GET|HEAD|POST|PUT|DELETE|CONNECT|OPTIONS|TRACE|PATCH) \S+ HTTP[^"]+" \d+ \d+ "[^"]+" "[^"]*(?:%(badbots)s)[^"]*".*$
ignoreregex =
""".lstrip()
FAIL2BAN_FILTER_PATH.write_text(fail2ban_filter)
