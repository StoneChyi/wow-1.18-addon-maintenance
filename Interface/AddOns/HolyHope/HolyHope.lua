------------------------------------------------------------------------------------------------------
-- HolyHope 1.0 BETA

-- Addon pour Paladin inspirer du celebre Necrosis
-- Gestion des benedictions et Compteur de sympbole des rois

-- Remerciements aux auteurs de Necrosis et KingsCounter

-- Remerciements speciaux	Erosenin, guilde Exodius, Designer de HolyHope

-- Auteur THE FREEMAN
-- Pour reporter un bug ou une ide d'amlioration: THEFREEMAN55@free.fr

-- Serveur:
-- Freeman, guilde Exodius, Ner'Zhul FR
------------------------------------------------------------------------------------------------------

-- Initialisation

HolyHope_Config = {
 ["Movable"] = true;
 ["Tooltip"] = 1;
 ["Toggle"] = true;
 ["scale"] = 1;
 ["selfcast"] = 0;
}

local HolyHopeMounted = false;
local HolyHopeKings = 0;
local HearthstoneOnHand = false;
local HearthstoneLocation = {nil,nil};
local QuirajiMountOnHand = false;
local QuirajiMountLocation = {nil,nil};
local MountOnHand = false;
local MountLocation = {nil,nil};
local TypeBlessing = 0; -- 0 benediction perso, 1 benediction de classe
local combat = false;
local PlayerName;
local load = false;
local QuirajiMount = false;
local PlayerZone;
 

------------------------------------------------------------------------------------------------------

-- FONCTIONS DE L'INTERFACE

------------------------------------------------------------------------------------------------------

-- Fonction d'initialisation
function HolyHope_Initialize()

	-- Chargement des sorts du joueur
	HolyHope_SpellSetup();

	-- Enregistrement des commandes console
	SlashCmdList["HolyHope"] = HolyHope_Slash;
	SLASH_HolyHope1 = "/holyhope";
	SLASH_HolyHope2 = "/hh";

	-- Recupertation du nom du joueur
	PlayerName = UnitName("player");
 
	-- Si le joueur n'est pas Paladin, on cache HolyHope
	if UnitClass("player") ~= HOLYHOPE_UNIT_PALADIN then
		HideUIPanel(HolyHopeButton);
		HideUIPanel(HolyHopeMountButton);
		HideUIPanel(HolyHopeMightButton);
		HideUIPanel(HolyHopeWisdomButton);
		HideUIPanel(HolyHopeSalvationButton);
		HideUIPanel(HolyHopeLightButton);
		HideUIPanel(HolyHopeFreedomButton);
		HideUIPanel(HolyHopeSacrificeButton);
		HideUIPanel(HolyKingsButton);
		HideUIPanel(HolyHopeSanctuaryButton);
		HideUIPanel(HolyHopeMountUpButton);
		HideUIPanel(HolyHopeMightUpButton);
		HideUIPanel(HolyHopeWisdomUpButton);
		HideUIPanel(HolyHopeSalvationUpButton);
		HideUIPanel(HolyHopeLightUpButton);
		HideUIPanel(HolyKingsUpButton);
		HideUIPanel(HolyHopeSanctuaryUpButton);	
	end

	-- Enregistrement des vnements intercepts par HolyHope
	this:RegisterEvent("LEARNED_SPELL_IN_TAB");
	this:RegisterEvent("PLAYER_REGEN_ENABLED");
	this:RegisterEvent("PLAYER_REGEN_DISABLED");
	
	-- Message de chargement de l'addon
	ChatFrame1:AddMessage(HOLYHOPE_MESSAGE.SLASH.InitOn);
end

-- Fonction permettant le dplacement d'lments de HolyHope sur l'cran
function HolyHope_OnDragStart(button)
	if (HolyHope_Config.Movable) then
		button:StartMoving();
	else
		return;
	end
end

-- Fonction arrtant le dplacement d'lments de HolyHope sur l'cran
function HolyHope_OnDragStop(button)
	button:StopMovingOrSizing();
end

