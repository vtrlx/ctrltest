local lgi = require "lgi"
local Manette = lgi.require "Manette"

print(Manette)
for k, v in pairs(Manette) do
	print(k, v)
end
