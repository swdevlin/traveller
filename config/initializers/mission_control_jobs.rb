# Gate Mission Control Jobs behind the app's own admin-only auth instead of
# the gem's default HTTP Basic Auth. Must use direct mattr assignment here
# (not `config.mission_control.jobs.xxx =`) — the engine's
# `config.before_initialize` hook that copies `config.mission_control.jobs.*`
# into `MissionControl::Jobs.*` runs during Rails' Bootstrap phase, before
# config/initializers/*.rb load, so the indirect form is silently ignored.
MissionControl::Jobs.base_controller_class = 'AdminController'
MissionControl::Jobs.http_basic_auth_enabled = false
