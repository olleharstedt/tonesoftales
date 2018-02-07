#
#	deriving clashes with type-conv and json.syntax
#	use type-conv in models, and deriving in controllers?
#

# Order matters
#objects=sql.cmx misc.cmx db.cmx user.cmx operation.cmx loginCookie.cmx card.cmx deck.cmx session.cmx chat.cmx game.cmx gamesession.cmx participates.cmx lua.cmx websocket.cmx
objects=sql misc db user operation loginCookie card deck session game gamesession participates lua websocket chat ads
objects_cmx=$(addsuffix .cmx,$(objects))
objects_ml=$(addsuffix .ml,$(objects))

#objects=$(patsubst %.ml,%.cmx,$(wildcard *.ml))		# Does not work because order matters

controller_objects=$(wildcard controller/*Controller.ml)	# Automatically include all controller files in controller dir. OBS: Naming convention

javascript_objects=$(wildcard js/*.js)

javascript_targets=$(wildcard /home/d37433/public_html/js/*.js)

css_objects=$(wildcard *.css)

secure_php_objects=php/login.php php/register.php php/new_password.php

php_objects=php/index.php

template_objects=tutorials.tmpl play_game.tmpl startpage.tmpl new_own_game.tmpl new_other_game.tmpl lobby.tmpl card_form.tmpl edit_card.tmpl game_form.tmpl edit_game.tmpl about.tmpl home.tmpl login.tmpl register.tmpl sourcecode.tmpl create_game.tmpl

template_objects2=$(addprefix templates/, $(template_objects))

packages=str,netcgi2,netstring,netsys,unix,bigarray,pcre,netstring,mysql,xml-light,yojson,lwt.preemptive,lwt-websocket,extlib,lua,jingoo

syntax_packages=json-tc.syntax,dyntype.syntax

drakskatten_cgi.exe: $(objects_cmx) $(patsubst %.ml,%.cmx,$(controller_objects)) drakskatten.ml
	@ocamlfind ocamlopt -g -thread -linkpkg -package $(packages),json-tc.syntax,dyntype,js_of_ocaml.deriving dyntype.cmxa $^ -o $@ 

drakskatten_ajax.exe: $(objects_cmx) $(patsubst %.ml,%.cmx,$(controller_objects)) drakskatten_ajax.ml
	@ocamlfind ocamlopt -g -thread -linkpkg -package $(packages),js_of_ocaml.deriving,json-tc.syntax,dyntype dyntype.cmxa $^ -o $@

# For javascript, just copy files to target dir
drakskatten_js: $(javascript_objects)
	@cp $^ /home/d37433/public_html/js

css: $(css_objects)
	@cp $^ /home/d37433/public_html/css

secure_php: $(secure_php_objects)
	@cp $^ /home/d37433/public_html/secure
	@cp $^ /home/d37433/public_html/

php_: php/index.php
	@cp $^ /home/d37433/public_html/

tmpls: $(template_objects2)
	@cp $^ /home/d37433/templates/

$(objects_cmx):$(objects_ml)
	@ocamlfind ocamlopt -g -c -syntax camlp4o -thread -package $(syntax_packages),$(packages) $^

# Controllers
%.cmx: %.ml
	@ocamlfind ocamlopt -g -c -thread -syntax camlp4o -package js_of_ocaml.deriving,json-tc.syntax,$(packages) $^

lua_test1: lua_test1.ml
	ocamlfind opt -thread -linkpkg -package lua,unix lua_test1.ml -o luatest.exe

lua_test3: lua_test1.ml
	ocamlfind opt -thread -package lua lua.cmxa lua_test1.ml -o luatest.exe

lua_test2: lua_test2.c
	gcc -o luatest2.exe lua_test2.c -I/usr/include/lua5.1 -llua5.1
	ocamlfind opt -thread -package lua lua.cmxa lua_test2.ml -o luatest2b.exe

deriving.byte: deriving.ml
	@ocamlfind ocamlc -package lwt,js_of_ocaml,js_of_ocaml.syntax,js_of_ocaml.deriving,js_of_ocaml.deriving.syntax -syntax camlp4o -linkpkg $^ -o deriving.byte

deriving.cmx: deriving.ml
	@ocamlfind ocamlopt -g -c -package lwt,js_of_ocaml,js_of_ocaml.syntax,js_of_ocaml.deriving,js_of_ocaml.deriving.syntax -syntax camlp4o -linkpkg $^ -o deriving.cmx

jstest.js: jstest.ml
	# TODO: Use lwt instead of lwt-websocket
	@ocamlfind ocamlc -package lwt,js_of_ocaml,js_of_ocaml.syntax,js_of_ocaml.deriving,js_of_ocaml.deriving.syntax -syntax camlp4o -linkpkg -o jstest.byte deriving.ml jstest.ml
	@js_of_ocaml jstest.byte
	@cp jstest.js /home/d37433/public_html/js

test.js: Test.hx
	haxe compile.hxml
	cp test.js /home/d37433/public_html/js

cp: drakskatten_cgi.exe drakskatten_ajax.exe
	@cp drakskatten_cgi.exe /home/d37433/public_html/cgi-bin/drakskatten
	@cp drakskatten_ajax.exe /home/d37433/public_html/cgi-bin/drakskatten_ajax

.PHONY: all clean sql install
all: drakskatten_cgi.exe drakskatten_ajax.exe drakskatten_js css tmpls php_ secure_php jstest.js cp

clean:
	@rm *.cmx *.cmi *.o controller/*.cmx controller/*.cmi controller/*.o *.exe

install:
	@read -p "Really install (yes/no)? " really; \
	if [ "$$really" = "yes" ] ; then \
		echo "Installing..."; \
		echo "Did you diff databases?"; \
		find . | xargs file | grep "executable" | grep ELF | cut -f 1 -d : | xargs strip --strip-unneeded 2> /dev/null; \
		scp templates/* d37433@www17.space2u.com:~/templates/ ; \
		scp php/login.php d37433@www17.space2u.com:~/public_html/secure ; \
		scp php/login.php d37433@www17.space2u.com:~/public_html/; \
		scp php/register.php d37433@www17.space2u.com:~/public_html/secure ; \
		scp php/register.php d37433@www17.space2u.com:~/public_html/; \
		scp php/index.php d37433@www17.space2u.com:~/public_html/ ; \
		scp drakskatten_cgi.exe d37433@www17.space2u.com:~/public_html/cgi-bin/ ; \
		scp drakskatten_ajax.exe d37433@www17.space2u.com:~/public_html/cgi-bin/ ; \
		scp js/drakskatten.js d37433@www17.space2u.com:~/public_html/js/ ; \
		scp js/tool.js d37433@www17.space2u.com:~/public_html/js/ ; \
		scp jstest.js d37433@www17.space2u.com:~/public_html/js/ ; \
		scp style.css d37433@www17.space2u.com:~/public_html/css/ ; \
		scp sql/api.sql d37433@www17.space2u.com:~/ ; \
	else \
		echo "Aborting"; \
	fi;

