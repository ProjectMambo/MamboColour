local M = {}

local source = debug.getinfo(1, "S").source
assert(source:sub(1, 1) == "@", "mambocolour must be loaded from a file")
local module_dir = source:sub(2):match("^(.*)/[^/]+$") or "."
local root = module_dir .. "/.."
local modulus = 4294967296
local maximum_seed = modulus - 1
local ui_roles = {
    "bg", "bg_surface", "border", "fg", "fg_muted", "fg_subtle",
    "brand", "brand_hover", "brand_active", "on_brand", "selection",
    "focus", "interactive", "interactive_hover", "success", "warning", "error",
}

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

for _, role in ipairs(ui_roles) do
    UiPalette[role] = function(self)
        return colour(assert(self.values[role], "UI palette is missing role " .. role))
    end
end

local ColourPalette = {}
ColourPalette.__index = ColourPalette

local function seeded_index(seed, length)
    assert(
        type(seed) == "number" and seed >= 0 and seed <= maximum_seed and seed % 1 == 0,
        "seed must be an integer from 0 to 4294967295"
    )
    local mixed = ((seed % modulus) * 1664525 + 1013904223) % modulus
    return (mixed % length) + 1
end

local fallback_counter = 0

local function random_seed()
    local file = io.open("/dev/urandom", "rb")
    if file then
        local bytes = file:read(4)
        file:close()
        if bytes and #bytes == 4 then
            local first, second, third, fourth = bytes:byte(1, 4)
            return ((first * 256 + second) * 256 + third) * 256 + fourth
        end
    end

    fallback_counter = (fallback_counter + 1) % modulus
    local address_text = tostring({}):match("0x(%x+)$")
    local address = address_text and tonumber(address_text, 16) or 0
    return (os.time() + math.floor(os.clock() * 1000000) + address + fallback_counter) % modulus
end

function ColourPalette:random()
    return self:random_seeded(random_seed())
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

local function assert_keys(rows, expected, label)
    assert(#rows == #expected, label .. " keys do not match")
    for index, key in ipairs(expected) do
        assert(rows[index].key == key, label .. " keys or order do not match")
    end
end

local function matching_keys(first, second, label)
    assert(#first == #second, label .. " keys do not match")
    for index, row in ipairs(first) do
        assert(row.key == second[index].key, label .. " keys or order do not match")
    end
end

local function make_theme(ui_rows, colour_rows)
    local ui_values = {}
    for _, row in ipairs(ui_rows) do
        ui_values[row.key] = row.value
    end
    local colour_values = {}
    for _, row in ipairs(colour_rows) do
        colour_values[#colour_values + 1] = row.value
    end

    return setmetatable({
        ui_palette = setmetatable({ values = ui_values }, UiPalette),
        colour_palette = setmetatable({ values = colour_values }, ColourPalette),
    }, Theme)
end

local directory = root .. "/palettes/mamboorche/"
local ui_light = read_rows(directory .. "ui-light.csv")
local ui_dark = read_rows(directory .. "ui-dark.csv")
local colour_light = read_rows(directory .. "colour-light.csv")
local colour_dark = read_rows(directory .. "colour-dark.csv")

assert_keys(ui_light, ui_roles, "light UI palette")
assert_keys(ui_dark, ui_roles, "dark UI palette")
matching_keys(colour_light, colour_dark, "accent palettes")

local cache = {
    light = make_theme(ui_light, colour_light),
    dark = make_theme(ui_dark, colour_dark),
}

function M.theme(scheme)
    assert(cache[scheme], "scheme must be light or dark")
    return cache[scheme]
end

return M
