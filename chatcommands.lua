-------------------------------------------------------------------------------
-- factionsmod Mod by Sapier
--
-- License WTFPL
--
--! @file chatcommnd.lua
--! @brief factionsmod chat interface
--! @copyright Sapier
--! @author Sapier
--! @date 2013-05-08
--
-- Contact sapier a t gmx net
-------------------------------------------------------------------------------

--! @class factionsmod_chat
--! @brief chat interface class
factionsmod_chat = {}

-------------------------------------------------------------------------------
-- name: init()
--
--! @brief initialize chat interface
--! @memberof factionsmod_chat
--! @public
-------------------------------------------------------------------------------

factionsmod.register_command = function(cmd_name, cmd)
    factionsmod.commands[cmd_name] = { -- default command
        name = cmd_name,
        faction_permissions = {},
        global_privileges = {},
        format = {},
        description = "This command has no description.",
        run = function(self, player, argv)
            -- check global privileges
            local global_privs = {}
            for i in ipairs(global_privileges) do
                global_privs[global_privileges] = true
            end
            local can, missing = minetest.check_player_privs(player, global_privs)
            if not can then
                --TODO: error (show missing privs?)
                return false
            end
            -- checks argument formats
            local args = {
                factions = {},
                players = {},
                strings = {},
                other = {}
            }
            for i in ipairs(format) do
                local argtype = format[i]
                local arg = argv[i]
                if argtype == "faction" then
                    local fac = factionsmod.factions[arg]
                    if not fac then
                        --TODO: error (faction required)
                        return false
                    else
                        table.insert(args.factions, fac)
                    end
                elseif argtype == "player" then
                    local pl = minetest.get_player_by_name(arg)
                    if not pl then
                        --TODO: error (player is not connected) --TODO: track existing players for offsync invites and the like
                        return false
                    else
                        table.insert(args.players, pl)
                    end
                elseif argtype == "string" then
                    table.insert(args.strings, arg)
                else
                    --TODO: error (badly formatted command definition, log to admin)
                    return false
                end
            end
            for i=#format, #argv, 1 do
                table.insert(args.other, argv[i])
            end

            -- checks permissions
            local player_faction = factionsmod.players[faction]

            if #faction_permissions > 1 and not player_faction then
                minetest.chat_send_player(player, "You are not part of any faction")
                return false
            elseif #faction_permissions > 1 then
            end

            -- get some more data
            local pos = minetest.get_player_by_name(player):getpos()
            local chunkpos = factionsmod.get_chunk_pos(pos)
            return self.on_success(player, player_faction, pos, chunkpos, args)
        end,
        on_success = function(player, faction, pos, chunkpos, args)
            minetest.chat_send_player(player, "Not implemented yet!")
        end
    }
    -- override defaults
    for k, v in pairs(cmd) do
        factionsmod.commands[cmd_name][k] = v
    end
end



function factionsmod_chat.init()

	minetest.register_privilege("faction_user",
		{
			description = "this user is allowed to interact with faction mod",
			give_to_singleplayer = true,
		}
	)
	
	minetest.register_privilege("faction_admin",
		{
			description = "this user is allowed to create or delete factionsmod",
			give_to_singleplayer = true,
		}
	)
	
	minetest.register_chatcommand("factionsmod",
		{
			params = "<cmd> <parameter 1> .. <parameter n>",
			description = "faction administration functions",
			privs = { interact=true },
			func = factionsmod_chat.cmdhandler,
		}
	)
	
	
	minetest.register_chatcommand("f",
		{
			params = "<factionname> text",
			description = "send message to a specific faction",
			privs = { faction_user=true },
			func = factionsmod_chat.chathandler,
		}
	)
end
	

-------------------------------------------
-- R E G I S T E R E D   C O M M A N D S  |
-------------------------------------------

factionsmod.register_command ("claim", {
    faction_permissions = {"claim"},
    description = "Claim the plot of land you're on.",
    on_success = function(player, faction, pos, chunkpos, args)
        local chunk = factionsmod.chunk[chunkpos]
        if not chunk then
            --TODO: success message
            player_faction:claim_chunk(chunkpos)
            return true
        else
            if chunk == player_faction.name then
                --TODO: error (chunk already claimed by faction)
                return false
            else
                --TODO: error (chunk claimed by another faction)
                return false
            end
        end
    end
})

