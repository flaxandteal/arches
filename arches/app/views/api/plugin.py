from django.views.generic import View

from arches.app.models import models
from arches.app.utils.response import JSONResponse
from arches.app.utils.permission_backend import (
    user_has_plugin_permissions,
    get_plugins_by_permission,
)


class Plugins(View):
    def get(self, request, plugin_id=None):
        if plugin_id is None:
            plugins = get_plugins_by_permission(user=request.user)
        else:
            plugins = user_has_plugin_permissions(
                user=request.user,
                plugins=[models.Plugin.objects.get(pk=plugin_id)]
            )

        return JSONResponse(plugins)
