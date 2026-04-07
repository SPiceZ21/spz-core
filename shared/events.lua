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
  CLIENT_ERROR       = "SPZ:clientError"
}
