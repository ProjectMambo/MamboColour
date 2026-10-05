local root = assert(arg[1], "repository root is required")
local module_path = root .. "/lua/mambocolour.lua"

if arg[2] == "expect-load-error" then
    local loaded, message = pcall(dofile, module_path)
    assert(not loaded, "invalid palette unexpectedly loaded")
    assert(tostring(message):find(assert(arg[3]), 1, true), message)
    return
end

local mambocolour = dofile(module_path)

if arg[2] == "detach-palettes" then
    assert(os.rename(root .. "/palettes", root .. "/palettes-unavailable"))
end

local dark = mambocolour.theme("dark")
local light = mambocolour.theme("light")

assert(dark:ui():fg():hex() == "#faf7f2")
local red, green, blue = light:ui():fg():rgb()
assert(red == 28 and green == 17 and blue == 17)
assert(dark:colour():len() == 21)
assert(dark:colour():random_seeded(42):hex() == "#a2b088")
assert(light:colour():random_seeded(42):hex() == "#738763")
assert(dark:colour():random_seeded(4294967295):hex() == "#bd8f42")
assert(dark:colour():random_seeded(42):hex() ~= dark:colour():random_seeded(43):hex())
assert(dark:colour():random_seeded(42):hex() ~= light:colour():random_seeded(42):hex())
assert(dark:colour():random():hex():match("^#[0-9a-f]+$"))

local accepted, message = pcall(function()
    dark:colour():random_seeded(4294967296)
end)
assert(not accepted and message:match("seed must be an integer from 0 to 4294967295"))

math.randomseed(1989)
local expected_random = math.random()
math.randomseed(1989)
dark:colour():random()
assert(math.random() == expected_random, "random() changed the caller's global PRNG state")

local original_open = io.open
io.open = function(path, mode)
    if path == "/dev/urandom" then
        assert(mode == "rb")
        return {
            read = function(_, count)
                assert(count == 4)
                return string.char(0, 0, 0, 42)
            end,
            close = function() end,
        }
    end
    return original_open(path, mode)
end
assert(dark:colour():random():hex() == dark:colour():random_seeded(42):hex())
io.open = original_open

print("MamboColour Lua API checks passed")
