if SERVER then
    AddCSLuaFile()
	resource.AddFile("materials/vgui/ttt/dynamic/roles/icon_trick.vmt")
end

function ROLE:PreInitialize()
    self.color = Color(214, 47, 21)
    self.abbr  = "trick"

    self.defaultTeam = TEAM_TRAITOR
	self.surviveBonus               = 0
	self.scoreKillsMultiplier       = 1
	self.scoreTeamKillsMultiplier   = -8
	self.preventFindCredits         = false
	self.preventKillCredits         = false
	self.preventTraitorAloneCredits = false
	self.preventWin                 = false
	self.unknownTeam                = false
	self.passive = true
	self.isOmniscientRole = true

    	self.conVarData = {
		pct = 0.17,
		maximum = 1,
		minPlayers = 6,
		credits = 1,
		togglable = true,
		creditsAwardKillEnable = 1,
		creditsAwardDeadEnable = 1,
		random = 30,
		traitorButton = 1,
		shopFallback = SHOP_FALLBACK_TRAITOR
	}
end

function ROLE:Initialize()
	roles.SetBaseRole(self, ROLE_TRAITOR)
end

local tricksters = {}

local function has_value (tab, val)
    for _, value in ipairs(tab) do
        if value == val then
            return true
        end
    end
    return false
end

if SERVER then

	hook.Add("TTT2PostPlayerDeath", "TricksterFakeTeamswitch", function(player)
		if not IsValid(player) or player:GetSubRole() ~= ROLE_TRICKSTER then return end
		player:SetRole(ROLE_INNOCENT)

		local corpse = player.server_ragdoll
		if not IsValid(corpse) then return end

		-- Fake role for body search
		player.role_color = TEAMS[TEAM_INNOCENT].color
		corpse.was_role = ROLE_INNOCENT
		corpse.confirmed = false
		corpse.was_team = TEAM_INNOCENT
		corpse.role_color = TEAMS[TEAM_INNOCENT].color
		corpse:SetNWBool("real_player_corpse", false)
		CORPSE.SetCredits(corpse, 0)
	end)

	hook.Add("TTT2UpdateSubrole", "TricksterRoleChange", function(player, oldRole, newRole)
		if not player:Alive() then return end
		if oldRole == ROLE_TRICKSTER and newRole ~= ROLE_TRICKSTER then
			player:SetRole(ROLE_TRICKSTER)
		end
		if newRole == ROLE_TRICKSTER and not has_value(tricksters, player) then
			table.insert(tricksters, player)
		end
	end)

	hook.Add("TTT2UpdateTeam", "TricksterTeamChange", function(player, _oldTeam, newTeam)
		if player:GetSubRole() == ROLE_TRICKSTER and newTeam ~= TEAM_TERROR then
			player:SetTeam(TEAM_TERROR)
			SendFullStateUpdate()
		end
	end)

	hook.Add("PlayerDisconnected", "TricksterCleanupDisconnect", function(player)
        if not IsValid(player) then return end
        for index, trickster in ipairs(tricksters) do
			if trickster == player then
				table.remove(tricksters, index)
				break
			end
		end
    end)

	hook.Add("TTT2PreEndRound", "TricksterPreRound", function(result, duration)
		print("revert tricksters")
		for _, player in ipairs(tricksters) do
			if IsValid(player) then
				player:SetRole(ROLE_TRICKSTER)
				player:SetTeam(TEAM_TERROR)
			end
		end
		SendFullStateUpdate()
	end)

	hook.Add("TTTBeginRound", "TricksterCleanupRoundStart", function()
		tricksters = {}
	end)

	hook.Add("TTT2ModifyLogicRoleCheck", "TricksterTestFaker", function(player, ent, activator, caller, data)
		if not IsValid(player) or not player:IsActive() or player:GetSubRole() ~= ROLE_TRICKSTER then return end
		return ROLE_INNOCENT, TEAM_INNOCENT
	end)
end
