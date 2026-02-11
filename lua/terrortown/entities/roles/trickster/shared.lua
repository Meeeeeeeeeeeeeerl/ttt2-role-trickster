if SERVER then
    AddCSLuaFile()
	resource.AddFile("materials/vgui/ttt/dynamic/roles/icon_trick.vmt")
end

function ROLE:PreInitialize()
    self.color = Color(240, 22, 17)
    self.abbr  = "trick"

    self.defaultTeam = TEAM_TRAITOR
	self.surviveBonus               = 0
	self.scoreKillsMultiplier       = 1
	self.scoreTeamKillsMultiplier   = -8
	self.preventFindCredits         = false
	self.preventKillCredits         = false
	self.preventTraitorAloneCredits = false
	self.creditsAwardKillEnable = 1
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

if SERVER then

	hook.Add("TTTOnCorpseCreated", "TricksterFakeTeamswitch", function(corpse, player)
		if not IsValid(player) or player:GetSubRole() ~= ROLE_TRICKSTER or not IsValid(corpse) then return end
		corpse.was_role = ROLE_INNOCENT
		corpse.confirmed = false
		corpse.was_team = TEAM_INNOCENT
		corpse.role_color = TEAMS[TEAM_INNOCENT].color
		corpse:SetNWBool("real_player_corpse", true)
		CORPSE.SetCredits(corpse, 0)
	end)

	hook.Add("TTT2ModifyLogicRoleCheck", "TricksterTestFaker", function(player, _ent, _activator, _caller, _data)
		if not IsValid(player) or not player:IsActive() or player:GetSubRole() ~= ROLE_TRICKSTER and not GetConVar("ttt2_trickster_test_as_innocent"):GetBool() then return end
		return ROLE_INNOCENT, TEAM_INNOCENT
	end)

	hook.Add("TTT2CheckCreditAward", "TricksterPreventKillCredit", function(victim, attacker)
		if IsValid(victim) and victim:GetSubRole() == ROLE_TRICKSTER then
			return false
		end
		return true
	end)
end

hook.Add("TTTScoreboardRowColorForPlayer", "TricksterScoreboardRowColorFake", function(player)
    local client = LocalPlayer()
    if not IsValid(client) or not client:HasRole() then return end
	if player:GetTeam() == client:GetTeam() then return end
	if IsValid(player) and player:GetSubRole() == ROLE_TRICKSTER then
		return TEAMS[TEAM_INNOCENT].color
	end
end)

hook.Add("TTT2ModifyMiniscoreboardColor", "TricksterMiniScoreboardColorFake", function(player, _col)
	local client = LocalPlayer()
    if not IsValid(client) or not client:HasRole() then return end
	if player:GetTeam() == client:GetTeam() then return end
	if IsValid(player) and player:GetSubRole() == ROLE_TRICKSTER then
		return TEAMS[TEAM_INNOCENT].color
	end
end)

hook.Add("TTTRenderEntityInfo", "TricksterFakeIcon", function(tData)
	local ent = tData:GetEntity()

    if not IsValid(ent) or not ent:IsPlayerRagdoll() then return end
	local player = CORPSE.GetPlayer(ent)
	if not IsValid(player) or not CORPSE.GetFound(ent, false) or player:GetSubRole() ~= ROLE_TRICKSTER then return end
	local roleData = roles.GetByIndex(ROLE_INNOCENT)

	local _data, params = tData:GetRaw()

	params.displayInfo.icon = {}

    tData:AddIcon(
        roleData.iconMaterial,
        roleData.color
    )
end)

hook.Add("TTTScoreboardColumns", "TricksterTeamIconOverride", function(row)
    local oldUpdate = row.UpdatePlayerData

    function row:UpdatePlayerData()
        oldUpdate(self)

        local ply = self.Player
        local client = LocalPlayer()

        if not IsValid(ply) or not ply:HasRole() then return end
        if not IsValid(client) or not client:HasRole() then return end

        if ply:GetSubRole() ~= ROLE_TRICKSTER then return end
        if ply:GetTeam() == client:GetTeam() then return end

        local icon = TEAMS[TEAM_INNOCENT].iconMaterial:GetName()

        self.team:SetTooltip(LANG.GetTranslation(TEAM_INNOCENT))
        self.team:SetImage(icon)
        self.team2:SetImage(icon)
    end
end)


hook.Add("TTT2UpdateSubrole", "DenyTricksterSidekick", function(player, oldSubrole, newSubrole)
	if oldSubrole == ROLE_TRICKSTER and newSubrole == ROLE_SIDEKICK and GetConVar("ttt2_trickster_refuse_sidekick"):GetBool() then
		player:SetRole(ROLE_TRICKSTER, TEAM_TRAITOR)
		SendFullStateUpdate()
	end
end)

hook.Add("TTT2UpdateTeam", "TricksterNoLove", function(player, _oldTeam, newTeam)
	if player:GetSubRole() == ROLE_TRICKSTER and newTeam == TEAM_LOVER and player:Alive() and GetConVar("ttt2_trickster_refuse_team_lovers"):GetBool() then
		timer.Simple(1, function()
			if lovedones then
				LANG.Msg(player, "trickster_love_faded", nil, MSG_MSTACK_PLAIN)
				lovedones = {}
				player:SetRole(ROLE_TRICKSTER, TEAM_TRAITOR)
				hook.Remove("EntityTakeDamage", "LoversDamageScaling")
				hook.Remove("Tick", "Lovers_Heal_Share")
				SendFullStateUpdate()
			end
		end)
	end
end)

if CLIENT then
	function ROLE:AddToSettingsMenu(parent)
		local form = vgui.CreateTTT2Form(parent, "header_roles_additional")

		form:MakeCheckBox({
			serverConvar = "ttt2_trickster_refuse_team_lovers",
			label = "label_trickster_refuse_team_lovers"
		})

		form:MakeCheckBox({
			serverConvar = "ttt2_trickster_refuse_sidekick",
			label = "label_trickster_refuse_sidekick"
		})

		form:MakeCheckBox({
			serverConvar = "ttt2_trickster_test_as_innocent",
			label = "label_trickster_test_as_innocent"
		})
	end
end