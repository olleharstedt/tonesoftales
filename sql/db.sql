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
-- Table structure for table `blog`
--

DROP TABLE IF EXISTS `blog`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `blog` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `blog` text NOT NULL,
  `youtube_link` varchar(99) DEFAULT NULL,
  `datetime` datetime NOT NULL,
  `title` varchar(100) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `blog`
--

LOCK TABLES `blog` WRITE;
/*!40000 ALTER TABLE `blog` DISABLE KEYS */;
INSERT INTO `blog` VALUES (1,'This is the test text, updated5','www.youtube.com/bla','0000-00-00 00:00:00','First blog entry'),(2,'This is a second blog text. Bla bla bla bla bla.','','0000-00-00 00:00:00','Second blog entry!'),(3,'This is t','www.youtube.com/bla','2012-11-15 20:16:13','First blog entry!'),(4,'This is t blaha','www.youtube.com/bla','2012-11-15 20:16:40','First blog entry!'),(5,'                  No content?\r\n                  ','asd','2012-11-17 19:04:57','No title');
/*!40000 ALTER TABLE `blog` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `comment`
--

DROP TABLE IF EXISTS `comment`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `comment` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `blog_id` int(10) unsigned NOT NULL,
  `comment` varchar(255) NOT NULL,
  `datetime` datetime NOT NULL,
  `name` varchar(200) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `blog_id` (`blog_id`),
  CONSTRAINT `comment_ibfk_1` FOREIGN KEY (`blog_id`) REFERENCES `blog` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `comment`
--

LOCK TABLES `comment` WRITE;
/*!40000 ALTER TABLE `comment` DISABLE KEYS */;
INSERT INTO `comment` VALUES (1,1,'Very good blog!','0000-00-00 00:00:00','Olle'),(2,1,'First comment','0000-00-00 00:00:00','Olle'),(3,1,'Second comment','0000-00-00 00:00:00','Olle'),(4,1,'rtrtr','0000-00-00 00:00:00','re'),(5,1,'hey','0000-00-00 00:00:00','Olle'),(6,1,'hey','2012-11-09 17:27:24','Olle'),(7,1,'hey2','2012-11-09 17:27:42','Olle'),(8,5,'comm','2012-11-17 19:05:59','asd');
/*!40000 ALTER TABLE `comment` ENABLE KEYS */;
UNLOCK TABLES;

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
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ds_api`
--

LOCK TABLES `ds_api` WRITE;
/*!40000 ALTER TABLE `ds_api` DISABLE KEYS */;
INSERT INTO `ds_api` VALUES ('get_deck','function get_deck(deck_id) \n     \n      for k, deck in pairs(decks) do\n            if deck.id == deck_id then\n                  return deck\n            end \n      end \n\n      return nil \nend\n',1,1,1,'Return deck with <span class=param>deck_id</span>','get_deck(deck_id)'),('pick_card','\nfunction pick_card(player_nr, deck_id, nr)\n      local player = players[player_nr]\n      if (player == nil) then\n            chat(\"Error: pick_card: Found no player with id \" .. player_nr)\n            return false\n      end\n\n      local deck = get_deck(deck_id)\n      if (deck == nil) then\n            chat(\"Error: pick_card: Found no deck with id \" .. deck_id)\n            return false\n      end\n\n      if (table.getn(deck.cards) < nr) then\n            chat(\"Error: pick_card: Not enough cards in deck\")\n            return false\n      end\n      local card = table.remove(deck.cards, 1)\n\n      card.onpickup(player, deck)\n\n      table.insert(player.hand, card)\n\n      return true\nend\n',1,1,2,'Pick <span class=param>nr</span> of cards from <span class=param>deck_id</span> and put it in <span class=param>player_nr</span>`s hand','pick_card(player_nr, deck_id, nr)'),('shuffle','function shuffle(deck)\n      t = deck.cards\n      local n = #t\n\n      while n >= 2 do\n            -- n is now the last pertinent index\n            local k = math.random(n) -- 1 <= k <= n\n            -- Quick swap\n            t[n], t[k] = t[k], t[n]\n            n = n - 1 \n      end \n\n      deck.cards = t \n\n      return deck\nend\n',1,1,3,'Shuffle <span class=param>deck.','shuffle(deck)'),('place_deck','',1,1,4,'Place deck with <span class=param>deck_id</span> onto <span class=param>table_slot</span>, cards down.','place_deck(deck_id, table_slot)'),('add_action','',1,1,5,'Add action with name <span class=param>action_name</span> to any menu in the game.','add_action(target, target_id, action_name)'),('dump','\nfunction isArray(tbl)\n      local numKeys = 0\n      for _, _ in pairs(tbl) do\n          numKeys = numKeys+1\n        end   \n      local numIndices = 0\n    for _, _ in ipairs(tbl) do\n      numIndices = numIndices+1\n    end   \n  return numKeys == numIndices\nend\n\nfunction dump(o)\n      if type(o) == \'table\' and isArray(o) then\n            local s = \'[\\n\'\n            for k,v in pairs(o) do\n                  if type(k) ~= \'number\' then k = \'\"\'..k..\'\"\' end\n                  s = s .. dump(v) .. \',\'\n            end\n            -- Strip last ,\n            if string.len(s) > 2 then s = string.sub(s, 1, -2) end\n            return s .. \'\\n] \'\n      elseif type(o) == \'table\' then\n            local s = \'{\\n\'\n            for k,v in pairs(o) do\n                  if type(k) ~= \'number\' then k = \'\"\'..k..\'\"\' end\n                  s = s .. \'\'..k..\': \' .. dump(v) .. \',\'\n            end\n            -- Strip last ,\n            if string.len(s) > 2 then s = string.sub(s, 1, -2) end\n            return s .. \'\\n} \'\n      elseif type(o) == \'function\' then\n            return \'\"fn\"\'\n      else\n            if type(o) == \'string\' then o = \'\"\' .. o .. \'\"\' end\n            return tostring(o)\n      end\nend\n',1,1,6,'Return string representation of <span class=param>table</span>','dump(table)'),('game_over','',1,1,7,'Ends the game. No game actions are possible after this. Chat is still active.','game_over()'),('getn','',1,1,8,'Same as table.getn, return length of <span class=param>table</span>.','getn(table)');
/*!40000 ALTER TABLE `ds_api` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ds_api_param`
--

DROP TABLE IF EXISTS `ds_api_param`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ds_api_param` (
  `api_id` int(10) NOT NULL DEFAULT '0',
  `name` varchar(100) NOT NULL,
  `type` varchar(100) NOT NULL,
  `desc` varchar(500) NOT NULL,
  UNIQUE KEY `index1` (`api_id`,`name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ds_api_param`
--

LOCK TABLES `ds_api_param` WRITE;
/*!40000 ALTER TABLE `ds_api_param` DISABLE KEYS */;
INSERT INTO `ds_api_param` VALUES (1,'deck_id','int','Id of deck.'),(2,'deck_id','int',''),(2,'nr','int','number of cards to pick.'),(2,'player_nr','int','nr of player to put card in.'),(3,'deck','deck','(use get_deck to get deck from a deck id)'),(4,'deck_id','int','id of deck. Deck must have been added to game.'),(4,'table_slot','int','id of slot, ranging from 1 to number of total slots.'),(5,'action_name','string','name of action. Supported actions are \"pick_card\".'),(5,'target','string','target kind. Supported kinds are \"deck\".'),(5,'target_id','int','id of target. If target kind is \"deck\", target_id would correspond to deck_id.'),(6,'table','table','any table'),(8,'table','table','any array-like table (like {1, 2, 3} or {\"a\", \"b\", \"c\"})');
/*!40000 ALTER TABLE `ds_api_param` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ds_card`
--

DROP TABLE IF EXISTS `ds_card`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ds_card` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `text` text NOT NULL,
  `img` varchar(100) DEFAULT NULL,
  `sound` varchar(100) DEFAULT NULL,
  `script` text,
  `user_id` int(10) unsigned DEFAULT NULL,
  `title` varchar(100) NOT NULL,
  `dir` varchar(100) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uc_title` (`user_id`,`title`),
  CONSTRAINT `user_fk` FOREIGN KEY (`user_id`) REFERENCES `ds_user` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=32 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ds_card`
--

LOCK TABLES `ds_card` WRITE;
/*!40000 ALTER TABLE `ds_card` DISABLE KEYS */;
INSERT INTO `ds_card` VALUES (17,'You enter the room','','','',NULL,'1',''),(18,'You enter the room.','','','',20,'2','anders'),(19,'This is another test card with a lot of information.','spelare.jpg','','',20,'3','anders'),(20,'Bla bla bla','','','',20,'4','anders'),(21,'card','absolutely_nothing_road_sign_lg.jpg','','',20,'5','anders'),(22,'a card, a card 2','spelare.jpg','',NULL,20,'dfg','anders'),(23,'','queenofspades.jpg','',NULL,20,'Queen of spades','anders'),(24,'','kingofspades.jpg','',NULL,20,'King of spades','anders'),(25,'','knightofspades.jpg','',NULL,20,'Knight of spades','anders'),(26,'','tenofspades.png','',NULL,20,'Ten of spades','anders'),(27,'','nineofspades.jpg','',NULL,20,'Nine of spades','anders'),(28,'test','Baby Seal 3..jpg','',NULL,20,'test',''),(29,'','babyseal.jpg','',NULL,20,'seal',''),(30,'','Baby Seal..jpg','',NULL,20,'seal2','');
/*!40000 ALTER TABLE `ds_card` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ds_card_has_script`
--

DROP TABLE IF EXISTS `ds_card_has_script`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ds_card_has_script` (
  `game_id` int(10) unsigned NOT NULL DEFAULT '0',
  `card_id` int(10) unsigned NOT NULL DEFAULT '0',
  `onpickup` text,
  `onplay` text,
  PRIMARY KEY (`game_id`,`card_id`),
  KEY `card_id` (`card_id`),
  CONSTRAINT `ds_card_has_script_ibfk_1` FOREIGN KEY (`game_id`) REFERENCES `ds_game` (`id`),
  CONSTRAINT `ds_card_has_script_ibfk_2` FOREIGN KEY (`card_id`) REFERENCES `ds_card` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ds_card_has_script`
--

LOCK TABLES `ds_card_has_script` WRITE;
/*!40000 ALTER TABLE `ds_card_has_script` DISABLE KEYS */;
INSERT INTO `ds_card_has_script` VALUES (1,18,'function(player, deck)\n	local i = 10\n  	local j = 20\nend',NULL),(1,21,'function(player, deck)\n  	local n = 1.23\nend',NULL),(18,25,'function(player, deck)\n  chat(player.name .. \" is Markus!\")\n  game_over()\nend',NULL);
/*!40000 ALTER TABLE `ds_card_has_script` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ds_common_script`
--

DROP TABLE IF EXISTS `ds_common_script`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ds_common_script` (
  `function_name` varchar(100) NOT NULL,
  `script` text NOT NULL,
  `active` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`function_name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ds_common_script`
--

LOCK TABLES `ds_common_script` WRITE;
/*!40000 ALTER TABLE `ds_common_script` DISABLE KEYS */;
/*!40000 ALTER TABLE `ds_common_script` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ds_deck`
--

DROP TABLE IF EXISTS `ds_deck`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ds_deck` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  `user_id` int(10) unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name_unasd` (`name`,`user_id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `ds_deck_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `ds_user` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ds_deck`
--

LOCK TABLES `ds_deck` WRITE;
/*!40000 ALTER TABLE `ds_deck` DISABLE KEYS */;
INSERT INTO `ds_deck` VALUES (8,'d1',20),(9,'d2',20),(10,'d3',20),(11,'d5',20),(12,'Standard deck',20);
/*!40000 ALTER TABLE `ds_deck` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ds_deck_card`
--

DROP TABLE IF EXISTS `ds_deck_card`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ds_deck_card` (
  `card_id` int(10) unsigned NOT NULL,
  `deck_id` int(10) unsigned NOT NULL,
  `nr` int(10) unsigned NOT NULL,
  PRIMARY KEY (`card_id`,`deck_id`),
  KEY `deck_id` (`deck_id`),
  CONSTRAINT `ds_deck_card_ibfk_1` FOREIGN KEY (`card_id`) REFERENCES `ds_card` (`id`),
  CONSTRAINT `ds_deck_card_ibfk_2` FOREIGN KEY (`deck_id`) REFERENCES `ds_deck` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ds_deck_card`
--

LOCK TABLES `ds_deck_card` WRITE;
/*!40000 ALTER TABLE `ds_deck_card` DISABLE KEYS */;
INSERT INTO `ds_deck_card` VALUES (18,8,5),(18,11,3),(19,8,10),(20,8,3),(20,9,2),(21,10,5),(22,11,1),(23,12,1),(24,12,1),(25,12,1),(26,12,1),(27,12,1),(28,8,1),(29,8,1);
/*!40000 ALTER TABLE `ds_deck_card` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ds_function_script`
--

DROP TABLE IF EXISTS `ds_function_script`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ds_function_script` (
  `name` varchar(100) NOT NULL,
  `script` text NOT NULL,
  PRIMARY KEY (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ds_function_script`
--

LOCK TABLES `ds_function_script` WRITE;
/*!40000 ALTER TABLE `ds_function_script` DISABLE KEYS */;
INSERT INTO `ds_function_script` VALUES ('shuffle','function shuffle(deck)\n	local tmp_deck = {}\n\n	-- Copy deck\n	for k,v in pairs(deck) do\n		tmp_deck[k] = v\n	end\n	tmp_deck.cards = {}	-- Remove cards\n\n	while table.getn(deck.cards) > 0 do\n		local r = math.random(1, table.getn(deck.cards))\n		-- Insert random card into tmp deck\n		table.insert(tmp_deck.cards, table.remove(deck.cards, r))\n		print(table.getn(tmp_deck.cards))\n	end\n	return tmp_deck\nend');
/*!40000 ALTER TABLE `ds_function_script` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ds_game`
--

DROP TABLE IF EXISTS `ds_game`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ds_game` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(100) DEFAULT NULL,
  `description` varchar(1000) DEFAULT NULL,
  `init_script` text CHARACTER SET latin1,
  `user_id` int(10) unsigned DEFAULT NULL,
  `public` tinyint(1) DEFAULT NULL,
  `max_players` int(11) NOT NULL,
  `min_players` int(11) NOT NULL,
  `hands` int(11) DEFAULT '1',
  `player_slots` int(11) DEFAULT '0',
  `table_slots` int(11) DEFAULT '1',
  `tables` int(11) DEFAULT '1',
  PRIMARY KEY (`id`),
  UNIQUE KEY `user_id` (`user_id`,`name`),
  CONSTRAINT `ds_game_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `ds_user` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=19 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ds_game`
--

LOCK TABLES `ds_game` WRITE;
/*!40000 ALTER TABLE `ds_game` DISABLE KEYS */;
INSERT INTO `ds_game` VALUES (1,'game1','asd','',20,0,4,5,1,0,2,1),(2,'Markus','Den som f?r Markus f?rlorar.','',20,0,10,2,1,0,2,1),(3,'Markus2','Test ???!','',20,0,2,1,1,0,2,1),(4,'Markus3','','',20,0,2,3,1,0,2,1),(5,'df','','',20,0,5,4,1,0,2,1),(6,'asd','','',20,0,3,2,1,0,2,1),(7,'äö','äö',NULL,NULL,NULL,0,0,1,0,2,1),(9,'asdrt','','',20,0,43,3,1,0,2,1),(10,'asdeeew','','',20,0,433,3,1,0,2,1),(12,'asdeeew5','','',20,0,433,3,1,0,2,1),(13,'iuy','','',20,0,6,5,1,0,2,1),(14,'iuy3','åäö','',20,0,6,5,1,0,2,1),(15,'asd5','öåä','',20,0,433,3,1,0,2,1),(16,'game2','','',20,1,1,1,1,0,2,1),(17,'game3','','',20,1,2,1,1,0,2,1),(18,'Markus4','','function init()\n  place_deck(12, 1)\n  add_action(\'deck\', 12, \'pick_card\')\n  shuffle(get_deck(12))\n  log(\"starting game!\")\n  chat(\"welcome to the game\")\nend',20,1,8,2,1,1,2,1);
/*!40000 ALTER TABLE `ds_game` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ds_game_has_deck`
--

DROP TABLE IF EXISTS `ds_game_has_deck`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ds_game_has_deck` (
  `game_id` int(10) unsigned DEFAULT NULL,
  `deck_id` int(10) unsigned DEFAULT NULL,
  `nr` int(11) DEFAULT '1',
  UNIQUE KEY `deck_id` (`deck_id`,`game_id`),
  KEY `game_id` (`game_id`),
  CONSTRAINT `ds_game_has_deck_ibfk_1` FOREIGN KEY (`game_id`) REFERENCES `ds_game` (`id`),
  CONSTRAINT `ds_game_has_deck_ibfk_2` FOREIGN KEY (`deck_id`) REFERENCES `ds_deck` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ds_game_has_deck`
--

LOCK TABLES `ds_game_has_deck` WRITE;
/*!40000 ALTER TABLE `ds_game_has_deck` DISABLE KEYS */;
INSERT INTO `ds_game_has_deck` VALUES (1,11,1),(1,10,1),(18,12,1);
/*!40000 ALTER TABLE `ds_game_has_deck` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ds_game_session`
--

DROP TABLE IF EXISTS `ds_game_session`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ds_game_session` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `comment` varchar(500) DEFAULT NULL,
  `password` varchar(100) DEFAULT NULL,
  `user_id` int(10) unsigned DEFAULT NULL,
  `public` tinyint(1) DEFAULT '1',
  `port` int(11) NOT NULL,
  `started` datetime DEFAULT '0000-00-00 00:00:00',
  `ended` datetime DEFAULT '0000-00-00 00:00:00',
  `created` datetime NOT NULL,
  `game_id` int(10) unsigned DEFAULT NULL,
  `debug` tinyint(1) DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `game_id` (`game_id`),
  KEY `fk1` (`user_id`),
  CONSTRAINT `ds_game_session_ibfk_2` FOREIGN KEY (`game_id`) REFERENCES `ds_game` (`id`),
  CONSTRAINT `fk1` FOREIGN KEY (`user_id`) REFERENCES `ds_user` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=531 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ds_game_session`
--

LOCK TABLES `ds_game_session` WRITE;
/*!40000 ALTER TABLE `ds_game_session` DISABLE KEYS */;
INSERT INTO `ds_game_session` VALUES (224,'','',20,1,8081,'0000-00-00 00:00:00','2013-04-09 14:03:18','2013-04-09 14:03:15',1,0),(225,'','',20,1,8082,'0000-00-00 00:00:00','2013-04-09 14:03:32','2013-04-09 14:03:29',1,0),(226,'','',20,1,8083,'0000-00-00 00:00:00','2013-04-09 14:09:17','2013-04-09 14:09:14',1,0),(227,'','',20,1,8084,'0000-00-00 00:00:00','2013-04-09 14:10:00','2013-04-09 14:09:57',1,0),(228,'','',20,1,8085,'0000-00-00 00:00:00','2013-04-09 14:11:08','2013-04-09 14:10:46',1,0),(229,'','',20,1,8086,'0000-00-00 00:00:00','2013-04-09 14:22:24','2013-04-09 14:22:21',1,0),(230,'','',20,1,8087,'2013-04-09 14:22:44','0000-00-00 00:00:00','2013-04-09 14:22:42',1,0),(231,'','',20,1,8088,'2013-04-09 15:11:48','2013-04-09 15:11:49','2013-04-09 15:11:46',1,0),(232,'','',20,1,8089,'2013-04-09 15:12:17','2013-04-09 15:12:18','2013-04-09 15:12:13',1,0),(233,'','',20,1,8090,'0000-00-00 00:00:00','2013-04-09 15:18:16','2013-04-09 15:14:56',1,0),(234,'','',20,1,8091,'2013-04-09 15:22:26','0000-00-00 00:00:00','2013-04-09 15:22:06',1,0),(235,'','',20,1,8092,'2013-05-01 15:56:58','2013-05-01 16:00:32','2013-05-01 15:56:28',1,1),(236,'','',20,1,8093,'2013-05-01 16:28:18','2013-05-01 16:32:19','2013-05-01 16:28:16',1,1),(237,'','',20,1,8094,'2013-05-01 16:32:23','2013-05-01 16:32:27','2013-05-01 16:32:22',1,1),(238,'','',20,1,8095,'2013-05-01 16:32:39','2013-05-01 16:35:46','2013-05-01 16:32:30',1,1),(239,'','',20,1,8096,'2013-05-01 16:35:01','2013-05-01 16:35:07','2013-05-01 16:34:56',1,1),(240,'','',20,1,8097,'2013-05-01 16:35:11','2013-05-01 16:35:42','2013-05-01 16:35:09',1,1),(241,'','',20,1,8098,'2013-05-01 16:35:51','2013-05-01 16:35:58','2013-05-01 16:35:44',1,1),(242,'','',20,1,8099,'2013-05-01 16:40:11','2013-05-01 16:40:19','2013-05-01 16:40:09',1,1),(243,'','',20,1,8100,'2013-05-01 16:40:21','2013-05-01 16:40:45','2013-05-01 16:40:20',1,1),(244,'','',20,1,8101,'2013-05-01 16:40:48','2013-05-01 16:41:03','2013-05-01 16:40:46',1,1),(245,'','',20,1,8102,'2013-05-01 16:41:12','2013-05-01 16:41:25','2013-05-01 16:41:05',1,1),(246,'','',20,1,8103,'2013-05-01 16:44:46','2013-05-01 16:45:23','2013-05-01 16:44:37',1,1),(247,'','',20,1,8104,'2013-05-01 16:49:32','2013-05-01 16:49:34','2013-05-01 16:49:30',1,1),(248,'','',20,1,8105,'2013-05-01 16:49:38','2013-05-01 16:49:50','2013-05-01 16:49:36',1,1),(249,'','',20,1,8106,'2013-05-01 16:50:04','0000-00-00 00:00:00','2013-05-01 16:49:52',1,1),(250,'','',20,1,8107,'2013-05-01 17:01:15','0000-00-00 00:00:00','2013-05-01 17:01:00',1,1),(251,'','',20,1,8108,'2013-05-01 17:10:27','2013-05-01 17:12:17','2013-05-01 17:10:15',1,1),(252,'','',20,1,8109,'2013-05-01 17:12:36','0000-00-00 00:00:00','2013-05-01 17:12:19',1,1),(253,'','',20,1,8110,'2013-05-01 17:21:26','2013-05-01 17:21:37','2013-05-01 17:21:23',1,1),(254,'','',20,1,8111,'2013-05-01 17:21:46','2013-05-01 17:25:17','2013-05-01 17:21:39',1,1),(255,'','',20,1,8112,'2013-05-01 17:25:46','2013-05-01 17:26:29','2013-05-01 17:25:33',1,1),(256,'','',20,1,8113,'2013-05-01 17:26:38','2013-05-01 17:27:53','2013-05-01 17:26:31',1,1),(257,'','',20,1,8114,'2013-05-01 17:28:35','2013-05-01 17:28:16','2013-05-01 17:27:57',1,0),(258,'','',20,1,8115,'2013-05-01 17:35:25','2013-05-01 17:36:55','2013-05-01 17:35:14',1,0),(259,'','',20,1,8116,'2013-05-01 17:37:07','2013-05-01 17:38:06','2013-05-01 17:37:05',1,0),(260,'','',20,1,8117,'2013-05-01 17:38:43','2013-05-01 17:40:59','2013-05-01 17:38:10',1,0),(261,'','',20,1,8118,'2013-05-01 17:41:15','2013-05-01 17:42:02','2013-05-01 17:41:07',1,0),(262,'','',20,1,8119,'2013-05-01 17:42:12','2013-05-01 17:42:22','2013-05-01 17:42:04',1,0),(263,'','',20,1,8120,'0000-00-00 00:00:00','2013-05-01 17:43:21','2013-05-01 17:42:24',1,0),(264,'','',20,1,8121,'0000-00-00 00:00:00','0000-00-00 00:00:00','2013-05-01 17:43:42',1,0),(265,'','',20,1,8122,'2013-05-01 17:44:33','0000-00-00 00:00:00','2013-05-01 17:44:30',1,0),(266,'','',20,1,8123,'2013-05-01 18:16:50','2013-05-01 18:16:56','2013-05-01 18:16:48',1,0),(267,'','',20,1,8124,'0000-00-00 00:00:00','0000-00-00 00:00:00','2013-05-01 18:16:57',1,0),(268,'','',20,1,8125,'2013-05-01 18:21:19','2013-05-01 18:23:44','2013-05-01 18:18:27',1,0),(269,'','',20,1,8126,'0000-00-00 00:00:00','2013-05-01 18:24:40','2013-05-01 18:23:55',1,0),(270,'','',20,1,8127,'2013-05-01 18:25:57','2013-05-01 18:26:43','2013-05-01 18:25:40',1,1),(271,'','',20,1,8128,'2013-05-01 18:30:47','2013-05-01 18:31:13','2013-05-01 18:30:45',1,1),(272,'','',20,1,8129,'2013-05-01 18:31:16','2013-05-01 18:31:52','2013-05-01 18:31:14',1,1),(273,'','',20,1,8130,'2013-05-01 18:31:55','2013-05-01 18:32:06','2013-05-01 18:31:53',1,1),(274,'','',20,1,8131,'2013-05-01 18:32:18','2013-05-01 18:33:04','2013-05-01 18:32:07',1,1),(275,'','',20,1,8132,'2013-05-01 18:34:19','2013-05-01 18:34:28','2013-05-01 18:34:17',1,1),(276,'','',20,1,8133,'2013-05-01 18:34:37','2013-05-01 18:34:55','2013-05-01 18:34:29',1,1),(277,'','',20,1,8134,'2013-05-01 19:23:00','2013-05-01 19:23:14','2013-05-01 19:22:53',1,1),(278,'','',20,1,8135,'2013-05-01 19:23:29','2013-05-01 19:24:08','2013-05-01 19:23:17',1,1),(279,'','',20,1,8136,'2013-05-01 19:25:39','0000-00-00 00:00:00','2013-05-01 19:25:32',1,1),(280,'','',20,1,8137,'2013-05-01 20:16:48','0000-00-00 00:00:00','2013-05-01 20:16:47',18,0),(281,'','',20,1,8138,'2013-05-01 20:48:50','2013-05-01 20:50:42','2013-05-01 20:48:48',18,0),(282,'','',20,1,8139,'2013-05-01 20:50:45','2013-05-01 20:54:41','2013-05-01 20:50:44',18,0),(283,'','',20,1,8140,'2013-05-01 20:54:56','2013-05-01 20:56:14','2013-05-01 20:54:51',18,0),(284,'','',20,1,8141,'2013-05-01 20:56:23','2013-05-01 20:57:00','2013-05-01 20:56:22',18,0),(285,'','',20,1,8142,'2013-05-01 20:57:09','2013-05-01 20:57:11','2013-05-01 20:57:07',18,0),(286,'','',20,1,8143,'2013-05-01 20:57:23','2013-05-01 20:57:25','2013-05-01 20:57:21',18,0),(287,'','',20,1,8144,'2013-05-01 21:00:42','2013-05-01 21:04:37','2013-05-01 21:00:41',18,0),(288,'','',20,1,8145,'2013-05-01 21:04:45','2013-05-01 21:05:48','2013-05-01 21:04:44',18,0),(289,'','',20,1,8146,'2013-05-01 21:05:56','2013-05-01 21:10:19','2013-05-01 21:05:53',18,0),(290,'','',20,1,8147,'2013-05-01 21:11:19','2013-05-01 21:11:23','2013-05-01 21:11:17',18,0),(291,'','',20,1,8148,'2013-05-01 21:11:47','2013-05-01 21:13:28','2013-05-01 21:11:39',18,0),(292,'','',20,1,8149,'2013-05-01 21:13:36','2013-05-01 21:13:58','2013-05-01 21:13:34',18,0),(293,'','',20,1,8150,'2013-05-01 21:14:01','2013-05-01 21:15:06','2013-05-01 21:13:59',18,0),(294,'','',20,1,8151,'2013-05-01 21:15:53','2013-05-01 21:16:01','2013-05-01 21:15:08',18,0),(295,'','',20,1,8152,'2013-05-01 21:16:06','2013-05-01 21:16:13','2013-05-01 21:16:04',18,0),(296,'','',20,1,8153,'2013-05-01 21:16:25','0000-00-00 00:00:00','2013-05-01 21:16:13',18,0),(297,'','',20,1,8154,'2013-05-03 15:32:28','2013-05-03 15:32:50','2013-05-03 15:32:26',18,0),(298,'','',20,1,8155,'2013-05-03 15:32:55','2013-05-03 15:33:08','2013-05-03 15:32:53',18,1),(299,'','',20,1,8156,'2013-05-03 15:33:12','2013-05-03 15:34:03','2013-05-03 15:33:09',18,1),(300,'','',20,1,8157,'2013-05-03 15:34:14','2013-05-03 15:34:28','2013-05-03 15:34:12',18,1),(301,'','',20,1,8158,'2013-05-03 15:34:31','2013-05-03 15:35:10','2013-05-03 15:34:29',18,1),(302,'','',20,1,8159,'2013-05-03 15:35:13','2013-05-03 15:35:17','2013-05-03 15:35:11',18,1),(303,'','',20,1,8160,'2013-05-03 15:35:21','2013-05-03 15:35:46','2013-05-03 15:35:18',18,1),(304,'','',20,1,8161,'2013-05-03 15:35:57','2013-05-03 15:36:06','2013-05-03 15:35:55',18,1),(305,'','',20,1,8162,'2013-05-03 15:36:19','0000-00-00 00:00:00','2013-05-03 15:36:16',18,1),(306,'','',20,1,8163,'2013-05-03 15:49:58','2013-05-03 15:50:38','2013-05-03 15:49:56',18,1),(307,'','',20,1,8164,'2013-05-03 15:50:52','2013-05-03 15:52:40','2013-05-03 15:50:49',18,1),(308,'','',20,1,8165,'2013-05-03 18:51:49','2013-05-03 18:55:42','2013-05-03 18:51:45',18,1),(309,'','',20,1,8166,'2013-05-03 18:55:48','2013-05-03 18:55:51','2013-05-03 18:55:45',18,0),(310,'','',20,1,8167,'2013-05-03 19:07:39','2013-05-03 19:08:06','2013-05-03 19:07:37',18,0),(311,'','',20,1,8168,'2013-05-03 19:08:09','2013-05-03 19:08:57','2013-05-03 19:08:07',18,0),(312,'','',20,1,8169,'2013-05-03 19:09:11','2013-05-03 19:09:27','2013-05-03 19:09:09',18,0),(313,'','',20,1,8170,'0000-00-00 00:00:00','0000-00-00 00:00:00','2013-05-03 19:10:32',18,0),(314,'','',20,1,8171,'0000-00-00 00:00:00','0000-00-00 00:00:00','2013-05-03 19:26:13',18,0),(315,'','',20,1,8172,'0000-00-00 00:00:00','0000-00-00 00:00:00','2013-05-03 19:26:21',18,0),(316,'','',20,1,8173,'2013-05-03 19:26:39','2013-05-03 19:28:35','2013-05-03 19:26:36',18,0),(317,'','',20,1,8174,'2013-05-03 19:28:37','0000-00-00 00:00:00','2013-05-03 19:28:35',18,0),(318,'','',20,1,8175,'2013-05-03 19:34:15','2013-05-03 19:34:34','2013-05-03 19:34:14',18,0),(319,'','',20,1,8176,'2013-05-03 19:34:36','2013-05-03 19:37:06','2013-05-03 19:34:34',18,0),(320,'','',20,1,8177,'2013-05-03 19:37:34','2013-05-03 19:38:27','2013-05-03 19:37:33',18,0),(321,'','',20,1,8178,'2013-05-03 19:38:48','2013-05-03 19:38:51','2013-05-03 19:38:45',18,0),(322,'','',20,1,8179,'2013-05-03 19:39:45','2013-05-03 19:39:51','2013-05-03 19:39:42',1,1),(323,'','',20,1,8180,'2013-05-03 19:39:55','0000-00-00 00:00:00','2013-05-03 19:39:53',18,1),(324,'','',20,1,8181,'2013-05-03 19:53:34','2013-05-03 19:59:32','2013-05-03 19:53:32',18,1),(325,'','',20,1,8182,'2013-05-05 15:56:37','2013-05-05 15:56:52','2013-05-05 15:56:35',18,0),(326,'','',20,1,8183,'2013-05-05 15:56:56','2013-05-05 15:57:02','2013-05-05 15:56:54',18,0),(327,'','',20,1,8184,'2013-05-05 15:57:06','2013-05-05 16:01:00','2013-05-05 15:57:03',18,0),(328,'','',20,1,8185,'2013-05-05 16:02:42','2013-05-05 16:01:31','2013-05-05 16:01:25',18,0),(329,'','',20,1,8186,'2013-05-05 16:09:45','2013-05-05 16:09:52','2013-05-05 16:09:42',18,0),(330,'','',20,1,8187,'2013-05-05 16:10:24','2013-05-05 16:11:11','2013-05-05 16:10:21',18,0),(331,'','',20,1,8188,'2013-05-05 16:11:28','0000-00-00 00:00:00','2013-05-05 16:11:23',18,0),(332,'','',20,1,8189,'2013-05-05 16:28:52','2013-05-05 16:29:29','2013-05-05 16:28:51',18,0),(333,'','',20,1,8190,'2013-05-05 16:29:42','2013-05-05 16:29:52','2013-05-05 16:29:40',18,0),(334,'','',20,1,8191,'2013-05-05 16:30:37','2013-05-05 16:30:46','2013-05-05 16:30:04',1,0),(335,'','',20,1,8192,'2013-05-05 16:30:50','0000-00-00 00:00:00','2013-05-05 16:30:49',18,0),(336,'','',20,1,8193,'2013-05-05 16:38:39','2013-05-05 16:38:48','2013-05-05 16:38:37',18,0),(337,'','',20,1,8194,'2013-05-05 19:40:12','2013-05-05 19:40:16','2013-05-05 19:40:10',18,0),(338,'','',20,1,8195,'2013-05-05 19:52:48','0000-00-00 00:00:00','2013-05-05 19:52:42',18,1),(339,'','',20,1,8196,'0000-00-00 00:00:00','0000-00-00 00:00:00','2013-05-16 11:25:59',1,0),(340,'','',20,1,8197,'0000-00-00 00:00:00','0000-00-00 00:00:00','2013-05-16 11:26:10',1,0),(341,'','',20,1,8198,'2013-05-16 11:28:52','2013-05-16 11:29:06','2013-05-16 11:28:49',1,0),(342,'','',20,1,8199,'2013-05-16 11:29:10','2013-05-16 11:29:49','2013-05-16 11:29:08',18,0),(343,'','',20,1,8200,'2013-05-16 11:30:39','2013-05-16 11:33:43','2013-05-16 11:30:37',18,0),(344,'','',20,1,8201,'2013-05-16 11:33:46','2013-05-16 11:34:27','2013-05-16 11:33:43',18,0),(345,'','',20,1,8202,'2013-05-16 11:34:33','2013-05-16 11:34:53','2013-05-16 11:34:27',18,0),(346,'','',20,1,8203,'2013-05-16 11:34:55','0000-00-00 00:00:00','2013-05-16 11:34:53',18,0),(347,'','',20,1,8204,'2013-05-16 11:47:55','0000-00-00 00:00:00','2013-05-16 11:47:53',18,0),(348,'','',20,1,8205,'2013-05-16 11:50:05','0000-00-00 00:00:00','2013-05-16 11:50:02',18,0),(349,'','',20,1,8206,'2013-05-16 11:55:37','2013-05-16 11:55:47','2013-05-16 11:55:35',18,0),(350,'','',20,1,8207,'2013-05-16 11:55:52','2013-05-16 11:55:58','2013-05-16 11:55:49',18,0),(351,'','',20,1,8208,'2013-05-16 11:56:37','2013-05-16 11:59:14','2013-05-16 11:56:01',18,0),(352,'','',20,1,8209,'2013-05-16 11:59:27','2013-05-16 12:00:57','2013-05-16 11:59:17',18,0),(353,'','',20,1,8210,'2013-05-16 12:01:56','2013-05-16 12:02:21','2013-05-16 12:01:52',18,0),(354,'','',20,1,8211,'2013-05-16 12:02:31','2013-05-16 12:05:23','2013-05-16 12:02:24',18,0),(355,'','',20,1,8212,'2013-05-16 12:05:33','0000-00-00 00:00:00','2013-05-16 12:05:26',18,0),(356,'','',20,1,8213,'2013-05-16 12:15:22','0000-00-00 00:00:00','2013-05-16 12:15:14',18,0),(357,'','',20,1,8214,'2013-05-16 12:20:57','2013-05-16 12:21:03','2013-05-16 12:20:51',18,0),(358,'','',20,1,8215,'2013-05-16 12:21:05','2013-05-16 12:21:07','2013-05-16 12:21:03',18,0),(359,'','',20,1,8216,'2013-05-16 12:21:14','0000-00-00 00:00:00','2013-05-16 12:21:07',18,0),(360,'','',20,1,8217,'2013-05-16 12:30:42','2013-05-16 12:30:55','2013-05-16 12:30:40',18,0),(361,'','',20,1,8218,'2013-05-16 12:30:59','2013-05-16 12:31:32','2013-05-16 12:30:56',18,0),(362,'','',20,1,8219,'2013-05-16 12:31:34','2013-05-16 12:32:46','2013-05-16 12:31:32',18,0),(363,'','',20,1,8220,'2013-05-16 12:32:50','2013-05-16 12:33:09','2013-05-16 12:32:48',18,0),(364,'','',20,1,8221,'2013-05-16 12:33:17','0000-00-00 00:00:00','2013-05-16 12:33:09',18,0),(365,'','',20,1,8222,'2013-05-16 12:55:34','2013-05-16 12:58:01','2013-05-16 12:55:32',18,0),(366,'','',20,1,8223,'2013-05-16 12:58:03','2013-05-16 12:58:35','2013-05-16 12:58:01',18,0),(367,'','',20,1,8224,'2013-05-16 12:58:44','2013-05-16 12:59:08','2013-05-16 12:58:37',18,0),(368,'','',20,1,8225,'2013-05-16 13:03:50','0000-00-00 00:00:00','2013-05-16 13:03:46',18,0),(369,'','',20,1,8226,'0000-00-00 00:00:00','2013-05-16 13:59:36','2013-05-16 13:59:00',18,0),(370,'','',20,1,8227,'2013-05-16 13:59:40','2013-05-16 14:00:10','2013-05-16 13:59:38',18,0),(371,'','',20,1,8228,'0000-00-00 00:00:00','0000-00-00 00:00:00','2013-05-16 14:36:46',18,0),(372,'','',20,1,8229,'0000-00-00 00:00:00','0000-00-00 00:00:00','2013-05-16 14:38:12',18,0),(373,'','',20,1,8230,'0000-00-00 00:00:00','0000-00-00 00:00:00','2013-05-16 14:41:01',18,0),(374,'','',20,1,8231,'2013-05-16 14:42:16','2013-05-16 14:42:25','2013-05-16 14:42:15',18,0),(375,'','',20,1,8232,'2013-05-16 20:51:40','2013-05-16 20:51:48','2013-05-16 20:51:38',18,0),(376,'','',20,1,8233,'0000-00-00 00:00:00','0000-00-00 00:00:00','2013-05-16 20:54:41',18,0),(377,'','',20,1,8234,'2013-05-16 21:18:07','2013-05-16 21:20:38','2013-05-16 21:18:04',18,1),(378,'','',20,1,8235,'2013-05-16 21:20:40','2013-05-16 21:20:46','2013-05-16 21:20:38',18,1),(379,'','',20,1,8236,'2013-05-16 21:20:57','2013-05-16 21:23:10','2013-05-16 21:20:48',18,1),(380,'','',20,1,8237,'2013-05-16 21:23:25','0000-00-00 00:00:00','2013-05-16 21:23:07',18,1),(381,'','',20,1,8238,'2013-05-16 21:46:56','2013-05-16 21:47:00','2013-05-16 21:46:54',18,1),(382,'','',20,1,8239,'2013-05-16 22:04:28','2013-05-16 22:05:07','2013-05-16 22:04:26',18,0),(383,'','',20,1,8240,'2013-05-16 22:05:09','2013-05-16 22:07:46','2013-05-16 22:05:07',18,0),(384,'','',20,1,8241,'2013-05-17 11:19:34','2013-05-17 11:19:44','2013-05-17 11:19:24',1,0),(385,'','',20,1,8242,'0000-00-00 00:00:00','2013-05-17 11:20:21','2013-05-17 11:19:46',18,0),(386,'','',20,1,8243,'2013-05-17 11:20:33','2013-05-17 11:22:10','2013-05-17 11:20:29',18,0),(387,'','',20,1,8244,'0000-00-00 00:00:00','2013-05-17 11:22:29','2013-05-17 11:22:21',18,0),(388,'','',20,1,8245,'0000-00-00 00:00:00','2013-05-17 11:22:57','2013-05-17 11:22:29',18,0),(389,'','',20,1,8246,'2013-05-17 11:23:10','2013-05-17 11:24:07','2013-05-17 11:23:06',18,0),(390,'','',20,1,8247,'2013-05-17 11:24:13','2013-05-17 11:26:19','2013-05-17 11:24:08',18,0),(391,'','',20,1,8248,'2013-05-17 11:26:35','0000-00-00 00:00:00','2013-05-17 11:26:34',18,0),(392,'','',20,1,8249,'2013-05-17 11:33:16','2013-05-17 11:35:38','2013-05-17 11:33:13',18,0),(393,'','',20,1,8250,'2013-05-17 11:35:41','2013-05-17 11:36:58','2013-05-17 11:35:38',18,0),(394,'','',20,1,8251,'0000-00-00 00:00:00','2013-05-17 11:37:04','2013-05-17 11:36:58',18,0),(395,'','',20,1,8252,'2013-05-17 11:37:09','2013-05-17 11:37:24','2013-05-17 11:37:07',18,0),(396,'','',20,1,8253,'2013-05-17 11:37:26','2013-05-17 11:37:53','2013-05-17 11:37:24',18,0),(397,'','',20,1,8254,'2013-05-17 11:37:55','2013-05-17 11:42:59','2013-05-17 11:37:53',18,0),(398,'','',20,1,8255,'2013-05-17 11:43:05','0000-00-00 00:00:00','2013-05-17 11:43:01',18,1),(399,'','',20,1,8256,'2013-05-17 11:49:16','2013-05-17 11:49:20','2013-05-17 11:49:15',18,1),(400,'','',20,1,8257,'2013-05-17 14:03:19','2013-05-17 14:03:49','2013-05-17 14:03:17',18,1),(401,'','',20,1,8258,'2013-05-17 14:03:52','2013-05-17 14:05:40','2013-05-17 14:03:49',18,1),(402,'','',20,1,8259,'0000-00-00 00:00:00','2013-05-17 15:36:40','2013-05-17 15:35:53',18,1),(403,'','',20,1,8260,'2013-05-17 15:36:55','2013-05-17 15:37:21','2013-05-17 15:36:53',18,1),(404,'','',20,1,8261,'0000-00-00 00:00:00','2013-05-17 15:52:51','2013-05-17 15:52:26',18,1),(405,'','',20,1,8262,'2013-05-17 15:53:01','0000-00-00 00:00:00','2013-05-17 15:52:59',18,1),(406,'','',20,1,8263,'2013-05-17 18:13:54','0000-00-00 00:00:00','2013-05-17 18:13:53',18,1),(407,'','',20,1,8264,'2013-05-18 15:50:29','2013-05-18 15:52:45','2013-05-18 15:50:25',18,0),(408,'','',20,1,8265,'2013-05-18 15:52:47','2013-05-18 15:52:59','2013-05-18 15:52:45',18,0),(409,'','',20,1,8266,'2013-05-18 15:53:02','0000-00-00 00:00:00','2013-05-18 15:52:59',18,0),(410,'','',20,1,8267,'2013-05-18 17:54:38','2013-05-18 17:55:15','2013-05-18 17:54:36',18,0),(411,'','',20,1,8268,'2013-05-18 17:55:51','0000-00-00 00:00:00','2013-05-18 17:55:50',18,1),(412,'','',20,1,8269,'2013-05-18 17:58:04','2013-05-18 17:58:48','2013-05-18 17:58:02',18,1),(413,'','',20,1,8270,'2013-05-18 20:40:50','0000-00-00 00:00:00','2013-05-18 20:40:48',18,1),(414,'','',20,1,8271,'2013-05-18 20:41:30','0000-00-00 00:00:00','2013-05-18 20:41:29',18,1),(415,'','',20,1,8272,'2013-05-18 20:57:23','0000-00-00 00:00:00','2013-05-18 20:57:22',18,1),(416,'','',20,1,8273,'2013-05-19 13:17:08','0000-00-00 00:00:00','2013-05-19 13:17:06',18,1),(417,'','',20,1,8274,'2013-05-19 13:41:14','2013-05-19 13:41:42','2013-05-19 13:41:12',18,1),(418,'','',20,1,8275,'2013-05-19 13:51:19','2013-05-19 13:51:38','2013-05-19 13:51:16',18,1),(419,'','',20,1,8276,'2013-05-19 13:51:39','2013-05-19 13:54:46','2013-05-19 13:51:38',18,1),(420,'','',20,1,8277,'2013-05-19 13:56:01','2013-05-19 13:56:55','2013-05-19 13:55:59',18,1),(421,'','',20,1,8278,'2013-05-19 13:56:58','0000-00-00 00:00:00','2013-05-19 13:56:55',18,1),(422,'','',20,1,8279,'2013-05-19 14:08:46','2013-05-19 14:09:01','2013-05-19 14:08:43',18,1),(423,'','',20,1,8280,'2013-05-19 14:12:13','0000-00-00 00:00:00','2013-05-19 14:12:11',18,1),(424,'','',20,1,8281,'2013-05-19 14:18:11','2013-05-19 14:21:23','2013-05-19 14:18:09',18,1),(425,'','',20,1,8282,'2013-05-19 14:21:37','2013-05-19 14:25:22','2013-05-19 14:21:35',18,1),(426,'','',20,1,8283,'2013-05-19 14:25:24','0000-00-00 00:00:00','2013-05-19 14:25:22',18,1),(427,'','',20,1,8284,'2013-05-19 15:25:34','0000-00-00 00:00:00','2013-05-19 15:25:31',18,1),(428,'','',20,1,8285,'2013-05-19 15:34:32','0000-00-00 00:00:00','2013-05-19 15:34:31',18,1),(429,'','',20,1,8286,'2013-05-19 16:33:18','2013-05-19 16:34:15','2013-05-19 16:33:17',18,1),(430,'','',20,1,8287,'2013-05-19 16:35:39','0000-00-00 00:00:00','2013-05-19 16:35:37',18,1),(431,'','',20,1,8288,'2013-05-19 17:03:40','2013-05-19 17:04:34','2013-05-19 17:03:38',18,1),(432,'','',20,1,8289,'2013-05-19 17:04:35','2013-05-19 17:06:05','2013-05-19 17:04:34',18,1),(433,'','',20,1,8290,'2013-05-19 17:06:07','2013-05-19 17:07:37','2013-05-19 17:06:05',18,1),(434,'','',20,1,8291,'2013-05-19 17:07:47','2013-05-19 17:09:41','2013-05-19 17:07:45',18,1),(435,'','',20,1,8292,'2013-05-19 17:09:50','2013-05-19 17:11:12','2013-05-19 17:09:49',18,1),(436,'','',20,1,8293,'2013-05-19 17:11:24','0000-00-00 00:00:00','2013-05-19 17:11:22',18,1),(437,'','',20,1,8294,'2013-05-19 17:16:38','2013-05-19 17:16:48','2013-05-19 17:16:37',18,1),(438,'','',20,1,8295,'2013-05-19 17:17:25','0000-00-00 00:00:00','2013-05-19 17:17:23',18,1),(439,'','',20,1,8296,'2013-05-19 17:43:55','2013-05-19 17:44:16','2013-05-19 17:43:53',18,1),(440,'','',20,1,8297,'0000-00-00 00:00:00','2013-05-19 17:44:47','2013-05-19 17:44:16',18,1),(441,'','',20,1,8298,'2013-05-19 17:44:49','2013-05-19 17:45:10','2013-05-19 17:44:47',18,1),(442,'','',20,1,8299,'2013-05-19 17:45:11','0000-00-00 00:00:00','2013-05-19 17:45:10',18,1),(443,'','',20,1,8300,'2013-05-19 17:55:03','0000-00-00 00:00:00','2013-05-19 17:55:01',18,1),(444,'','',20,1,8301,'2013-05-20 14:40:43','2013-05-20 14:41:20','2013-05-20 14:40:39',18,1),(445,'','',20,1,8302,'0000-00-00 00:00:00','2013-05-20 14:41:26','2013-05-20 14:41:20',18,1),(446,'','',20,1,8303,'2013-05-20 14:41:30','0000-00-00 00:00:00','2013-05-20 14:41:26',18,1),(447,'','',20,1,8304,'2013-05-20 15:53:17','2013-05-20 15:54:01','2013-05-20 15:53:13',18,1),(448,'','',20,1,8305,'2013-05-20 15:56:06','2013-05-20 15:58:38','2013-05-20 15:55:32',18,1),(449,'','',20,1,8306,'2013-05-20 16:04:56','2013-05-20 16:05:29','2013-05-20 16:04:54',18,1),(450,'','',20,1,8307,'2013-05-20 16:05:36','2013-05-20 16:07:09','2013-05-20 16:05:33',18,1),(451,'','',20,1,8308,'2013-05-20 16:07:17','2013-05-20 16:07:18','2013-05-20 16:07:14',18,1),(452,'','',20,1,8309,'0000-00-00 00:00:00','2013-05-20 16:08:02','2013-05-20 16:08:00',18,1),(453,'','',20,1,8310,'0000-00-00 00:00:00','0000-00-00 00:00:00','2013-05-20 16:11:35',18,1),(454,'','',20,1,8311,'0000-00-00 00:00:00','2013-05-20 16:18:47','2013-05-20 16:18:31',18,1),(455,'','',20,1,8312,'2013-05-20 16:27:02','2013-05-20 16:28:45','2013-05-20 16:26:57',18,1),(456,'','',20,1,8313,'2013-05-20 16:28:48','2013-05-20 16:31:21','2013-05-20 16:28:45',18,1),(457,'','',20,1,8314,'0000-00-00 00:00:00','2013-05-20 16:31:58','2013-05-20 16:31:22',18,1),(458,'','',20,1,8315,'2013-05-20 16:32:02','2013-05-20 16:36:50','2013-05-20 16:31:58',18,1),(459,'','',20,1,8316,'2013-05-20 16:38:19','0000-00-00 00:00:00','2013-05-20 16:38:16',18,1),(460,'','',20,1,8317,'2013-05-20 17:06:55','0000-00-00 00:00:00','2013-05-20 17:06:52',18,1),(461,'','',20,1,8318,'2013-05-20 17:15:47','2013-05-20 17:15:41','2013-05-20 17:15:38',18,1),(462,'','',20,1,8319,'2013-05-20 17:53:12','2013-05-20 17:53:45','2013-05-20 17:53:08',18,1),(463,'','',20,1,8320,'2013-05-20 17:53:48','2013-05-20 17:54:32','2013-05-20 17:53:45',18,1),(464,'','',20,1,8321,'2013-05-20 17:54:35','2013-05-20 17:55:59','2013-05-20 17:54:32',18,1),(465,'','',20,1,8322,'2013-05-20 17:56:56','2013-05-20 17:58:23','2013-05-20 17:56:53',18,1),(466,'','',20,1,8323,'2013-05-20 17:58:33','2013-05-20 17:59:45','2013-05-20 17:58:30',18,1),(467,'','',20,1,8324,'0000-00-00 00:00:00','2013-05-20 18:02:06','2013-05-20 18:01:52',18,1),(468,'','',20,1,8325,'2013-05-20 18:02:10','2013-05-20 18:02:34','2013-05-20 18:02:06',18,1),(469,'','',20,1,8326,'2013-05-20 18:02:36','2013-05-20 18:03:38','2013-05-20 18:02:34',18,1),(470,'','',20,1,8327,'2013-05-20 18:03:41','2013-05-20 18:04:35','2013-05-20 18:03:38',18,1),(471,'','',20,1,8328,'2013-05-20 18:04:38','2013-05-20 18:05:50','2013-05-20 18:04:35',18,1),(472,'','',20,1,8329,'2013-05-20 18:05:53','2013-05-20 18:07:14','2013-05-20 18:05:50',18,1),(473,'','',20,1,8330,'2013-05-20 18:14:15','2013-05-20 18:20:12','2013-05-20 18:14:10',18,1),(474,'','',20,1,8331,'2013-05-20 18:28:56','0000-00-00 00:00:00','2013-05-20 18:28:50',18,1),(475,'','',20,1,8332,'2013-05-20 20:45:17','0000-00-00 00:00:00','2013-05-20 20:45:13',18,1),(476,'','',20,1,8333,'2013-05-20 22:02:50','2013-05-20 22:04:22','2013-05-20 22:00:57',18,1),(477,'','',20,1,8334,'2013-05-20 22:04:41','2013-05-20 22:08:06','2013-05-20 22:04:37',18,1),(478,'','',20,1,8335,'2013-05-20 22:08:08','0000-00-00 00:00:00','2013-05-20 22:08:06',18,1),(479,'','',20,1,8336,'2013-05-20 22:21:12','0000-00-00 00:00:00','2013-05-20 22:21:04',18,1),(480,'','',20,1,8337,'2013-05-21 14:11:17','2013-05-21 14:12:19','2013-05-21 14:11:14',18,1),(481,'','',20,1,8338,'2013-05-21 14:12:27','0000-00-00 00:00:00','2013-05-21 14:12:24',18,1),(482,'','',20,1,8339,'2013-05-21 14:32:01','2013-05-21 14:34:23','2013-05-21 14:31:59',18,1),(483,'','',20,1,8340,'2013-05-21 14:34:39','2013-05-21 14:35:01','2013-05-21 14:34:31',18,1),(484,'','',20,1,8341,'2013-05-21 14:35:05','2013-05-21 14:35:33','2013-05-21 14:35:02',18,1),(485,'','',20,1,8342,'2013-05-21 14:35:35','2013-05-21 14:36:16','2013-05-21 14:35:33',18,1),(486,'','',20,1,8343,'2013-05-21 14:36:47','2013-05-21 14:38:31','2013-05-21 14:36:39',18,1),(487,'','',20,1,8344,'2013-05-21 14:38:37','2013-05-21 14:38:47','2013-05-21 14:38:36',18,1),(488,'','',20,1,8345,'2013-05-21 14:38:53','2013-05-21 14:40:45','2013-05-21 14:38:50',18,1),(489,'','',20,1,8346,'2013-05-21 14:42:23','2013-05-21 14:43:57','2013-05-21 14:41:09',18,0),(490,'','',20,1,8347,'2013-05-21 14:44:10','2013-05-21 14:45:28','2013-05-21 14:43:59',18,0),(491,'','',20,1,8348,'2013-05-21 14:45:53','2013-05-21 14:46:57','2013-05-21 14:45:40',18,0),(492,'','',20,1,8349,'2013-05-21 15:06:56','0000-00-00 00:00:00','2013-05-21 15:06:54',18,0),(493,'','',20,1,8350,'2013-05-21 17:01:52','2013-05-21 17:02:05','2013-05-21 17:01:49',18,0),(494,'','',20,1,8351,'0000-00-00 00:00:00','2013-05-21 17:02:34','2013-05-21 17:02:31',1,0),(495,'','',22,1,8352,'0000-00-00 00:00:00','0000-00-00 00:00:00','2013-05-21 17:11:29',18,0),(496,'','',22,1,8353,'0000-00-00 00:00:00','0000-00-00 00:00:00','2013-05-21 17:13:33',18,0),(497,'','',22,1,8354,'0000-00-00 00:00:00','0000-00-00 00:00:00','2013-05-21 17:15:25',18,0),(498,'','',22,1,8355,'0000-00-00 00:00:00','0000-00-00 00:00:00','2013-05-21 17:21:50',18,0),(499,'','',22,1,8356,'0000-00-00 00:00:00','0000-00-00 00:00:00','2013-05-21 17:28:24',18,0),(500,'','',22,1,8357,'0000-00-00 00:00:00','0000-00-00 00:00:00','2013-05-23 12:46:56',18,0),(501,'','',22,1,8358,'0000-00-00 00:00:00','0000-00-00 00:00:00','2013-05-23 12:47:29',18,0),(502,'','',22,1,8359,'2013-05-23 13:03:30','0000-00-00 00:00:00','2013-05-23 13:03:13',18,0),(503,'','',20,1,8360,'0000-00-00 00:00:00','2013-05-25 14:07:07','2013-05-25 14:07:06',18,0),(504,'','',20,1,8361,'2013-05-25 14:07:12','2013-05-25 14:07:23','2013-05-25 14:07:09',18,1),(505,'','',20,1,8362,'2013-05-25 15:09:29','2013-05-25 15:09:35','2013-05-25 15:09:27',18,1),(506,'','',20,1,8363,'2013-05-25 15:09:39','2013-05-25 15:10:10','2013-05-25 15:09:37',18,1),(507,'','',20,1,8364,'2013-05-25 15:10:19','2013-05-25 15:13:56','2013-05-25 15:10:18',18,1),(508,'','',20,1,8365,'2013-05-25 15:14:06','0000-00-00 00:00:00','2013-05-25 15:14:04',18,1),(509,'','',20,1,8366,'0000-00-00 00:00:00','2013-05-25 16:14:02','2013-05-25 16:13:19',18,1),(510,'','',20,1,8367,'0000-00-00 00:00:00','2013-05-25 16:14:09','2013-05-25 16:14:02',18,1),(511,'','',20,1,8368,'2013-05-25 16:14:22','2013-05-25 16:20:18','2013-05-25 16:14:17',18,1),(512,'','',20,1,8369,'2013-05-25 16:22:04','2013-05-25 16:23:17','2013-05-25 16:22:01',18,1),(513,'','',20,1,8370,'2013-05-25 16:23:27','2013-05-25 16:24:12','2013-05-25 16:23:26',18,1),(514,'','',20,1,8371,'2013-05-25 16:38:54','0000-00-00 00:00:00','2013-05-25 16:38:52',18,1),(515,'','',20,1,8372,'2013-05-25 16:45:50','0000-00-00 00:00:00','2013-05-25 16:45:49',18,1),(516,'','',20,1,8373,'2013-05-25 18:03:23','0000-00-00 00:00:00','2013-05-25 18:03:21',18,1),(517,'','',20,1,8374,'2013-05-25 18:13:08','2013-05-25 18:16:49','2013-05-25 18:13:05',18,1),(518,'','',20,1,8375,'2013-05-25 18:16:58','0000-00-00 00:00:00','2013-05-25 18:16:56',18,1),(519,'','',20,1,8376,'2013-05-25 18:48:20','0000-00-00 00:00:00','2013-05-25 18:48:19',18,1),(520,'','',20,1,8377,'2013-05-25 19:05:33','2013-05-25 19:07:05','2013-05-25 19:05:31',18,1),(521,'','',20,1,8378,'2013-05-25 19:34:47','0000-00-00 00:00:00','2013-05-25 19:34:45',18,1),(522,'','',20,1,8379,'2013-05-25 19:36:31','2013-05-25 19:36:37','2013-05-25 19:36:29',18,1),(523,'','',20,1,8380,'2013-05-25 19:36:39','2013-05-25 19:38:06','2013-05-25 19:36:37',18,1),(524,'','',20,1,8381,'2013-05-25 19:38:47','0000-00-00 00:00:00','2013-05-25 19:38:45',18,1),(525,'','',20,1,8382,'2013-05-25 19:46:57','2013-05-25 19:49:14','2013-05-25 19:46:48',18,1),(526,'','',20,1,8383,'0000-00-00 00:00:00','2013-05-25 19:49:34','2013-05-25 19:49:10',18,1),(527,'','',20,1,8384,'2013-05-25 19:49:39','2013-05-25 19:50:43','2013-05-25 19:49:29',18,1),(528,'','',20,1,8385,'2013-05-25 19:50:48','2013-05-25 19:52:51','2013-05-25 19:50:39',18,1),(529,'','',20,1,8386,'0000-00-00 00:00:00','2013-05-25 19:52:48','2013-05-25 19:51:18',18,1),(530,'','',20,1,8387,'2013-05-25 19:52:57','0000-00-00 00:00:00','2013-05-25 19:52:48',18,1);
/*!40000 ALTER TABLE `ds_game_session` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ds_participates`
--

DROP TABLE IF EXISTS `ds_participates`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ds_participates` (
  `game_session_id` int(10) unsigned NOT NULL DEFAULT '0',
  `user_id` int(10) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`game_session_id`,`user_id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `ds_participates_ibfk_1` FOREIGN KEY (`game_session_id`) REFERENCES `ds_game_session` (`id`),
  CONSTRAINT `ds_participates_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `ds_user` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ds_participates`
--

LOCK TABLES `ds_participates` WRITE;
/*!40000 ALTER TABLE `ds_participates` DISABLE KEYS */;
/*!40000 ALTER TABLE `ds_participates` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ds_session`
--

DROP TABLE IF EXISTS `ds_session`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ds_session` (
  `deck_id` int(10) unsigned DEFAULT NULL,
  `datetime` datetime NOT NULL,
  `user_id` int(10) unsigned DEFAULT NULL,
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`id`),
  UNIQUE KEY `deckuser` (`deck_id`,`user_id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `ds_session_ibfk_1` FOREIGN KEY (`deck_id`) REFERENCES `ds_deck` (`id`),
  CONSTRAINT `ds_session_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `ds_user` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ds_session`
--

LOCK TABLES `ds_session` WRITE;
/*!40000 ALTER TABLE `ds_session` DISABLE KEYS */;
/*!40000 ALTER TABLE `ds_session` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ds_session_card`
--

DROP TABLE IF EXISTS `ds_session_card`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ds_session_card` (
  `session_id` int(10) unsigned DEFAULT NULL,
  `card_id` int(10) unsigned DEFAULT NULL,
  `nr` int(10) unsigned DEFAULT NULL,
  UNIQUE KEY `session_card` (`session_id`,`card_id`),
  KEY `card_id` (`card_id`),
  CONSTRAINT `ds_session_card_ibfk_1` FOREIGN KEY (`session_id`) REFERENCES `ds_session` (`id`),
  CONSTRAINT `ds_session_card_ibfk_2` FOREIGN KEY (`card_id`) REFERENCES `ds_card` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ds_session_card`
--

LOCK TABLES `ds_session_card` WRITE;
/*!40000 ALTER TABLE `ds_session_card` DISABLE KEYS */;
/*!40000 ALTER TABLE `ds_session_card` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ds_user`
--

DROP TABLE IF EXISTS `ds_user`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ds_user` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `username` varchar(100) NOT NULL,
  `password` varchar(50) NOT NULL,
  `email` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `username` (`username`)
) ENGINE=InnoDB AUTO_INCREMENT=25 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ds_user`
--

LOCK TABLES `ds_user` WRITE;
/*!40000 ALTER TABLE `ds_user` DISABLE KEYS */;
INSERT INTO `ds_user` VALUES (20,'anders','73fa9f10d105c0ddabe356f81d6aecd5','asd'),(22,'olle','df9d12d354532253bbfe7fb54318dc49','e'),(24,'olle2','df9d12d354532253bbfe7fb54318dc49','owowo');
/*!40000 ALTER TABLE `ds_user` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ds_user_cookie`
--

DROP TABLE IF EXISTS `ds_user_cookie`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ds_user_cookie` (
  `user_id` int(10) unsigned DEFAULT NULL,
  `datetime` datetime NOT NULL,
  `login_session_id` int(10) unsigned NOT NULL,
  KEY `user_id` (`user_id`,`login_session_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ds_user_cookie`
--

LOCK TABLES `ds_user_cookie` WRITE;
/*!40000 ALTER TABLE `ds_user_cookie` DISABLE KEYS */;
INSERT INTO `ds_user_cookie` VALUES (17,'2012-12-18 04:41:05',1065937866),(6,'2012-12-19 19:29:14',281827771),(24,'2013-05-01 19:25:35',551245851),(20,'2013-05-25 19:52:49',752005726),(22,'2013-05-25 19:52:54',565796660);
/*!40000 ALTER TABLE `ds_user_cookie` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2013-05-27 14:12:03
