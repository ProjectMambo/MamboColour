local M = {}

local source = debug.getinfo(1, "S").source
assert(source:sub(1, 1) == "@", "mambocolour must be loaded from a file")
local module_dir = source:sub(2):match("^(.*)/[^/]+$") or "."
local root = module_dir .. "/.."
local cache = {}

local function valid_key(value)
    return value:match("^[a-z][a-z0-9_]*$") ~= nil
end

local function valid_hex(value)
    return value:match("^#[0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]$") ~= nil
end

local function read_rows(path)
    local file, message = io.open(path, "r")
    assert(file, message)
    local rows, seen, header = {}, {}, false

    for raw_line in file:lines() do
        local line = raw_line:match("^%s*(.-)%s*$")
        if line ~= "" and line:sub(1, 1) ~= "#" then
            if not header then
                assert(line == "key,hex", "invalid palette header: " .. path)
                header = true
            else
                local key, hex = line:match("^([^,]+),([^,]+)$")
                assert(key and valid_key(key), "invalid palette key: " .. line)
                assert(valid_hex(hex), "invalid palette colour: " .. line)
                assert(not seen[key], "duplicate palette key: " .. key)
                seen[key] = true
                rows[#rows + 1] = { key = key, value = hex }
            end
        end
    end
    file:close()
    assert(header and #rows > 0, "palette must not be empty: " .. path)
    return rows
end

local Colour = {}
Colour.__index = Colour

function Colour:hex()
    return self.value
end

function Colour:rgb()
    return tonumber(self.value:sub(2, 3), 16),
        tonumber(self.value:sub(4, 5), 16),
        tonumber(self.value:sub(6, 7), 16)
end

local function colour(value)
    return setmetatable({ value = value }, Colour)
end

local UiPalette = {}
UiPalette.__index = UiPalette

for _, role in ipairs({
    "bg", "bg_surface", "border", "fg", "fg_muted", "fg_subtle",
    "brand", "brand_hover", "brand_active", "on_brand", "selection",
    "focus", "interactive", "interactive_hover", "success", "warning", "error",
}) do
    UiPalette[role] = function(self)
        return colour(assert(self.values[role], "UI palette is missing role " .. role))
    end
end

local ColourPalette = {}
ColourPalette.__index = ColourPalette

local function seeded_index(seed, length)
    assert(type(seed) == "number" and seed >= 0 and seed % 1 == 0, "seed must be a non-negative integer")
    local modulus = 4294967296
    local mixed = ((seed % modulus) * 1664525 + 1013904223) % modulus
    return (mixed % length) + 1
end

function ColourPalette:random()
    return colour(self.values[math.random(#self.values)])
end

function ColourPalette:random_seeded(seed)
    return colour(self.values[seeded_index(seed, #self.values)])
end

function ColourPalette:len()
    return #self.values
end

local Theme = {}
Theme.__index = Theme

function Theme:ui()
    return self.ui_palette
end

function Theme:colour()
    return self.colour_palette
end

function M.theme(scheme)
    assert(scheme == "light" or scheme == "dark", "scheme must be light or dark")
    if cache[scheme] then
        return cache[scheme]
    end

    local directory = root .. "/palettes/mamboorche/"
    local ui_values = {}
    for _, row in ipairs(read_rows(directory .. "ui-" .. scheme .. ".csv")) do
        ui_values[row.key] = row.value
    end
    local colour_values = {}
    for _, row in ipairs(read_rows(directory .. "colour-" .. scheme .. ".csv")) do
        colour_values[#colour_values + 1] = row.value
    end

    local result = setmetatable({
        ui_palette = setmetatable({ values = ui_values }, UiPalette),
        colour_palette = setmetatable({ values = colour_values }, ColourPalette),
    }, Theme)
    cache[scheme] = result
    return result
end

return M