factionsmod.register_command("unclaim", {
    faction_permissions = {"claim"},
    description = "Unclaim the plot of land you're on.",
    on_success = function(player, faction, pos, chunkpos, args)
        local chunk = factionsmod.chunk[chunkpos]
        if chunk ~= player_faction.name then
            --TODO: error (not your faction's chunk)
            return false
        else
            player_faction:unclaim_chunk(chunkpos)
            return true
        end
    end
})

--list all known factions
factionsmod.register_command("list", {
    description = "List all registered factions.",
    on_success = function(player, faction, pos, chunkpos, args)
        local list = factionsmod.get_faction_list()
        local tosend = "factionsmod: current available factionsmod:"
        
        for i,v in ipairs(list) do
            if i ~= #list then
                tosend = tosend .. " " .. v .. ","
            else
                tosend = tosend .. " " .. v
            end
        end	
        minetest.chat_send_player(player, tosend, false)
        return true
    end
})

--show factionsmod mod version
factionsmod.register_command("version", {
    description = "Displays mod version.",
    on_success = function(player, faction, pos, chunkpos, args)
        if cmd == "version" then
            minetest.chat_send_player(player, "factionsmod: version " .. factionsmod_version , false)
        return true
        end
    end
})

--show description  of faction
factionsmod.register_command("info", {
    format = {"faction"},
    description = "Shows a faction's description.",
    on_success = function(player, faction, pos, chunkpos, args)
        minetest.chat_send_player(player,
            "factionsmod: " .. args.factions[1].name .. ": " ..
            args.factions[1].description, false)
        return true
    end
})

factionsmod.register_command("leave", {
    description = "Leave your faction."
    on_success = function(player, faction, pos, chunkpos, args)
        if faction then
            faction:remove_player(player)
        else
            --TODO: error (not in a faction)
            return false
        end
        --TODO: message?
    return true
    end
})

factionsmod.register_command("kick", {
    faction_permissions = {"playerlist"},
    format = {"player"},
    description = "Kick a player from your faction.",
    on_success = function(player, faction, pos, chunkpos, args)
        local victim = args.players[1]
        if factionsmod.players[victim.name] == faction.name then
            and victim.name ~= faction.leader -- can't kick da king
            faction:remove_player(player)
            --TODO: message?
            return true
        else
            --TODO: error (player is leader or in faction)
            return false
        end
    end
})

--create new faction
factionsmod.register_command("create", {
    format = {"string"},
    description = "Create a new faction.",
    on_success = function(player, faction, pos, chunkpos, args)
        if faction then
            --TODO: error (cannot create faction while in faction)
            return false
        end
        local factioname = args.strings[1]
        if factionsmod.can_create_faction(factionname) then
            new_faction = factionsmod.create_faction(faction)
            new_faction:add_player(player)
            new_faction:set_leader(player)
            return true
        else
            --TODO: error (cannot create faction)
            return false
        end
    end
})

factionsmod.register_commmand("join", {
    format = {"faction"},
    description = "Join a faction.",
    on_success = function(player, faction, pos, chunkpos, args)
        local new_faction = args.factions[1]
        if new_faction:can_join(player) then
            if player_faction then -- leave old faction
                player_faction:remove_player(player)
                --TODO: message
            end
            new_faction:add_player(player)
        else
            --TODO: error (could not join faction)
            return false
        end
        return true
    end
})

factionsmod.register_command("disband", {
    faction_permissions = {"disband"},
    description = "Disband your faction.",
    on_success = function(player, faction, pos, chunkpos, args)
        faction:disband()
        --TODO: message
        return true
    end
})

factionsmod.register_command("close", {
    faction_permissions = {"playerslist"},
    description = "Make your faction invite-only.",
    on_success = function(player, faction, pos, chunkpos, args)
        faction:toggle_join_free(false)
        --TODO: message
        return true
    end
})

factionsmod.register_command("open", {
    faction_permissions = {"playerslist"},
    description = "Allow any player to join your faction.",
    on_success = function(player, faction, pos, chunkpos, args)
        faction:toggle_join_free(true)
        --TODO: message
        return true
    end
})

factionsmod.register_command("description", {
    faction_permissions = {"description"},
    description = "Set your faction's description",
    on_success = function(player, faction, pos, chunkpos, args)
        faction:set_description(args.other.concat(" "))
        --TODO: message
        return true
    end
})

factionsmod.register_command("invite", {
    format = {"player"},
    faction_permissions = {"playerslist"},
    description = "Invite a player to your faction.",
    on_success = function(player, faction, pos, chunkpos, args)
        faction:invite_player(args.players[1]:get_player_name)
        --TODO: message
        return true
    end
})

factionsmod.register_command("uninvite", {
    format = {"player"},
    faction_permissions = {"playerslist"},
    description = "Revoke a player's invite.",
    on_success = function(player, faction, pos, chunkpos, args)
        faction:revoke_invite(args.players[1]:get_player_name)
        --TODO: message
        return true
    end
})

factionsmod.register_command("delete", {
    global_privileges = {"faction_admin"},
    format = {"faction"},
    description = "Delete a faction.",
    on_success = function(player, faction, pos, chunkpos, args)
        args.factions[1]:disband()
        --TODO: message
        return true
    end
})

-------------------------------------------------------------------------------
-- name: cmdhandler(playername,parameter)
--
--! @brief chat command handler
--! @memberof factionsmod_chat
--! @private
--
--! @param playername name
--! @param parameter data supplied to command
-------------------------------------------------------------------------------
function factionsmod_chat.cmdhandler(playername,parameter)

	local player = minetest.env:get_player_by_name(playername)
	local params = parameter:split(" ")
    local player_faction = factionsmod.players[playersname]

	if parameter == nil or
		parameter == "" then
        if player_faction then
            minetest.chat_send_player(playername, player_faction.description)
        else
            --TODO: message, no faction
        end
		return
	end

	local cmd = factionsmod.commands[params[1]]
    if not cmd then
        --TODO: error (unknown command)
    end

    local argv = {}
    for i=2, #params, 1 do
        table.insert(argv, params[i])
    end
	
    cmd.run(player, argv)

end

-------------------------------------------------------------------------------
-- name: show_help(playername,parameter)
--
--! @brief send help message to player
--! @memberof factionsmod_chat
--! @private
--
--! @param playername name
-------------------------------------------------------------------------------
function factionsmod_chat.show_help(playername)

	local MSG = function(text)
		minetest.chat_send_player(playername,text,false)
	end
	
	MSG("factionsmod mod")
	MSG("Usage:")
    for k, v in pairs(factionsmod.commands) do
        local args = {}
        for i in ipairs(v.format) do
            table.insert(args, v.format[i])
        end
        MSG{"\t/factionsmod "..k.." <"..table.concat(args, "> <").."> : "..v.description}
    end
end

