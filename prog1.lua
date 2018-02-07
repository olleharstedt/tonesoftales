-- Lua test 1, setup players, cards, events etc
-- Use dofile to load in Lua command prompt

-- OBS! Required
math.randomseed(os.time())

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

function dump(o)
	if type(o) == 'table' and isArray(o) then
		local s = '[\n'
		for k,v in pairs(o) do
			if type(k) ~= 'number' then k = '"'..k..'"' end
			s = s .. dump(v) .. ','
		end
		-- Strip last ,
		if string.len(s) > 2 then s = string.sub(s, 1, -2) end
		return s .. '\n] '
	elseif type(o) == 'table' then
		local s = '{\n'
		for k,v in pairs(o) do
			if type(k) ~= 'number' then k = '"'..k..'"' end
			s = s .. ''..k..': ' .. dump(v) .. ','
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

card1 = {title = "Kung", onpickup = function(player, deck) end }
card2 = {title = "Drottning", onpickup = function(player, deck) end }
card3 = {title = "Knekt", onpickup = function(player, deck) 
	-- This player is Marcus! Set gameover flag
	gameover = true
	loser = player
	print(player.name .. " is Marcus!")
end }
card4 = {title = "Ess", onpickup = function(player, deck) end}

-- 
deck1 = {name = "d1", id = 12, cards = {card1, card2, card3, card4}}

decks = {deck1}

player1 = {name = "Olle", hand = {}}
player2 = {name = "Anton", hand = {}}

players = {player1, player2}

gameover = false
winner = nil
loser = nil

-- Init function for game, setup players data etc
function init()
	-- E.g. shuffle
end

--[[
	Get deck with @deck_id from decks.
	Deck must been added to game.

	@param deck_id	int; id of deck, as of in db
	@return		deck if found; otherwise nil
]]--
function get_deck(deck_id) 
	
	for k, deck in pairs(decks) do
		if deck.id == deck_id then
			return deck
		end
	end

	return nil
end


--- Move @nr cards from top of @deck_id to @player_nr's hand
--
-- @param player_nr	0 < player_nr <= players
-- @param deck_id		int; id of deck, as of in db
-- @param nr		int; number of cards to draw
-- @param hand_nr		hand nr of player to put card in
-- @return bool		true if succeeded; false otherwise
function pick_card(player_nr, deck_id, nr)
	local player = players[player_nr]
	if (player == nil) then
		chat("Error: pick_card: Found no player with id " .. player_nr)
		return false
	end

	local deck = get_deck(deck_id)
	if (deck == nil) then
		chat("Error: pick_card: Found no deck with id " .. deck_id)
		return false
	end

	if (table.getn(deck.cards) < nr) then
		chat("Error: pick_card: Not enough cards in deck")
		return false
	end
	local card = table.remove(deck.cards, 1)

	card.onpickup(player, deck)

	table.insert(player.hand, card)

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

function shuffle(deck)
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

-- Check end conditions
function check_gameover()
end

-- From OCaml, display in chat window
function log(str)
end

-- @player picks up card at the top of @deck and put it in his/hers hand
function player_pick_card(player, deck) 

	-- Grab topcard from deck
	local topcard = table.remove(deck.cards, 1)

	-- Insert in players hand
	table.insert(player.hand, topcard)

	-- Run card pickup event
	topcard.onpickup(player, deck, cards)

end

-- Tests

shuffle(deck1)
print("cards in deck1 = " .. table.getn(deck1.cards))
print(deck1.cards[1].title)
print(deck1.cards[2].title)
print(deck1.cards[3].title)
print(deck1.cards[4].title)

pick_card(1, 12, 1)
pick_card(2, 12, 1)
pick_card(1, 12, 1)
pick_card(2, 12, 1)

-- player_pick_card(player1, deck1)
-- player_pick_card(player2, deck1)
-- player_pick_card(player1, deck1)
-- player_pick_card(player2, deck1)
