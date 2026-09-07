-- The version lives in fxmanifest.lua, and ONLY there.
--
-- This file used to carry its own copy as a literal, and the two drifted: the
-- manifest said 2.0.0 while this returned 1.0.0, so `GetVersion()` and the
-- registry built on top of it reported a version this resource had not been for
-- some time. Nothing catches that, because both values are perfectly valid
-- strings and neither side knows the other exists.
--
-- Reading the manifest removes the second copy rather than re-syncing it. A
-- version bump is now one edit in one place, and cannot half-apply.
local VERSION = GetResourceMetadata(GetCurrentResourceName(), "version", 0) or "unknown"

exports("GetVersion", function()
    return VERSION
end)
