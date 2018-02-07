--[[

	OO approach to API where you do
		action:remove()
	instead of
		remove_action(action)

	Put as a layer above the OCaml API

	@since 2013-07-22

--]]

-- Action class
Action = {}
__actions = {}	-- Global list of actions, to track id etc

function Action:add()
	add_action(self)
end

function Action:remove()
	remove_action(self)
end

function Action:exists()
	return action_exists(self)
end

function Action:new(a)
	a.action_id = #__actions + 1

	-- Validation
	if a.action_name ~= "play_card" and
	   a.action_name ~= "pick_card" then
		error("Action:new: action_name not supported: " .. a.action_name)
	end

	if a.menu_text == nil then
		error("Action:new: no menu_text")
	end

	if #a.players == 0 then
		error("Action:new: no players")
	end

	if a.target ~= "hand" and
	   a.target ~= "deck" and
	   a.target ~= "player_slot" then
		error("Action:new: illegal target: " .. a.target)
	end

	if #a.target_ids == 0 then
		error("Action:new: no target ids")
	end

	setmetatable(a, self)
	self.__index = self
	table.insert(__actions, a)
	return a
end
