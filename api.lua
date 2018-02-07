
-- OBS! Required
math.randomseed(os.time())

getn = table.getn
chat = print

function isArray(tbl)
	local numKeys = 0
	for _, _ in pairs(tbl) do
		numKeys = numKeys+1
	end
	local numIndices = 0
	for _, _ in ipairs(tbl) do
		numIndices = numIndices+1
	end
	return numKeys == numIndices
end

-- Error: slot_list contains {players = {player1}} => circle loop
-- Use example from Lua website instead

function dump_aux(o, depth)
		if depth > 100 then log("depth > 100"); return end
		if type(o) == 'table' and isArray(o) then
			local s = '[\n'
			for k,v in pairs(o) do
				if type(k) ~= 'number' then k = '"'..k..'"' end
				s = s .. dump_aux(v, depth + 1) .. ','
			end
			-- Strip last ,
			if string.len(s) > 2 then s = string.sub(s, 1, -2) end
			return s .. '\n] '
		elseif type(o) == 'table' then
			local s = '{\n'
			for k,v in pairs(o) do
				--if type(k) ~= 'number' then k = '"'..k..'"' end	-- This messes up JSON
				k = '"'..k..'"'
				s = s .. ''..k..': ' .. dump_aux(v, depth + 1) .. ','
			end
			-- Strip last ,
			if string.len(s) > 2 then s = string.sub(s, 1, -2) end
			return s .. '\n} '
		elseif type(o) == 'function' then
			return '"fn"'
		else
			if type(o) == 'string' then o = '"' .. o .. '"' end
			return tostring(o)
		end
end

function dump(o)
	return dump_aux(o, 0)
end

--[[
	Get deck with @deck_nr from decks.
	Deck must been added to game.

	@param deck_nr	int; nr of deck
	@return		deck if found; otherwise nil
]]--
function get_deck(deck_nr)
	
	for k, deck in pairs(decks) do
		if deck.deck_nr == deck_nr then
			return deck
		end
	end

	return nil
end

-- Get card, where ever it is (hand, deck...)
-- @param card_nr		int; unique identifier of card
function get_card(card_nr)

	for _, card in pairs(cards) do	-- ALL cards should be stored in cards at init
		if card.card_nr == card_nr then
			return card
		end
	end

	chat("Error: get_card: No card with nr " .. card_nr)
	return nil
end

--- Move @nr cards from top of @deck_id to @player_nr's hand
--
-- @param player_nr	0 < player_nr <= players
-- @param deck_id		int; id of deck, as of in db
-- @param nr		int; number of cards to draw
-- @return bool		true if succeeded; false otherwise
function __pick_card(player_nr, deck_nr, nr)
	local player = players[player_nr]
	if (player == nil) then
		chat("Error: pick_card: Found no player with nr " .. player_nr)
		return false
	end

	local deck = get_deck(deck_nr)
	if (deck == nil) then
		chat("Error: pick_card: Found no deck with nr " .. deck_nr)
		return false
	end

	if (table.getn(deck.cards) < nr) then
		chat("Error: pick_card: Not enough cards in deck")
		return false
	end


	onpickup_all(player, deck, 1)
	card.onpickup(player, deck, 1)

	-- TODO: Should be own function 
	--local card = table.remove(deck.cards, 1)
	--table.insert(player.hand, card)

	return true
end

-- Returns shuffled version of @deck
-- Original deck remains unchanged.
--[[
function shuffle(deck)
	local result = {}

	-- Copy deck (shallow)
	for k,v in pairs(deck) do
		result[k] = v
	end
	result.cards = {}	-- Remove cards

	for i, card in ipairs(deck.cards) do
		local r = math.random(1, table.getn(deck.cards))
		-- Insert random card into tmp deck
		-- table.insert(result.cards, deck.cards[r])
		table.insert(result.cards, card)
	end
	return result
end
]]--

-- Shuffle inplace
function shuffle(deck)
	
	if deck == nil then
		chat("shuffle: No deck")
		return false
	end

	t = deck.cards
	local n = #t

	while n >= 2 do
		-- n is now the last pertinent index
		local k = math.random(n) -- 1 <= k <= n
		-- Quick swap
		t[n], t[k] = t[k], t[n]
		n = n - 1
	end

	deck.cards = t

	return deck
end

-- Run when player plays a card
-- @param player		The playing player
-- @param card		Card being played
function play_card(player_nr, card_nr)
	local player = players[player_nr]
	if (player == nil) then
		chat("Error: play_card: Found no player with nr " .. player_nr)
		return false
	end

	card = get_card(card_nr)
	if card == nil then
		chat("Error: play_card: Found no card with nr " .. card_nr)
		return false
	end

	-- check so player really have card in hand
	-- done in ocaml

	-- move card is done in user specific function (can be moved to trash or table or anywhere).
	
	-- Run onplay for all cards
	onplay_all(player, card)

	-- TODO: Run onplay for card from this deck

	-- Run onplay for this card
	card.onplay(player, card)

	return true
end

--- Used with place_card_on_table()
function get_free_table_slot()
	local j = 1
	for i, slot in ipairs(table_slots) do
		if (slot == nil) then
			return i
		end
		j = j + 1
	end

	return j
end

-- Removes @card from @players hand
-- Error message if card is not found
-- Internal: Called by remove_card_from_hand()
function __remove_card_from_hand(player, card)
	local hand = player.hand
	local card_nr = card.card_nr
	for k, card in ipairs(hand) do
		if card.card_nr == card_nr then
			table.remove(hand, k)
			return true
		end
	end

	chat("Error: remove_card_from_hand: No such card nr in hand: " .. card_nr)
	return false
end

