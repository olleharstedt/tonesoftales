-- Lua test file for Kasino
-- @since 2013-05-25

dofile("api.lua")

card1 = {title = "Kung", card_nr = 1, onpickup = function(player, deck) end, onplay = function () end }
card2 = {title = "Drottning", card_nr = 2, onpickup = function(player, deck) end }
card3 = {title = "Knekt", card_nr = 3, onpickup = function(player, deck) end }
card4 = {title = "Ess", card_nr = 4, onpickup = function(player, deck) end}

-- Array of card etc
deck1 = {name = "d1", id = 12, deck_nr = 1, cards = {}}

-- Construct standard deck
card_nr = 1
suits = {"spades", "hearts", "clubs", "diamonds"}
for _, suit in ipairs(suits) do
	for i = 1, 13 do
		card = {}
		card.value = i
		card.suit = suit
		card.title = suit .. " " .. i
		card.card_nr = card_nr; card_nr = card_nr + 1
		card.onpickup = function () end
		card.onplay = function () end
		table.insert(deck1.cards, card)
	end
end

-- Array of decks
decks = {deck1}

player1 = {name = "Olle", hand = {}, picked_cards = {}, points = 0}
player2 = {name = "Anton", hand = {}, picked_cards = {}, points = 0}

-- Array of players
players = {player1, player2}

-- NOT array, because we wan't indexes to point to slots, and shift them if anyone is removed.
table_slots = {deck1}

gameover = false
winner = nil
loser = nil

-- Return nr of cards on players hand
function cards_on_hand(player)
	table.getn(player.hands)
end

-- Filter inplace, that is, changes the in-table.
function  filter(t, predicate)
	local j = 1

	for i = 1,#t do
		local v = t[i]
		if predicate(v) then
		t[j] = v
		j = j + 1
		end
	end

	while t[j] ~= nil do
		t[j] = nil
		j = j + 1
	end

	return t
end

-- Set values and suits to standard deck
function set_values(deck)
	for _, card in pairs(deck.cards) do
		local title = card.title
		-- Set values
		if string.find(title, "Ace") ~= nil then
			card.value = 1
		elseif string.find(title, 'King') ~= nil then
			card.value = 13
		elseif string.find(title, 'Queen') ~= nil then
			card.value = 12
		elseif string.find(title, 'Jack') ~= nil then
			card.value = 11
		elseif string.find(title, "Ten") ~= nil then
			card.value = 10
		elseif string.find(title, "Nine") ~= nil then
			card.value = 9
		elseif string.find(title, "Eight") ~= nil then
			card.value = 8
		elseif string.find(title, "Seven") ~= nil then
			card.value = 7
		elseif string.find(title, "Six") ~= nil then
			card.value = 6
		elseif string.find(title, "Five") ~= nil then
			card.value = 5
		elseif string.find(title, "Four") ~= nil then
			card.value = 4
		elseif string.find(title, "Three") ~= nil then
			card.value = 3
		elseif string.find(title, "Two") ~= nil then
			card.value = 2
		end

		-- Set suits
		if string.find(title, "spades") ~= nil then
			card.suit = "spades"
		elseif string.find(title, "diamonds") ~= nil then
			card.suit = "diamonds"
		elseif string.find(title, "clubs") ~= nil then
			card.suit = "clubs"
		elseif string.find(title, "hearts") ~= nil then
			card.suit = "hearts"
		end
	end
end

-- Test onplay. Provided by user.
function onplay_all(player, card)
	-- filter(player.hand, function (c) return c.card_nr ~= card.card_nr end)
	-- local ts = get_next_free_table_slot()
	-- place_card_on_table(card.card_nr, ts, "up")
	remove_card_from_hand(player, card)

	-- Only put card on table if we did NOT pick up card(s)
	if not onplay_aux(card, false) then
		ts = get_free_table_slot()
		place_card_on_table(card, ts, "up")
	end
end

