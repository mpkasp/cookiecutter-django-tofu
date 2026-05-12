"""
URL configuration for {{ cookiecutter.project_name }}.
"""
from django.conf import settings
from django.contrib import admin
from django.urls import path, include
from django.http import JsonResponse


def health_check(request):
    """Health check endpoint for container orchestration."""
    return JsonResponse({'status': 'healthy'})


urlpatterns = [
    path('admin/', admin.site.urls),
    path('health/', health_check, name='health'),
    path('social-auth/', include('social_django.urls', namespace='social')),
]

# Debug toolbar URLs (only in DEBUG mode)
if settings.DEBUG:
    try:
        import debug_toolbar
        urlpatterns = [
            path('__debug__/', include(debug_toolbar.urls)),
        ] + urlpatterns
    except ImportError:
        pass
