from time import sleep

from django.http import HttpResponse


def slow_view(request):
    sleep(5)
    return HttpResponse("Slow example view, to test DDoS attacks.")
