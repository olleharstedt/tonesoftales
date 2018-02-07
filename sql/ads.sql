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
-- Table structure for table `ds_ads`
--

DROP TABLE IF EXISTS `ds_ads`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ds_ads` (
  `uri` varchar(150) NOT NULL,
  `company` varchar(50) NOT NULL,
  PRIMARY KEY (`uri`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ds_ads`
--

LOCK TABLES `ds_ads` WRITE;
/*!40000 ALTER TABLE `ds_ads` DISABLE KEYS */;
INSERT INTO `ds_ads` VALUES ('var uri = \'http://impse.tradedoubler.com/imp?type(iframe)g(16357512)a(2337181)\' + new String (Math.random()).substring (2, 11);','active24'),('var uri = \'http://impse.tradedoubler.com/imp?type(iframe)g(18569502)a(2337181)\' + new String (Math.random()).substring (2, 11);','spelbutiken'),('var uri = \'http://impse.tradedoubler.com/imp?type(iframe)g(19975430)a(2337181)\' + new String (Math.random()).substring (2, 11);','wowhd'),('var uri = \'http://impse.tradedoubler.com/imp?type(iframe)g(20172658)a(2337181)\' + new String (Math.random()).substring (2, 11);','mcafee'),('var uri = \'http://impse.tradedoubler.com/imp?type(iframe)g(21063908)a(2337181)\' + new String (Math.random()).substring (2, 11);','infurn');
/*!40000 ALTER TABLE `ds_ads` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2013-10-27 23:11:04