-- Fonction lance	la mise	jour de l'interface (main) -- toutes les 0,1 secondes environ
function HolyHope_OnUpdate()
	local number = 320;
	local count = -1;
	local start, duration, cooldown;
	
	--Si c'est la premiere update on initialize
	if (load == false) then
		HolyHope_Initialize();
		HolyHope_UpdateIcons();
		load = true;
	end
		
	-- On met	jour les symboles des rois
	HolyHopeKings = HolyHope_CountKings()
	if (HolyHopeKings == 0) then
		HolyHopeKingsCount:SetText("");
	else
		HolyHopeKingsCount:SetText(HolyHopeKings);
	end

	-- On met	jour le cooldown de libert
	if( HOLYHOPE_SPELL_TABLE.ID[9] > 0 ) then
		start, duration = GetSpellCooldown(HOLYHOPE_SPELL_TABLE.ID[9], BOOKTYPE_SPELL);
		if (start > 0 and duration > 0) then
			cooldown =	floor(duration - ( GetTime() - start)) + 1;
			HolyHopeFreedomCooldown:SetText(cooldown);
		else
			HolyHopeFreedomCooldown:SetText("");
		end
	end
	-- On met	jour les cooldowns gnraux
	if( HOLYHOPE_SPELL_TABLE.ID[3] > 0 ) then
		start, duration = GetSpellCooldown(HOLYHOPE_SPELL_TABLE.ID[3], BOOKTYPE_SPELL);
		if (start > 0 and duration > 0) then
			cooldown =	floor(duration - ( GetTime() - start)) + 1;
			for index = 1, 14, 1 do
				getglobal("Cooldown"..index):SetText(cooldown);
			end
		else
			for index = 1, 14, 1 do
				getglobal("Cooldown"..index):SetText("");
			end
		end
	end

	-- On met	jour la localisation du joueur
	PlayerZone = GetRealZoneText();
	
 	-- Gestion de l'affichage du fond en fontion du nombre de symboles
 	if (combat == false) then
		if (HolyHopeKings <= number) then
			while (HolyHopeKings <= number) do
				number = number - 10;
				count = count +1;
			end
			count = 32 - count;
		 	HolyHopeButton:SetNormalTexture("Interface\\Addons\\HolyHope\\UI\\Symbol"..count);
		else
		 	HolyHopeButton:SetNormalTexture("Interface\\Addons\\HolyHope\\UI\\Symbol32");
		end
	end
end

function HolyHope_OnEvent(event)
	-- Changement de couleur suivant le mode Combat
	if (event == "PLAYER_REGEN_DISABLED") then
			HolyHopeButton:SetNormalTexture("Interface\\Addons\\HolyHope\\UI\\HolyHopeC");
			combat = true;
	elseif (event == "PLAYER_REGEN_ENABLED") then
			combat = false;
			
	-- Si un nouveau sort est apris, on rafraichie le tableau des sorts
	elseif (event == "LEARNED_SPELL_IN_TAB") then
		 	HolyHope_SpellSetup();
	end
end

-- Gestion du clic sur HolyHope
-- Clique gauche: Passe HolyHope en mode bndiction Individuel/Classe
-- Clique droit: Pierre de Foyer

function HolyHope_OnClick(button)
	if button == "RightButton" then
	 HolyHope_UseItem("Hearthstone");
	else
		if (TypeBlessing == 0) then
			TypeBlessing = 1;
			HideUIPanel(HolyHopeMightButton);
			HideUIPanel(HolyHopeWisdomButton);
			HideUIPanel(HolyHopeSalvationButton);
			HideUIPanel(HolyHopeLightButton);
		 	HideUIPanel(HolyHopeKingsButton);
		 	HideUIPanel(HolyHopeSanctuaryButton);
		 	if (HOLYHOPE_SPELL_TABLE.ID[11] ~= 0) then
				ShowUIPanel(HolyHopeMightUpButton);
			end
			if (HOLYHOPE_SPELL_TABLE.ID[12] ~= 0) then
				ShowUIPanel(HolyHopeWisdomUpButton);
			end
			if (HOLYHOPE_SPELL_TABLE.ID[13] ~= 0) then
				ShowUIPanel(HolyHopeSalvationUpButton);
			end
			if (HOLYHOPE_SPELL_TABLE.ID[14] ~= 0) then
				ShowUIPanel(HolyHopeLightUpButton);
			end
			if (HOLYHOPE_SPELL_TABLE.ID[15] ~= 0) then
				ShowUIPanel(HolyHopeKingsUpButton);
			end
			if (HOLYHOPE_SPELL_TABLE.ID[16] ~= 0) then
				ShowUIPanel(HolyHopeSanctuaryUpButton);
			end
		else
			TypeBlessing= 0;
			if (HOLYHOPE_SPELL_TABLE.ID[3] ~= 0) then
				ShowUIPanel(HolyHopeMightButton);
			end
			if (HOLYHOPE_SPELL_TABLE.ID[4] ~= 0) then
				ShowUIPanel(HolyHopeWisdomButton);
			end
			if (HOLYHOPE_SPELL_TABLE.ID[5] ~= 0) then
				ShowUIPanel(HolyHopeSalvationButton);
			end
			if (HOLYHOPE_SPELL_TABLE.ID[6] ~= 0) then
				ShowUIPanel(HolyHopeLightButton);
			end
			if (HOLYHOPE_SPELL_TABLE.ID[7] ~= 0) then
				ShowUIPanel(HolyHopeKingsButton);
			end
			if (HOLYHOPE_SPELL_TABLE.ID[8] ~= 0) then
				ShowUIPanel(HolyHopeSanctuaryButton);
			end
			HideUIPanel(HolyHopeMightUpButton);
			HideUIPanel(HolyHopeWisdomUpButton);
			HideUIPanel(HolyHopeSalvationUpButton);
			HideUIPanel(HolyHopeLightUpButton);
			HideUIPanel(HolyHopeKingsUpButton);
			HideUIPanel(HolyHopeSanctuaryUpButton);	
		end
	GameTooltip:Hide();
	end
end

