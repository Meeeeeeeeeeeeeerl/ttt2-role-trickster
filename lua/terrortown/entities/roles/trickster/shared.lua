if SERVER then
    AddCSLuaFile()
	resource.AddFile("materials/vgui/ttt/dynamic/roles/icon_trick.vmt")
end

function ROLE:PreInitialize()
    self.color = Color(170, 30, 30)
    self.abbr  = "trick"

    self.defaultTeam = TEAM_TRAITOR
	self.surviveBonus               = 0
	self.scoreKillsMultiplier       = 1
	self.scoreTeamKillsMultiplier   = -8
	self.preventFindCredits         = true
	self.preventKillCredits         = true
	self.preventTraitorAloneCredits = false
	self.preventWin                 = false
	self.unknownTeam                = false
	self.passive = true
	self.isOmniscientRole = true

    	self.conVarData = {
		pct = 0.17, -- necessary: percentage of getting this role selected (per player)
		maximum = 1, -- maximum amount of roles in a round
		minPlayers = 6, -- minimum amount of players until this role is able to get selected
		credits = 1, -- the starting credits of a specific role
		togglable = true, -- option to toggle a role for a client if possible (F1 menu)
		random = 30,
		traitorButton = 1, -- can use traitor buttons
		shopFallback = SHOP_FALLBACK_TRAITOR -- granting the role access to the shop
	}
end

function ROLE:Initialize()
	roles.SetBaseRole(self, ROLE_TRAITOR)
end

local deadTricksters = {}
local function RevertDeadTricksters()
	for index, player in ipairs(deadTricksters) do
		if IsValid(player) and player:GetSubRole() == ROLE_INNOCENT and player:Alive() then
			player:SetRole(ROLE_TRICKSTER)
		end
	end
	deadTricksters = {}
end

if SERVER then
	-- Make corpse appear innocent and fake team
	hook.Add("TTT2PostPlayerDeath", "TricksterFakeCorpse", function(player)
		if not IsValid(player) or player:GetSubRole() ~= ROLE_TRICKSTER then return end

		local corpse = player.server_ragdoll
		if not IsValid(corpse) then return end

		-- Fake role for body search
		corpse.was_role = ROLE_INNOCENT
		corpse.confirmed = false
		corpse.was_team = TEAM_INNOCENT
		corpse.role_color = Color(80, 173, 59, 255)
		CORPSE.SetCredits(corpse, 0)
		player:SetRole(ROLE_INNOCENT)
		deadTricksters.insert(player)
	end)

	hook.Add("PlayerDisconnected", "TricksterCleanupDisconnect", function(player)
        if not IsValid(player) then return end
        for index, deadTrickster in ipairs(deadTricksters) do
			if deadTrickster == player then
				table.remove(deadTricksters, index)
				break
			end
		end
    end)

	hook.Add("TTTEndRound", "TricksterCleanupRoundEnd", function(result)
		RevertDeadTricksters()
	end)

	hook.Add("TTTBeginRound", "TricksterCleanupRoundStart", function()
		deadTricksters = {}
	end)
end
