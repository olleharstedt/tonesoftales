-- Test file for vändtia
-- @since 2013-06-21

-- Array of card etc
deck1 = {name = "Standard deck", id = 12, deck_nr = 1, cards = {}, __type = "deck"}

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
		card.__type = "card"
		table.insert(deck1.cards, card)
		table.insert(__cards, card)
	end
end

-- Array of decks
decks = {deck1}


player1 = {name = "Olle", hand = {, slots = {}}}
player2 = {name = "Anton", hand = {}, slots = {}}

table_slots = {}

-- Overlay of cards, as deck but visible
stack = {
	cards = {},
	__type = "stack"
}

-- Partial overlay, stack cards so value/suit is visible below
overlay = {
	cards = {},
	__type = "overlay"
}