-- On place les boutons des sort autour du Principal, on les cachent si le paladin ne les a pas
function HolyHope_UpdateIcons()
	local teste = HolyHopeMightButton;
	
	if (HOLYHOPE_SPELL_TABLE.ID[1] == 0 and HOLYHOPE_SPELL_TABLE.ID[2] == 0) then
		HideUIPanel(HolyHopeMountButton);
	else
	HolyHopeMountButton:SetPoint("CENTER", "HolyHopeButton", "CENTER", 0, -65);
	end	
	if (HOLYHOPE_SPELL_TABLE.ID[3] == 0) then
		HideUIPanel(HolyHopeMightButton);
	else
	teste:SetPoint("CENTER", "HolyHopeButton", "CENTER", 17, 42);
	end
	if (HOLYHOPE_SPELL_TABLE.ID[4] == 0) then
		HideUIPanel(HolyHopeWisdomButton);
	else
	HolyHopeWisdomButton:SetPoint("CENTER", "HolyHopeButton", "CENTER", -17, 42);
	end
	if (HOLYHOPE_SPELL_TABLE.ID[5] == 0) then
		HideUIPanel(HolyHopeSalvationButton);
	else
	HolyHopeSalvationButton:SetPoint("CENTER", "HolyHopeButton", "CENTER", -42, 17);
	end
	if (HOLYHOPE_SPELL_TABLE.ID[6] == 0) then
		HideUIPanel(HolyHopeLightButton);
	else
	HolyHopeLightButton:SetPoint("CENTER", "HolyHopeButton", "CENTER", 42, 17);
	end 
	if (HOLYHOPE_SPELL_TABLE.ID[7] == 0) then
		HideUIPanel(HolyHopeKingsButton);
	else
	HolyHopeKingsButton:SetPoint("CENTER", "HolyHopeButton", "CENTER", 42, -17);
	end
	if (HOLYHOPE_SPELL_TABLE.ID[8] == 0) then
		HideUIPanel(HolyHopeSanctuaryButton);
	else
		HolyHopeSanctuaryButton:SetPoint("CENTER", "HolyHopeButton", "CENTER", -42, -17);
	end 
	if (HOLYHOPE_SPELL_TABLE.ID[9] == 0) then
		HideUIPanel(HolyHopeFreedomButton);
	else
	HolyHopeFreedomButton:SetPoint("CENTER", "HolyHopeButton", "CENTER", 17, -41);
	end
	if (HOLYHOPE_SPELL_TABLE.ID[10] == 0) then
		HideUIPanel(HolyHopeSacrificeButton);
	else
	HolyHopeSacrificeButton:SetPoint("CENTER", "HolyHopeButton", "CENTER", -17, -41);
	end
	if (HOLYHOPE_SPELL_TABLE.ID[11] == 0) then
		HideUIPanel(HolyHopeMightUpButton);
	else
	HolyHopeMightUpButton:SetPoint("CENTER", "HolyHopeButton", "CENTER", 17, 42);
	end
	if (HOLYHOPE_SPELL_TABLE.ID[12] == 0) then
		HideUIPanel(HolyHopeWisdomUpButton);
	else
	HolyHopeWisdomUpButton:SetPoint("CENTER", "HolyHopeButton", "CENTER", -17, 42);
	end
	if (HOLYHOPE_SPELL_TABLE.ID[13] == 0) then
		HideUIPanel(HolyHopeSalvationUpButton);
	else
	HolyHopeSalvationUpButton:SetPoint("CENTER", "HolyHopeButton", "CENTER", -42, 17);
	end
	if (HOLYHOPE_SPELL_TABLE.ID[14] == 0) then
		HideUIPanel(HolyHopeLightUpButton);
	else
	HolyHopeLightUpButton:SetPoint("CENTER", "HolyHopeButton", "CENTER", 42, 17);
	end 
	if (HOLYHOPE_SPELL_TABLE.ID[15] == 0) then
		HideUIPanel(HolyHopeKingsUpButton);
	else
	HolyHopeKingsUpButton:SetPoint("CENTER", "HolyHopeButton", "CENTER", 42, -17);
	end
	if (HOLYHOPE_SPELL_TABLE.ID[16] == 0) then
		HideUIPanel(HolyHopeSanctuaryUpButton);
	else
		HolyHopeSanctuaryUpButton:SetPoint("CENTER", "HolyHopeButton", "CENTER", -42, -17);
	end 
end

