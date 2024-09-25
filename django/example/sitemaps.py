from django.contrib import sitemaps
from django.urls import reverse


class StaticViewSitemap(sitemaps.Sitemap):
    priority = 0.5
    changefreq = 'yearly'

    def items(self):
        return ['slow']

    def location(self, item):
        return reverse(item)
