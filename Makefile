SHELL := /bin/bash

.PHONY: fresh_install prepare remove stop start restart bash_mw bash_jr bash_wb use_vector_skin use_apiportal_skin use_minervaneue_skin use_timeless_skin use_monobook_skin open_special_version_page run_parser_tests run_php_unit_tests run_selenium_tests run_selenium_test_file run_selenium_test_wildcard run_selenium_test
.DEFAULT: fresh_install
fresh_install:
	./script.sh fresh_install

prepare:
	./script.sh prepare

remove:
	./script.sh remove

stop:
	./script.sh stop

start:
	./script.sh start

restart:
	./script.sh restart

bash_mw:
	./script.sh bash_mw

bash_jr:
	./script.sh bash_jr

bash_wb:
	./script.sh bash_wb

use_vector_skin:
	./script.sh use_vector_skin

use_apiportal_skin:
	./script.sh use_apiportal_skin

use_minervaneue_skin:
	./script.sh use_minervaneue_skin

use_timeless_skin:
	./script.sh use_timeless_skin

use_monobook_skin:
	./script.sh use_monobook_skin

open_special_version_page:
	./script.sh open_special_version_page

run_parser_tests:
	./script.sh run_parser_tests

run_php_unit_tests:
	./script.sh run_php_unit_tests

run_selenium_tests:
	./script.sh run_selenium_tests

run_selenium_test_file:
	./script.sh run_selenium_test_file

run_selenium_test_wildcard:
	./script.sh run_selenium_test_wildcard

run_selenium_test:
	./script.sh run_selenium_test