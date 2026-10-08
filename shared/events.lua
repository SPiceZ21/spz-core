SPZ = SPZ or {}

-- 3.1 Event Name Registry
SPZ.Events = {
  CORE_READY         = "SPZ:coreReady",
  STATE_CHANGED      = "SPZ:stateChanged",
  RACE_START         = "SPZ:raceStart",
  RACE_END           = "SPZ:raceEnd",
  POLL_OPEN          = "SPZ:pollOpen",
  POLL_CLOSE         = "SPZ:pollClose",
  BUCKET_CHANGED     = "SPZ:bucketChanged",
  PLAYER_CONNECTED   = "SPZ:playerConnected",
  PLAYER_DISCONNECTED= "SPZ:playerDisconnected",
  CLIENT_CONFIG      = "SPZ:clientConfig",

  -- spz-progression (single emitter: spz-progression/server/main.lua and
  -- server/rank_admin.lua). Fired once per race with every player's
  -- before/after RP, rank, SR, iRating — analytics and feeds read this
  -- instead of diffing profiles on a timer.
  PROGRESSION_APPLIED = "SPZ:progressionApplied",
  RANK_CHANGED        = "SPZ:rankChanged",
  RANK_VOIDED         = "SPZ:rankVoided",
  -- spz-identity (single emitter: UnlockLicense) — class letter went up.
  LICENSE_UNLOCKED    = "SPZ:licenseUnlocked",
}