-- Cration et Affichage des bulles d'aides
function HolyHope_BuildTooltip(button, anchor, type)
	--on verifie que les aides sont actives
	if (HolyHope_Config.Tooltip == 1) then
		-- Definie	qui apartient la bulle d'aide
		GameTooltip:SetOwner(button, anchor);
		if (type == "Mount") then
			-- Soit c'est la monture pique
			if HOLYHOPE_SPELL_TABLE.ID[2] ~= 0 then
		 		GameTooltip:AddLine("耗魔:"..HOLYHOPE_SPELL_TABLE.Mana[2]);
			-- Soit c'est la monture classique
			elseif HOLYHOPE_SPELL_TABLE.ID[1] ~= 0 then
				GameTooltip:AddLine("耗魔:"..HOLYHOPE_SPELL_TABLE.Mana[1]);
			end
		elseif (type == "Might") then
			GameTooltip:AddLine("耗魔:"..HOLYHOPE_SPELL_TABLE.Mana[3]);
		elseif (type == "Wisdom") then
			GameTooltip:AddLine("耗魔:"..HOLYHOPE_SPELL_TABLE.Mana[4]);
		elseif (type == "Salvation") then
			GameTooltip:AddLine("耗魔:"..HOLYHOPE_SPELL_TABLE.Mana[5]);
		elseif (type == "Light") then
			GameTooltip:AddLine("耗魔:"..HOLYHOPE_SPELL_TABLE.Mana[6]);
		elseif (type == "Kings") then
			GameTooltip:AddLine("耗魔:"..HOLYHOPE_SPELL_TABLE.Mana[7]);
		elseif (type == "Sanctuary") then
			GameTooltip:AddLine("耗魔:"..HOLYHOPE_SPELL_TABLE.Mana[8]);
		elseif (type == "Freedom") then
			GameTooltip:AddLine("耗魔:"..HOLYHOPE_SPELL_TABLE.Mana[9]);
		elseif (type == "Sacrifice") then
			GameTooltip:AddLine("耗魔:"..HOLYHOPE_SPELL_TABLE.Mana[10]);
		elseif (type == "MightUp") then
			GameTooltip:AddLine("耗魔:"..HOLYHOPE_SPELL_TABLE.Mana[11]);
		elseif (type == "WisdomUp") then
			GameTooltip:AddLine("耗魔:"..HOLYHOPE_SPELL_TABLE.Mana[12]);
		elseif (type == "SalvationUp") then
			GameTooltip:AddLine("耗魔:"..HOLYHOPE_SPELL_TABLE.Mana[13]);
		elseif (type == "LightUp") then
			GameTooltip:AddLine("耗魔:"..HOLYHOPE_SPELL_TABLE.Mana[14]);
		elseif (type == "KingsUp") then
			GameTooltip:AddLine("耗魔:"..HOLYHOPE_SPELL_TABLE.Mana[15]);
		elseif (type == "SanctuaryUp") then
			GameTooltip:AddLine("耗魔:"..HOLYHOPE_SPELL_TABLE.Mana[16]);
		-- Soit c'est le bouton principal
		else
			GameTooltip:AddLine(HOLYHOPE_MESSAGE.TOOLTIP.Clic);
			-- Gestion mode de bndiction
			if (TypeBlessing == 0) then
				GameTooltip:AppendText(HOLYHOPE_MESSAGE.TOOLTIP.NotUp);
			else
				GameTooltip:AppendText(HOLYHOPE_MESSAGE.TOOLTIP.Up);
			end
			GameTooltip:AddLine(HOLYHOPE_MESSAGE.TOOLTIP.RightClic);
		end
		-- On affiche
		GameTooltip:Show();
		
		elseif (HolyHope_Config.Tooltip == 2) then
		-- Definie	qui apartient la bulle d'aide
		GameTooltip:SetOwner(button, anchor);
		if (type == "Mount") then
			-- Soit c'est la monture pique
			if HOLYHOPE_SPELL_TABLE.ID[2] ~= 0 then
		 		GameTooltip:SetSpell(HOLYHOPE_SPELL_TABLE.ID[2],1);
			-- Soit c'est la monture classique
			else
				GameTooltip:SetSpell(HOLYHOPE_SPELL_TABLE.ID[1],1);
			end
		elseif (type == "Might") then
			GameTooltip:SetSpell(HOLYHOPE_SPELL_TABLE.ID[3],1);
		elseif (type == "Wisdom") then
			GameTooltip:SetSpell(HOLYHOPE_SPELL_TABLE.ID[4],1);
		elseif (type == "Salvation") then
			GameTooltip:SetSpell(HOLYHOPE_SPELL_TABLE.ID[5],1);
		elseif (type == "Light") then
			GameTooltip:SetSpell(HOLYHOPE_SPELL_TABLE.ID[6],1);
		elseif (type == "Kings") then
			GameTooltip:SetSpell(HOLYHOPE_SPELL_TABLE.ID[7],1);
		elseif (type == "Sanctuary") then
			GameTooltip:SetSpell(HOLYHOPE_SPELL_TABLE.ID[8],1);
		elseif (type == "Freedom") then
			GameTooltip:SetSpell(HOLYHOPE_SPELL_TABLE.ID[9],1);
		elseif (type == "Sacrifice") then
			GameTooltip:SetSpell(HOLYHOPE_SPELL_TABLE.ID[10],1);
		elseif (type == "MightUp") then
			GameTooltip:SetSpell(HOLYHOPE_SPELL_TABLE.ID[11],1);
		elseif (type == "WisdomUp") then
			GameTooltip:SetSpell(HOLYHOPE_SPELL_TABLE.ID[12],1);
		elseif (type == "SalvationUp") then
			GameTooltip:SetSpell(HOLYHOPE_SPELL_TABLE.ID[13],1);
		elseif (type == "LightUp") then
			GameTooltip:SetSpell(HOLYHOPE_SPELL_TABLE.ID[14],1);
		elseif (type == "KingsUp") then
			GameTooltip:SetSpell(HOLYHOPE_SPELL_TABLE.ID[15],1);
		elseif (type == "SanctuaryUp") then
			GameTooltip:SetSpell(HOLYHOPE_SPELL_TABLE.ID[16],1);
		-- Soit c'est le bouton principal
		else
			GameTooltip:AddLine(HOLYHOPE_MESSAGE.TOOLTIP.Clic);
			-- Gestion mode de bndiction
			if (TypeBlessing == 0) then
				GameTooltip:AppendText(HOLYHOPE_MESSAGE.TOOLTIP.NotUp);
			else
				GameTooltip:AppendText(HOLYHOPE_MESSAGE.TOOLTIP.Up);
			end
			GameTooltip:AddLine(HOLYHOPE_MESSAGE.TOOLTIP.RightClic);
		end
		-- On affiche
		GameTooltip:Show();
	end
