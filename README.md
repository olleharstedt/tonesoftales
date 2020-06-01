Tones of Tales

Online card game engine using the scripting language Lua

Video tutorial here: https://www.youtube.com/watch?v=PO0u8sArOA0

Needs some love to get going again.

---
Notes:

stripping bins, worth a try:

Here's the Slack way of stripping binaries, both executables and libs ("shared object")......................
Code:

  find . | xargs file | grep "executable" | grep ELF | cut -f 1 -d : | xargs strip --strip-unneeded 2> /dev/null
    find . | xargs file | grep "shared object" | grep ELF | cut -f 1 -d : | xargs strip --strip-unneeded 2> /dev/null

    NOTE: First 'cd' to the top=level directory where you want to strip the files............These are the commands used in Patrick's SlackBuild scripts found in the source trees of the Slack mirrors................. 


Dump game to sql-file:
mysqldump -u root d37433 -t ds_game --where="id=28" > simplepoker.sql

---

Video:
recordmydesktop
Camorama Webcam viewer