function remove_card_from_slot(player, card)
	local card_nr = card.card_nr

	for i, slot in ipairs(player.slots) do
		for k, card in ipairs(slot) do
			if card.card_nr == card_nr then
				table.remove(slot, k)
				return true
			end
		end
	end

	chat("Error: remove_card_from_slot: No such card nr in slot.cards: " .. card_nr)
	return false

end

function __remove_card_from_table(card)
	for k, table_card in ipairs(table_slots) do
		if table_card.__type == "card" then
			if table_card.card_nr == card.card_nr then
				table.remove(table_slots, k)
				return true
			end
		end
	end

	chat("Error: remove_card_from_table: No such card nr in table: " .. card.card_nr)
	return false
end

-- Place a @card on @table_slot, @facing up/down, assuming the slot is empty
-- Function have both Lua and OCaml counter part, because it's easiser to modify Lua state from Lua.
-- 
-- Defined through OCaml in reality.
--
-- @param card		card object
-- @param table_slot	int, > 0;
-- @param facing		string; "up" or "down"
function place_card_on_table(card_nr, table_slot, facing)
	if facing ~= "up" and facing ~= "down" then
		chat("Error: place_card_on_table: facing must be either 'up' or 'down'")
		return false
	end

	local card = get_card(card_nr)

	if (card == nil) then
		chat("Error: place_cad_on_table: found no card with nr " .. card_nr)
		return false
	end

	if table_slots[table_slot] ~= nil then
		chat("Error: place_cad_on_table: table slot " .. table_slot .. " is not empty");
		return false;
	end

	table.insert(table_slots, card)
end

-- Get next free player slot
function get_free_player_slot(player)
	local j = 1
	for i, slot in ipairs(player.slots) do
		if (slot == nil) then
			return i
		end
		j = j + 1
	end

	return {player.slots, j}
end

--- Place a @card in @slot (where slot is received from get_free_table/player_slot)
-- @param card		card object
-- @param slot		tuple like {table, index}
function place_card_in_slot(card, slot)
	local t = slot[1] 	-- table
	local k = slot[2] 	-- key
	t[k] = card
end

function new_overlay()
	return {cards = {}, __type = "overlay"}
end

function new_stack()
	return {cards = {}, __type = "stack"}
end

function place_card_on_player_slot(player, card, slot_nr)
end

function draw_card(deck)
	return table.remove(deck, 1)
end

-- Place a card in the players hand
-- Can do this manually with table.insert and update_hand
function place_card_on_hand(card, player)
end

function add_action(action)
	print("Action added")
end


-- If we're here, card does not belong to player, check table

for k, s in ipairs(table_slots) do
-- Slot is a card
if s.__type == "card" then
return {
	slot_type = "table_slot",
						slot_nr = k
}
-- Slot is a deck
elseif s.__type == "deck" then
cate slot location of @card
-- Return slot table, like {slot_type = "player_hand", player = p, slot_nr = 2}
function __locate_card(card)
	local location = {}
	local card_nr = card.card_nr
	-- Check for all players
	for k, p in ipairs(players) do

	-- Check hand
	for k2, c in ipairs(p.hand) do
		if c.card_nr == card_nr then
		return {
			slot_type = "player_hand",
								player = p,
								slot_nr = k2
		}
		end
	end

-- Check player slots
for k2, c in ipairs(p.slots) do
-- Slot is a card
if c.__type == "card" and c.card_nr == card_nr then
return {
	slot_type = "player_slot",
						player = p,
						slot_nr = k2
}
-- Slot is a deck
elseif c.__type == "deck" then
for k3, c2 in ipairs(c.cards) do
if c2.card_nr == card_nr then
return {
	slot_type = "player_slot",
						player = p,
						slot_nr = k3
}
end
end
-- Slot is an overlay/stack
else
for k3, c2 in ipairs(c) do
if c2.card_nr == card_nr then
return {
	slot_type = "player_slot",
						player = p,
						slot_nr = k2,
						index = k3
}
end
end
end
end
end

-- If we're here, card does not belong to player, check table

for k, s in ipairs(table_slots) do
-- Slot is a card
if s.__type == "card" and s.card_nr == card_nr then
return {
	slot_type = "table_slot",
						slot_nr = k
}
-- Slot is a deck
elseif s.__type == "deck" then
for k2, c in ipairs(s.cards) do
if c.card_nr == card_nr then
return {
	slot_type = "table_slot",
						slot_nr = k
}
end
end
-- Slot is an overlay/stack
else
for k2, c in ipairs(s) do
if c.card_nr == card_nr then
return {
	slot_type = "table_slot",
						slot_nr = k,
						index = k2
}
end
end
end
end

-- Should never be here
error("locate_card: did not find a card with card_nr " .. card_nr)

end
for k2, c in ipairs(s.cards) do
if c.card_nr == card_nr then
return {
	slot_type = "table_slot",
						slot_nr = k
}
end
end
-- Slot is an overlay/stack
else
for k2, c in ipairs(s) do
if c.card_nr == card_nr then
return {
	slot_type = "table_slot",
						slot_nr = k,
						index = k2
}
end
end
end
end

-- Should never be here
error("locate_card: did not find a card with card_nr " .. card_nr)

end

-- Roll dice. Only 6 values for now
-- Make sure math.seed is called before use (should happen before init)
function roll_dice(dice)
	dice.value = math.random(6)
end

--[[
	OO approach to API
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
function

function Action:new(a)
	a.action_id = #__actions + 1

	-- Validation
	if a.action_name ~= "play_card" or
	   a.action_name ~= "pick_card" then
		error("Action:new: action_name not supported: " .. a.action_name)
	end

	setmetatable(a, self)
	self.__index = self
	return a
end