end

------------------------------------------------------------------------------------------------------

-- FONCTION DE GETION DES COMMANDES SLASH

------------------------------------------------------------------------------------------------------

-- Gestion de la commande
function HolyHope_Slash(msg)
	local msg = TextParse(msg);
	msg[1] = strlower(msg[1]);
	
	if strfind(msg[1], "unlock") then
		HolyHope_Config.Movable = true;
	elseif strfind(msg[1], "lock") then
		HolyHope_Config.Movable = false;
	elseif strfind(msg[1], "toggle") then
		HolyHope_HideUI();
	elseif strfind(msg[1], "tooltip0") then
		HolyHope_Config.Tooltip = 0;
		ChatFrame1:AddMessage(HOLYHOPE_MESSAGE.SLASH.Tooltip0);
	elseif strfind(msg[1], "tooltip1") then
		HolyHope_Config.Tooltip= 1;
		ChatFrame1:AddMessage(HOLYHOPE_MESSAGE.SLASH.Tooltip1);
	elseif strfind(msg[1], "tooltip2") then
		HolyHope_Config.Tooltip= 2;
		ChatFrame1:AddMessage(HOLYHOPE_MESSAGE.SLASH.Tooltip2);
	--[[elseif strfind(msg[1], "scale") then
		local scale = tonumber(msg[2])
		if( scale <= 3.0 and scale >= 0.25 ) then
			HolyHope_Config.scale = scale;
			if (HOLYHOPE_SPELL_TABLE.ID[15] ~= 0) then
				HolyKingsUpButton:SetScale(HolyHope_Config.scale * UIParent:GetScale());
			end
			if (HOLYHOPE_SPELL_TABLE.ID[16] ~= 0) then
				HolyHopeSanctuaryUpButton:SetScale(HolyHope_Config.scale * UIParent:GetScale());
			end
			ChatFrame1:AddMessage("缩放比例设置为"..HolyHope_Config.scale);
		end]]
	 elseif strfind(msg[1], "selfcast") then
		local selfcast = tonumber(msg[2]);
		if ( selfcast == 1) then
			HolyHope_Config.selfcast = 1;
			ChatFrame1:AddMessage(HOLYHOPE_MESSAGE.SLASH.SelfCast1);
		elseif ( selfcast == 0) then
			HolyHope_Config.selfcast = 0;
			ChatFrame1:AddMessage(HOLYHOPE_MESSAGE.SLASH.SelfCast2);
		end
	else
		ChatFrame1:AddMessage(HOLYHOPE_MESSAGE.SLASH.Option1);
		ChatFrame1:AddMessage(HOLYHOPE_MESSAGE.SLASH.Option2);
		ChatFrame1:AddMessage(HOLYHOPE_MESSAGE.SLASH.Option3);
		ChatFrame1:AddMessage(HOLYHOPE_MESSAGE.SLASH.Option4);
		--ChatFrame1:AddMessage(HOLYHOPE_MESSAGE.SLASH.Option5);
	end
end

