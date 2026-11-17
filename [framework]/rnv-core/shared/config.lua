Config = {}

Config.Name = 'RUN V'
Config.Prefix = 'RNV'
Config.Debug = true

-- which identifiers we look for, the first one found is used
Config.Identifiers = { 'license', 'license2', 'vmp', 'fivem' }

-- don't let the same license join twice
Config.CheckDuplicateLicense = true

-- minutes between autosaves
Config.AutoSaveInterval = 5

-- role during a city visit, other resources decide when it changes
Config.Roles = { civilian = true, criminal = true, cop = true }
Config.DefaultRole = 'civilian'

-- alive, downed or dead
Config.LifeStates = { alive = true, downed = true, dead = true }
Config.DefaultLifeState = 'alive'

-- account types and who can own one, opening rules are in the banking resource
Config.AccountTypes = { bank = true }
Config.OwnerTypes = { player = true, group = true }

-- starting metadata for a new profile, keep it small
Config.DefaultMetadata = {}