function onplay_aux(card, picked_a_card)
	-- First check if we can pick ONE card
	for k, table_card in pairs(table_slots) do
		if table_card.__type == "card" then
			if table_card.value == card.value then
				remove_card_from_table(table_card)
				table.insert(player.picked_cards, table_card)
				if not picked_a_card then table.insert(player.picked_cards, card) end	-- Only save this one time
				return onplay_aux(card, true)
			end
		end
	end

	-- Can we pick TWO cards?
	for k, table_card in pairs(table_slots) do
		for j, table_card2 in pairs(table_slots) do
			if (j ~= k) and table_card.__type == "card" and table_card2.__type == "card" then
				if table_card.value + table_card2.value == card.value then
					remove_card_from_table(table_card)
					remove_card_from_table(table_card2)
					table.insert(player.picked_cards, table_card)
					table.insert(player.picked_cards, table_card2)
					if not picked_a_card then table.insert(player.picked_cards, card) end	-- Only save this one time
					return onplay_aux(card, true)
				end
			end
		end
	end

	-- Pick THREE cards?
	for k, table_card in pairs(table_slots) do
		for j, table_card2 in pairs(table_slots) do
			for i, table_card3 in pairs(table_slots) do
				if (j ~= k) and (j ~= i) and (k ~= i) and table_card.__type == "card" and table_card2.__type == "card" and table_card3.__type == "card" then
					if table_card.value + table_card2.value + table_card3.value == card.value then
						remove_card_from_table(table_card)
						remove_card_from_table(table_card2)
						remove_card_from_table(table_card3)
						table.insert(player.picked_cards, table_card)
						table.insert(player.picked_cards, table_card2)
						table.insert(player.picked_cards, table_card3)
						if not picked_a_card then table.insert(player.picked_cards, card) end	-- Only save this one time
						return onplay_aux(card, true)
					end
				end
			end
		end
	end

	-- Pick FOUR cards?
	for k, table_card in pairs(table_slots) do
		for j, table_card2 in pairs(table_slots) do
			for i, table_card3 in pairs(table_slots) do
				for n, table_card4 in pairs(table_slots) do
					if (j ~= k) and (j ~= i) and (k ~= i) and (n ~= i) and (n ~= j) and (n ~= k)
						and table_card.__type == "card" and table_card2.__type == "card" 
						and table_card3.__type == "card"  and table_card3.__type == "card" then

						if table_card.value + table_card2.value + table_card3.value == card.value then
							remove_card_from_table(table_card)
							remove_card_from_table(table_card2)
							remove_card_from_table(table_card3)
							remove_card_from_table(table_card4)
							table.insert(player.picked_cards, table_card)
							table.insert(player.picked_cards, table_card2)
							table.insert(player.picked_cards, table_card3)
							table.insert(player.picked_cards, table_card4)
							if not picked_a_card then table.insert(player.picked_cards, card) end	-- Only save this one time
							return onplay_aux(card, true)
						end
					end
				end
			end
		end
	end

	return picked_a_card
end

-- Calculate points at end of game
function calc_points()

	-- Check last pick
	last_pick.points = last_pick.points + 1
	chat(last_pick.name .. " took the last cards")

	for i, card in ipairs(table_slots) do
		if card.__type == "card" then
			remove_card_from_table(card)
			table.insert(player.picked_cards, card)
		end
	end

	-- Points for most cards
	if #player1.picked_cards > #player2.picked_cards then
		player1.points = player1.points + 1
		chat(player1.name .. " had most cards")
	elseif #player1.picked_cards < #player2.picked_cards then
		player2.points = player2.points + 1
		chat(player2.name .. " had most cards")
	else
		chat("Both players had equal amounts of cards")
	end

	-- Points for spades
	p1_spades = 0
	for i, card in pairs(player1.picked_cards) do
		if card.suit == "spades" then
			p1_spades = p1_spades + 1
		end
	end
	if p1_spades > 6 then
		player1.points = player1.points + 2
		chat(player1.name .. " had most spades")
	else 
		player2.points = player2.points + 2
		chat(player2.name .. " had most spades")
	end

	-- Check ten of diamonds
	if find_card(player1.picked_cards, 10, "diamonds") then
		player1.points = player1.points + 2
		chat(player1.name .. " picked up ten of diamonds")
	else
		player2.points = player2.points + 2
		chat(player2.name .. " picked up ten of diamonds")
	end

	-- Check two of spades
	if find_card(player1.picked_cards, 2, "spades") then
		player1.points = player1.points + 1
		chat(player1.name .. " picked up two of spades")
	else
		player2.points = player2.points + 1
		chat(player2.name .. " picked up two of spades")
	end

	-- Check aces
	p1_aces = 0
	for i, card in pairs(player1.picked_cards) do
		if card.value == 1 then
			p1_aces = p1_aces + 1
			player1.points = player1.points + 1
		end
	end
	chat(player1.name .. " picked up " .. p1_aces .. " aces")
	p2_aces = 4 - p1_aces
	chat(player2.name .. " picked up " .. p2_aces .. " aces")
	player2.points = player2.points + p2_aces

	chat("Total points:\n" .. player1.name .. ": " .. player1.points .. "\n" .. player2.name .. ": " .. player2.points)

end

-- Look up card in table @t with @value and @suit
function find_card(t, value, suit)
	for i, card in ipairs(t) do
		if (card.value == value and card.suit == suit) then
			return card
		end
	end

	return nil
end

-- From OCaml, display in chat window
function log(str)
end

-- When played card, select lowest point to pick
-- @param player	Player that played card
-- @param card	Played card
function casino_choose_cards(player, card)
	-- get all cards in table slots (not deck)
	-- sort cards
	-- get card that is played
	-- iterate to pick 1 card (if any match)
	-- iterate to pick 2 card (start with lowest)
	-- iterate to pick 3, etc, while < nr of cards on table
	-- move cards to player slot
	-- if player picked all cards, make a "tabbe"
end

-- Tests

shuffle(deck1)
set_values(deck1)
print("cards in deck1 = " .. table.getn(deck1.cards))
print(deck1.cards[1].title)
print(deck1.cards[2].title)
print(deck1.cards[3].title)
print(deck1.cards[4].title)
card = get_card(1)
print(card.title)

for i = 0, 25 do
	card = table.remove(deck1.cards, 1)
	table.insert(player1.picked_cards, card)
end
for i = 0, 25 do
	card = table.remove(deck1.cards, 1)
	table.insert(player2.picked_cards, card)
end

last_pick = player1

ts = get_free_table_slot()
--__play_card(1, player1.hand[1].card_nr)
print(getn(table_slots))

calc_points()

-- player_pick_card(player1, deck1)
-- player_pick_card(player2, deck1)
-- player_pick_card(player1, deck1)
-- player_pick_card(player2, deck1)
