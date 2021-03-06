-- MySQL dump 10.13  Distrib 5.5.34, for debian-linux-gnu (x86_64)
--
-- Host: localhost    Database: d37433
-- ------------------------------------------------------
-- Server version	5.5.34-0ubuntu0.12.10.1

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Dumping data for table `ds_game`
--
-- WHERE:  id=30

LOCK TABLES `ds_game` WRITE;
/*!40000 ALTER TABLE `ds_game` DISABLE KEYS */;
INSERT INTO `ds_game` VALUES (30,'31','The classic game 31. The first player who have 31 or the highest numbers on his/hers hand when knocking wins. Press &amp;amp;amp;quot;Knock&amp;amp;amp;quot; to call the other players hands.','\naction3 = {\n  action_id = 3,\n  action_name = \"play_card\",\n  menu_text = \"Play card\",\n  players = players,\n  target = \"hand\",\n  target_ids = {1}\n}\n\n-- Action for switching open card on table\naction1 = {\n  action_id = 1,\n  action_name = \"callback\",\n  menu_text = \"Pick card\",\n  players = players,\n  target = \"table_slot\",\n  target_ids = {2},\n  callback = function(player, slot)\n    -- Check so that exactly one card is marked in hand\n    --[[\n    local marked_card = nil\n    local place\n    for k, c in ipairs(player.hand) do\n      if c.marked and marked_card == nil then\n        marked_card = c\n      	place = k\n      elseif c.marked then\n        chat(\"Mark only one card to switch\")\n        return\n      end\n    end\n    \n    if marked_card == nil then\n      chat(\"Mark a card to switch from your hand\")\n      return\n    end\n    --]]\n    \n    if drawn_card then return end\n    \n    -- Switch cards\n    move_card(slot[#slot], {slot_type = \"player_hand\", player = player}, function()  -- Callback in last animation call\n      local card = table.remove(slot, #slot)	-- Get top card from stack\n      table.insert(player.hand, card)\n      add_action(action3)\n      drawn_card = true\n  \n      -- Update\n      update_hand(player)\n      update_table()\n    end)\n    \n  end\n}\n\n-- Global variable, true if player took card from deck\ndrawn_card = false\n\n-- Pick up card from deck\naction2 = {\n  action_id = 2,\n  action_name = \"callback\",\n  menu_text = \"Pick card\",\n  players = players,\n  target = \"table_slot\",\n  target_ids = {1},\n  callback = function(player, slot)\n    local deck = slot\n    \n    if drawn_card then return end\n\n    -- Check so exactly one card is marked in hand\n    --[[\n    local marked_card = nil\n    local place\n    for k, c in ipairs(player.hand) do\n      if c.marked and marked_card == nil then\n        marked_card = c\n      	place = k\n      elseif c.marked then\n        chat(\"Mark only one card to switch\")\n        return\n      end\n    end\n    \n    if marked_card == nil then\n      chat(\"Mark a card to switch from your hand\")\n      return\n    end\n    --]]\n    \n    -- Draw card and put old on stack\n    move_card(deck1.cards[1], {slot_type = \"player_hand\", player = player}, function()\n      table.insert(player.hand, draw_card())\n      update_hand(player)\n      drawn_card = true\n        \n      -- Add action so player can play the forth card\n      chat(\"add_acion3\")\n      add_action(action3)\n      update_hands()\n    end)\n    --[[move_card(marked_card, {slot_type = \"table_slot\", slot_nr = 2}, function()\n      marked_card.facing = \"up\"\n      table.insert(table_slots[2], marked_card)	-- Put marked card on stack, face up\n      local drawn_card = table.remove(deck.cards, 1)\n      player.hand[place] = drawn_card\n  \n      -- Update\n      update_hand(player)\n      update_table()\n      end_turn()\n    end)\n    --]]\n    \n    \n  end\n}\n\nknock_button = {\n  gadget_id = 1,\n  type = \"button\",\n  text = \"Knock\",\n  players = players,\n  callback = function(player)\n    \n    if #player.hand == 4 then return end\n    \n    chat(player.name .. \" knocked!\")\n    \n    -- Calculate points for all players\n    for _, p in ipairs(players) do\n      chat(p.name .. \" got \" .. calc_points(p) .. \" points\")\n    end\n    \n    -- Put cards in slots\n    for _, p in ipairs(players) do\n      for k, c in ipairs(p.hand) do\n    	c.facing = \"up\"\n        p.slots[k] = c\n      end\n      p.hand = {}\n      update_hand(p)\n      update_player_slots(p)\n    end\n    \n    game_over()\n    \n  end\n}\n\n-- Return points for a player\nfunction calc_points(p)\n\n  local matches = {\n    hearts = 0,\n    spades = 0,\n    clubs = 0,\n    diamonds = 0\n  }\n  for _, c in ipairs(p.hand) do\n    matches[c.suit] = matches[c.suit] + 1\n  end\n  \n  log(dump(matches))\n  \n  local points = 0\n  local highest_value = 0\n  \n  for k, s in pairs(matches) do\n    log(k .. s)\n  	if s == 3 then\n      -- All cards in same colour\n      for _, c in ipairs(p.hand) do\n        points = points + c.value\n      end\n      break\n    elseif s == 2 then\n      -- Two cards in this colour\n      points = 0\n      for _, c in ipairs(p.hand) do\n        if c.suit == k then\n          points = points + c.value\n        end\n      end\n    else\n      -- Three different colours, pick highest card\n      for _, c in ipairs(p.hand) do\n        if c.value > highest_value then\n          highest_value = c.value\n        end\n      end\n    end\n  end\n  \n  --assert(points ~= 0)\n    \n  return (points > 0 and points > highest_value) and points or highest_value\n  \nend\n\n-- Initialization\nfunction init()\n  shuffle(deck1)\n  set_values(deck1)\n  \n  -- Marking setup\n  for _, p in ipairs(players) do\n    local slot_list = {}\n    table.insert(slot_list, {\n      slot_type = \"player_hand\",\n      players = {p}\n    })\n    p.slot_list = slot_list\n  end\n  \n  -- Set face cards to value 10\n  for _, card in ipairs(deck1.cards) do\n    if card.value == 11 or card.value == 12 or card.value == 13 then\n      card.value = 10\n    end\n  end\n  \n  -- Set ace to value 11\n  for _, card in ipairs(deck1.cards) do\n    if card.value == 1 then\n      card.value = 11\n    end\n  end\n  \n  -- Place deck and first card on table\n  table_slots[1] = deck1\n  local stack = {__type = \"stack\"}\n  local card = draw_card()\n  card.facing = \"up\"\n  table.insert(stack, card)\n  table_slots[2] = stack\n  update_table()\n  \n  -- Deal three cards to each player\n  for _, p in ipairs(players) do\n    for i=1, 3 do\n      local card = draw_card()\n      table.insert(p.hand, card)\n    end\n    update_hand(p)\n  end\n  \n  add_action(action1)\n  add_action(action2)\n  --add_action(action3)\n  add_gadget(knock_button)\n  \n  --update_hands()\n  \nend\n\nfunction draw_card()\n  return table.remove(deck1.cards, 1)\nend\n\nfunction update_hands()\n  for _, p in ipairs(players) do\n    update_hand(p)\n  end\nend',22,1,5,2,1,3,2,1,'function onpickup_all(player, deck)\nend','function onplay_all(player, card)\n  -- This should only be possible when play have 4 cards on hand\n  if #player.hand == 4 and drawn_card then\n    move_card(card, {slot_type = \"table_slot\", slot_nr = 2}, function()\n      card.facing = \"up\"\n      remove_card_from_hand(player, card)\n      table.insert(table_slots[2], card)\n      drawn_card = false\n      remove_action(action3)\n      update_table()\n      update_hands()\n      end_turn()\n    end)\n  end\nend','function onendturn(player)\nend','function onbeginturn(player)\n  --enable_marking(player.slot_list)\nend',1,1,0);
/*!40000 ALTER TABLE `ds_game` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2013-11-04 20:02:24
