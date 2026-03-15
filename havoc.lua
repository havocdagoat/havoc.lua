local Junkie = loadstring(game:HttpGet("https://jnkie.com/sdk/library.lua"))()
Junkie.service = "HAVOC-DUELS"
Junkie.identifier = "1050870"
Junkie.provider = "HAVOC"

local function onKeyEntered(key)
  local result = Junkie.check_key(key)
  if result and result.valid then
    getgenv().SCRIPT_KEY = key
    -- load published loadstring (replace with your copied URL)
    local code = game:HttpGet("PASTED_LOADSTRING_URL")
    loadstring(code)()
  else
    -- handle errors (see possible check_key responses)
    print(result and result.error or "Unknown error")
  end
end

