from time import sleep

from django.http import HttpResponse, HttpRequest

def get_client_ip(request: HttpRequest) -> str:
    x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
    if x_forwarded_for:
        return x_forwarded_for.split(',')[0]
    return request.META['REMOTE_ADDR']


def slow_view(request):
    sleep(1)
    return HttpResponse(f"""
        <h1>docker-compose-django example project</h1>
        <p>Slow example view, to test DDoS attacks.</p>
        <h2>Request metadata</h2>
        <p>Guessed client IP: {get_client_ip(request)}</p>
        <p>{'</p><p>'.join(f'{k}: {v}' for k, v in sorted(request.META.items()))}</p>
    """)