-- Active ou Desactive HolyHope (attention pour la desactivation on cache les boutons, l'addon tourne toujours)
function HolyHope_HideUI()
	if (HolyHope_Config.Toggle == true) then
		HideUIPanel(HolyHopeButton);
		HideUIPanel(HolyHopeMountButton);
		HideUIPanel(HolyHopeMightButton);
		HideUIPanel(HolyHopeWisdomButton);
		HideUIPanel(HolyHopeSalvationButton);
		HideUIPanel(HolyHopeLightButton);
		HideUIPanel(HolyHopeFreedomButton);
		HideUIPanel(HolyHopeSacrificeButton);
		HideUIPanel(HolyHopeKingsButton);
		HideUIPanel(HolyHopeSanctuaryButton);
		HideUIPanel(HolyHopeMountUpButton);
		HideUIPanel(HolyHopeMightUpButton);
		HideUIPanel(HolyHopeWisdomUpButton);
		HideUIPanel(HolyHopeSalvationUpButton);
		HideUIPanel(HolyHopeLightUpButton);
		HideUIPanel(HolyKingsUpButton);
		HideUIPanel(HolyHopeSanctuaryUpButton);
		HolyHope_Config.Toggle = false;
		ChatFrame1:AddMessage(HOLYHOPE_MESSAGE.SLASH.InitOff);
	else
		if (TypeBlessing == 0) then
			ShowUIPanel(HolyHopeMightButton);
			ShowUIPanel(HolyHopeWisdomButton);
			ShowUIPanel(HolyHopeSalvationButton);
			ShowUIPanel(HolyHopeLightButton);
			ShowUIPanel(HolyHopeKingsButton);
			ShowUIPanel(HolyHopeSanctuaryButton);
		else
			ShowUIPanel(HolyHopeMightUpButton);
			ShowUIPanel(HolyHopeWisdomUpButton);
			ShowUIPanel(HolyHopeSalvationUpButton);
			ShowUIPanel(HolyHopeLightUpButton);
			ShowUIPanel(HolyKingsUpButton);
			ShowUIPanel(HolyHopeSanctuaryUpButton);
		end
		ShowUIPanel(HolyHopeButton);
		ShowUIPanel(HolyHopeMountButton);
		ShowUIPanel(HolyHopeFreedomButton);
		ShowUIPanel(HolyHopeSacrificeButton);
		HolyHope_UpdateIcons();
		HolyHope_Config.Toggle = true;
		ChatFrame1:AddMessage(HOLYHOPE_MESSAGE.SLASH.InitOn);		
	end
end

------------------------------------------------------------------------------------------------------

-- FONCTION DE HOLYHOPE

------------------------------------------------------------------------------------------------------

-- 2 fonctions de recherche pour plus de spcificit: 
-- il vaut mieux perdre 15sec de copi-coller/modif que X fois de cycle machine pour rien^^
-- Trouve la localisation de la pierre de foyer dans le sac
function HolyHope_FindHearthstone()
local bag, slot = 0;
	for bag = 0, NUM_BAG_FRAMES do
		for slot = 1, GetContainerNumSlots(bag) do
		local itemName = GetContainerItemLink(bag, slot);
			if itemName then
				if string.find(itemName, HOLYHOPE_ITEM.Hearthstone) then
					HearthstoneOnHand = true;
					HearthstoneLocation = {bag,slot};
				else
					HeathstoneOnHand = false;
				end
			end
		end
	end
end

-- Trouve la localisation de la monture quiraji dans le sac
function HolyHope_FindQuirajiMount()
local bag, slot = 0;
	for bag = 0, NUM_BAG_FRAMES do
		for slot = 1, GetContainerNumSlots(bag) do
		local itemName = GetContainerItemLink(bag, slot);
			if itemName then
				if string.find(itemName, HOLYHOPE_ITEM.QuirajiMount) then
					QuirajiMountOnHand = true;
					QuirajiMountLocation = {bag,slot};	
 				end
			end
		end
	end
end

-- Trouve la localisation des montures dans le sac
function HolyHope_FindMount()
local bag, slot = 0;
	for bag = 0, NUM_BAG_FRAMES do
		for slot = 1, GetContainerNumSlots(bag) do
		local itemName = GetContainerItemLink(bag, slot);
			if itemName then
				if string.find(itemName, MOUNT_ITEM.ReinsMount) then
					MountLocation = {bag,slot};
					MountOnHand = true;
				elseif string.find(itemName, MOUNT_ITEM.RamMount) then
					MountLocation = {bag,slot};
					MountOnHand = true;
				elseif string.find(itemName, MOUNT_ITEM.BridleMount) then
					MountLocation = {bag,slot};
					MountOnHand = true;
				elseif string.find(itemName, MOUNT_ITEM.BridleMount2) then
					MountLocation = {bag,slot};
					MountOnHand = true;
				elseif string.find(itemName, MOUNT_ITEM.BridleMount3) then
					MountLocation = {bag,slot};
					MountOnHand = true;
				elseif string.find(itemName, MOUNT_ITEM.MechanostriderMount) then
					MountLocation = {bag,slot};
					MountOnHand = true;
				end
			end
		end
	end
end

-- Renvoi le nombre de symbole des rois contenus dans les sacs
function HolyHope_CountKings()
	local kings = 0;
	local bag, slot = 0;
	for bag = 0, NUM_BAG_FRAMES do
		for slot = 1, GetContainerNumSlots(bag) do
		local itemName = GetContainerItemLink(bag, slot);
			if itemName then
				if string.find(itemName, "%["..HOLYHOPE_ITEM.Kings.."%]") then
					local texture, count = GetContainerItemInfo(bag, slot);
					kings = kings + count;
				end
			end
		end
	end
	return kings;
end

-- Fonction pour grer les actions effectues par HolyHope au clic sur un boutton
function HolyHope_UseItem(type,button)

	-- Fonction pour utiliser une pierre de foyer dans l'inventaire
	if (type == "Hearthstone") then
		-- Trouve les items utilis par HolyHope
		HolyHope_FindHearthstone();
		if (HearthstoneOnHand) then
		-- on l'utilise
		UseContainerItem(HearthstoneLocation[1], HearthstoneLocation[2]);
		-- soit il n'y en a pas dans l'inventaire, on affiche un message d'erreur
		else
		ChatFrame1:AddMessage(HOLYHOPE_MESSAGE.nohearthstone);
		end
	end

	-- Si on clic sur le bouton de monture
	if (type == "Mount") then
	 -- Trouve les montures
	 HolyHope_FindQuirajiMount();
	 HolyHope_FindMount();
		-- Si le Paladin est	AQ et qu'il a la monture
		if (QuirajiMountOnHand and PlayerZone == "安其拉") then	
			UseContainerItem(QuirajiMountLocation[1], QuirajiMountLocation[2]); 
		else
			-- Soit c'est la monture pique
			if HOLYHOPE_SPELL_TABLE.ID[2] ~= 0 then
				CastSpell(HOLYHOPE_SPELL_TABLE.ID[2], "spell");
			-- Soit c'est une autre monture
			elseif (MountOnHand) then
				UseContainerItem(MountLocation[1], MountLocation[2]); 	
		 	-- Soit c'est la monture classique
		 	else
				CastSpell(HOLYHOPE_SPELL_TABLE.ID[1], "spell");
		 	end
		end
	end
	
	 -- Gestion de l'auto target au clic droit (debut)
	if (button == "RightButton") then
		if ( UnitIsFriend("player","target") and ( UnitName("target") ~= UnitName("player"))) then
			isme = false;
			targetname = UnitName("target");
			TargetUnit("player");
		else
			isme = true;
		end
	end
	if ( not UnitIsFriend("player","target") ) then
		isFriend = false;
	else
		isFriend = true;
	end

	-- Si on clic sur le bouton de la bndiction de puissance
	if (type == "Might") then
		if (TypeBlessing == 0) then
			CastSpell(HOLYHOPE_SPELL_TABLE.ID[3], "spell");
		else
			CastSpell(HOLYHOPE_SPELL_TABLE.ID[11], "spell");
		end
	end
	
	-- Si on clic sur le bouton de la bndiction de sagesse
	if (type == "Wisdom") then
		 if (TypeBlessing == 0) then
			CastSpell(HOLYHOPE_SPELL_TABLE.ID[4], "spell");
		else
			CastSpell(HOLYHOPE_SPELL_TABLE.ID[12], "spell");
		end
	end
	
	-- Si on clic sur le bouton de la bndiction de salut
	if (type == "Salvation") then
		 if (TypeBlessing == 0) then
			CastSpell(HOLYHOPE_SPELL_TABLE.ID[5], "spell");
		else
			CastSpell(HOLYHOPE_SPELL_TABLE.ID[13], "spell");
		end
	end
	
	-- Si on clic sur le bouton de la bndiction de lumire
	if (type == "Light") then
		if (TypeBlessing == 0) then
			CastSpell(HOLYHOPE_SPELL_TABLE.ID[6], "spell");
		else
			CastSpell(HOLYHOPE_SPELL_TABLE.ID[14], "spell");
		end
	end

	-- Si on clic sur le bouton de la bndiction des rois
	if (type == "Kings") then
		if (TypeBlessing == 0) then
			CastSpell(HOLYHOPE_SPELL_TABLE.ID[7], "spell");
		else
			CastSpell(HOLYHOPE_SPELL_TABLE.ID[15], "spell");
		end
	end
	
	-- Si on clic sur le bouton de la bndiction de sanctuaire
	if (type == "Sanctuary") then
		if (TypeBlessing == 0) then
			CastSpell(HOLYHOPE_SPELL_TABLE.ID[8], "spell");
		else
			CastSpell(HOLYHOPE_SPELL_TABLE.ID[16], "spell");
		end
	end

	if (type == "Freedom") then
		CastSpell(HOLYHOPE_SPELL_TABLE.ID[9], "spell");
	end
	
	if (type == "Sacrifice") then
		CastSpell(HOLYHOPE_SPELL_TABLE.ID[10], "spell");
	end

	if ( not isFriend and HolyHope_Config.selfcast == 1 ) then
		SpellTargetUnit("player");
	end

	-- Gestion de l'auto target au clic droit (fin)
	if (button == "RightButton") then
		if (isme) then
			SpellTargetUnit("player");
		else
			TargetByName(targetname);
		end
	end
end

---------------------------------------------------------------------------------------------

-- FONCTION REPRIT SUR D'AUTRE ADDON

---------------------------------------------------------------------------------------------

-- Cree la liste des sorts connus par le Paladin, et les classe par rangs.
function HolyHope_SpellSetup()
	
	local CurrentSpells = {
		ID = {},
		Name = {},
		subName = {}
	};
	
	local spellID = 1;
	local Invisible = 0;
	local InvisibleID = 0;

	-- On va parcourir tous les sorts posseds par le Paladin
	while true do
		local spellName, subSpellName = GetSpellName(spellID, BOOKTYPE_SPELL);

		if not spellName then
			do break end
		end
		
		if (spellName) then
			-- Pour les sorts avec des rangs numrots, on compare pour chaque sort les rangs 1	1
			-- Le rang suprieur est conserv
			if (string.find(subSpellName, HOLYHOPE_TRANSLATION.Rank)) then
				local found = false;
				local rank = tonumber(strsub(subSpellName, 8, strlen(subSpellName)));
				for index=1, table.getn(CurrentSpells.Name), 1 do
					if (CurrentSpells.Name[index] == spellName) then
						found = true;
						if (CurrentSpells.subName[index] < rank) then
							CurrentSpells.ID[index] = spellID;
							CurrentSpells.subName[index] = rank;
						end
						break;
					end
				end
				-- Les plus grands rangs de chacun des sorts	rang numrots sont insrs dans la table
				if (not found) then
					table.insert(CurrentSpells.ID, spellID);
					table.insert(CurrentSpells.Name, spellName);
					table.insert(CurrentSpells.subName, rank);
				end
			end
		end
		spellID = spellID + 1;
	end

	-- On met	jour la liste des sorts avec les nouveaux rangs
	for spell=1, table.getn(HOLYHOPE_SPELL_TABLE.Name), 1 do
		for index=1, table.getn(CurrentSpells.Name), 1 do
			if (HOLYHOPE_SPELL_TABLE.Name[spell] == CurrentSpells.Name[index]) then
				HOLYHOPE_SPELL_TABLE.ID[spell] = CurrentSpells.ID[index];
				HOLYHOPE_SPELL_TABLE.Rank[spell] = CurrentSpells.subName[index];
			end
		end
	end
	
	for index=1, table.getn(HOLYHOPE_SPELL_TABLE.Name), 1 do
		HOLYHOPE_SPELL_TABLE.ID[index] = 0;
	end
	for spellID=1, MAX_SPELLS, 1 do
				local spellName, subSpellName = GetSpellName(spellID, "spell");
		if (spellName) then
			for index=1, table.getn(HOLYHOPE_SPELL_TABLE.Name), 1 do
				if HOLYHOPE_SPELL_TABLE.Name[index] == spellName then
					HolyHope_MoneyToggle();
					GameTooltip:SetSpell(spellID,1);
					local _, _, ManaCost = string.find(GameTooltipTextLeft2:GetText(), "(%d+)");
					HolyHope_MoneyToggle();
					HOLYHOPE_SPELL_TABLE.ID[index] = spellID;
					HOLYHOPE_SPELL_TABLE.Mana[index] = tonumber(ManaCost);
				end
			end
		end
	end
	
end

function HolyHope_MoneyToggle()
	for index=1, 10 do
		local text = getglobal("GameTooltipTextLeft"..index);
			text:SetText(nil);
			text = getglobal("GameTooltipTextRight"..index);
			text:SetText(nil);
	end
	GameTooltip:Hide();
	GameTooltip:SetOwner(WorldFrame, "ANCHOR_NONE"); 
end

function TextParse(InputString)
--[[ By FERNANDO!
	This function should take a string and return a table with each word from the string in
	each entry. IE, "Linoleum is teh awesome" returns {"Linoleum", "is", "teh", "awesome"}
	Some good should come of this, I've been avoiding writing a text parser for a while, and
	I need one I understand completely. ^_^

	If you want to gank this function and use it for whatever, feel free. Just give me props
	somewhere. This function, as far as I can tell, is fairly foolproof. It's hard to get it
	to screw up. It's also completely self-contained. Just cut and paste.]]
	 local Text = InputString;
	 local TextLength = 1;
	 local OutputTable = {};
	 local OTIndex = 1;
	 local StartAt = 1;
	 local StopAt = 1;
	 local TextStart = 1;
	 local TextStop = 1;
	 local TextRemaining = 1;
	 local NextSpace = 1;
	 local Chunk = "";
	 local Iterations = 1;
	 local EarlyError = false;

	 if ((Text ~= nil) and (Text ~= "")) then
	 -- ... Yeah. I'm not even going to begin without checking to make sure Im not getting
	 -- invalid data. The big ol crashes I got with my color functions taught me that. ^_^

			-- First, it's time to strip out any extra spaces, ie any more than ONE space at a time.
			while (string.find(Text, "	") ~= nil) do
				 Text = string.gsub(Text, "	", " ");
			end

			-- Now, what if text consisted of only spaces, for some ungodly reason? Well...
			if (string.len(Text) <= 1) then
				 EarlyError = true;
			end

			-- Now, if there is a leading or trailing space, we nix them.
			if EarlyError ~= true then
				TextStart = 1;
				TextStop = string.len(Text);

				if (string.sub(Text, TextStart, TextStart) == " ") then
					 TextStart = TextStart+1;
				end

				if (string.sub(Text, TextStop, TextStop) == " ") then
					 TextStop = TextStop-1;
				end

				Text = string.sub(Text, TextStart, TextStop);
			end

			-- Finally, on to breaking up the goddamn string.

			OTIndex = 1;
			TextRemaining = string.len(Text);

			while (StartAt <= TextRemaining) and (EarlyError ~= true) do

				 -- NextSpace is the index of the next space in the string...
				 NextSpace = string.find(Text, " ",StartAt);
				 -- if there isn't another space, then StopAt is the length of the rest of the
				 -- string, otherwise it's just before the next space...
				 if (NextSpace ~= nil) then
						StopAt = (NextSpace - 1);
				 else
						StopAt = string.len(Text);
						LetsEnd = true;
				 end

				 Chunk = string.sub(Text, StartAt, StopAt);
				 OutputTable[OTIndex] = Chunk;
				 OTIndex = OTIndex + 1;

				 StartAt = StopAt + 2;

			end
	 else
			OutputTable[1] = "Error: Bad value passed to TextParse!";
	 end

	 if (EarlyError ~= true) then
			return OutputTable;
	 else
			return {"Error: Bad value passed to TextParse!"};
	 end
end
