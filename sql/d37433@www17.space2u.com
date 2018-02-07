-- MySQL dump 10.13  Distrib 5.5.31, for debian-linux-gnu (i686)
--
-- Host: localhost    Database: d37433
-- ------------------------------------------------------
-- Server version	5.5.31-0ubuntu0.12.04.1

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
-- Table structure for table `ds_api`
--

DROP TABLE IF EXISTS `ds_api`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ds_api` (
  `name` varchar(100) NOT NULL DEFAULT '',
  `script` text NOT NULL,
  `active` tinyint(1) DEFAULT '1',
  `version` int(11) DEFAULT '1',
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `desc` varchar(500) NOT NULL,
  `signature` varchar(100) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ds_api`
--

LOCK TABLES `ds_api` WRITE;
/*!40000 ALTER TABLE `ds_api` DISABLE KEYS */;
INSERT INTO `ds_api` VALUES ('get_deck','function get_deck(deck_id) \n     \n      for k, deck in pairs(decks) do\n            if deck.id == deck_id then\n                  return deck\n            end \n      end \n\n      return nil \nend\n',1,1,1,'Return deck with <span class=param>deck_id</span>','get_deck(deck_id)'),('pick_card','\nfunction pick_card(player_nr, deck_id, nr)\n      local player = players[player_nr]\n      if (player == nil) then\n            chat(\"Error: pick_card: Found no player with id \" .. player_nr)\n            return false\n      end\n\n      local deck = get_deck(deck_id)\n      if (deck == nil) then\n            chat(\"Error: pick_card: Found no deck with id \" .. deck_id)\n            return false\n      end\n\n      if (table.getn(deck.cards) < nr) then\n            chat(\"Error: pick_card: Not enough cards in deck\")\n            return false\n      end\n      local card = table.remove(deck.cards, 1)\n\n      card.onpickup(player, deck)\n\n      table.insert(player.hand, card)\n\n      return true\nend\n',1,1,2,'Pick <span class=param>nr</span> of cards from <span class=param>deck_id</span> and put it in <span class=param>player_nr</span>`s hand','pick_card(player_nr, deck_id, nr)'),('shuffle','function shuffle(deck)\n      t = deck.cards\n      local n = #t\n\n      while n >= 2 do\n            -- n is now the last pertinent index\n            local k = math.random(n) -- 1 <= k <= n\n            -- Quick swap\n            t[n], t[k] = t[k], t[n]\n            n = n - 1 \n      end \n\n      deck.cards = t \n\n      return deck\nend\n',1,1,3,'Shuffle <span class=param>deck.','shuffle(deck)'),('place_deck','',1,1,4,'Place deck with <span class=param>deck_id</span> onto <span class=param>table_slot</span>, cards down.','place_deck(deck_id, table_slot)'),('add_action','',1,1,5,'Add action with name <span class=param>action_name</span> to any menu in the game.','add_action(target, target_id, action_name)'),('dump','\nfunction isArray(tbl)\n      local numKeys = 0\n      for _, _ in pairs(tbl) do\n          numKeys = numKeys+1\n        end   \n      local numIndices = 0\n    for _, _ in ipairs(tbl) do\n      numIndices = numIndices+1\n    end   \n  return numKeys == numIndices\nend\n\nfunction dump(o)\n      if type(o) == \'table\' and isArray(o) then\n            local s = \'[\\n\'\n            for k,v in pairs(o) do\n                  if type(k) ~= \'number\' then k = \'\"\'..k..\'\"\' end\n                  s = s .. dump(v) .. \',\'\n            end\n            -- Strip last ,\n            if string.len(s) > 2 then s = string.sub(s, 1, -2) end\n            return s .. \'\\n] \'\n      elseif type(o) == \'table\' then\n            local s = \'{\\n\'\n            for k,v in pairs(o) do\n                  if type(k) ~= \'number\' then k = \'\"\'..k..\'\"\' end\n                  s = s .. \'\'..k..\': \' .. dump(v) .. \',\'\n            end\n            -- Strip last ,\n            if string.len(s) > 2 then s = string.sub(s, 1, -2) end\n            return s .. \'\\n} \'\n      elseif type(o) == \'function\' then\n            return \'\"fn\"\'\n      else\n            if type(o) == \'string\' then o = \'\"\' .. o .. \'\"\' end\n            return tostring(o)\n      end\nend\n',1,1,6,'Return string representation of <span class=param>table</span>','dump(table)'),('game_over','',1,1,7,'Ends the game. No game actions are possible after this. Chat is still active.','game_over()');
/*!40000 ALTER TABLE `ds_api` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2013-05-21 17:16:10
