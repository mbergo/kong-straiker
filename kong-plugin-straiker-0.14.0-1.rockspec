package = "kong-plugin-straiker"
version = "0.14.0-1"
supported_platforms = { "linux", "macosx" }
source = {
   url = "file://./",
}
description = {
   summary = "Straiker AI security plugin for Kong Gateway",
   detailed = [[
Straiker on Kong Gateway. One rock, one plugin:

  straiker
      Inspects LLM traffic on a route and enforces the Straiker verdict at
      the edge. Speaks Anthropic Messages and OpenAI chat, so the same
      plugin covers chat applications and coding agents (Claude Code and
      other Anthropic Messages clients). Scores the prompt in `access` and
      the model's answer afterwards, and injects the upstream model
      credential so the client never holds it.

Delivery mode is the STRAIKER_KONG_MODE environment variable, NOT a config
field:

  buffered (default)
      Kong holds the answer until Straiker has scored it, so a violating
      tool_use never reaches the client. Time to first token becomes the
      completion time.

  streaming
      Tokens reach the client untouched and the answer is relayed to
      Straiker afterwards. Prompts and tool results are still enforced;
      the answer's verdict is advisory because the client already has it.

It is an environment variable because Kong refuses a plugin that
implements both `response` and `body_filter`, and it inspects the handler
table at load time -- so the choice cannot be per-config. A config field
would advertise a switch that cannot work. The mode is therefore
node-wide: a node serves one mode, and changing it is a restart.

The plugin is exactly one handler.lua and one schema.lua, with no sibling
modules and no require() in the schema. That is what Kong streaming custom
plugins accept, so the same sources install as a rock, copy into a Docker
image, or upload to a Konnect Dedicated Cloud Gateway unchanged.
tools/check-plugin-layout.sh enforces it.

Enable with:
  KONG_PLUGINS=bundled,straiker

v0.14.0 -- buffered mode holds streamed answers on Kong AI Gateway 2.2 and
later. That runtime turns response buffering off for a streamed request after
this plugin has been collected, so on 0.13.0 a streamed answer behind a Model
or an AI proxy was passed through unscored with x-straiker-verdict: allow. The
access handler now requests buffering itself. The plugin also runs as a handler
delivered by the control plane (for example a Konnect custom policy of type
streaming): Kong's plugin sandbox has no os.getenv, setmetatable or timers, and
0.13.0 failed to load there. The mode is read through the env vault when the
environment cannot be read, empty lists are left out of the log record, and
streaming mode skips the answer relay with a warning where timers are missing.
An installed plugin on Kong Gateway 3.x is unchanged. No config changes.

v0.13.0 -- Straiker's turn details go on Kong's log record (straiker.session_id,
then straiker.request and straiker.response: action, turn_id, controls,
blocked_by, events_scored). x-straiker-verdict reports detect, which read as
allow before, and in buffered mode keeps the worse of the prompt's and the
answer's verdicts. The injected upstream_api_key is masked in the log record.
Derived sessions seed on the first user message and the caller. No config
changes.

v0.12.0 -- BREAKING. The three plugins are replaced by one. Both
straiker-coding-agent-buffered and straiker-coding-agent-streaming are
removed, and `straiker` is a new implementation rather than the previous
webhook plugin: it targets the Straiker v3 detect API (POST
/api/v3/detect) instead of the v1 webhook, and its config schema is not
compatible with 0.11.x. See README.md for the field-by-field migration.

v0.11.1 -- every plugin became exactly one handler.lua and one schema.lua,
so the same sources upload to a Konnect Dedicated Cloud Gateway as
streaming custom plugins.

v0.11.0 -- added coding-agent buffered and streaming plugins.
   ]],
   homepage = "https://straiker.ai",
   license = "Apache 2.0",
}
dependencies = {
   "lua >= 5.1",
   "lua-resty-http",
}
build = {
   type = "builtin",
   modules = {
      ["kong.plugins.straiker.handler"] = "kong/plugins/straiker/handler.lua",
      ["kong.plugins.straiker.schema"]  = "kong/plugins/straiker/schema.lua",
   },
}
