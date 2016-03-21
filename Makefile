
NODE_ENV ?= 'development'
ifeq ($(NODE_ENV),'development')
DEVEL := 'devel'
endif

BC = browserify
BCOFFEE = -t coffeeify --extension=".coffee"

ifndef DEVEL
BUGLIFY = -t [ uglifyify -x .js -x .coffee ]
BC = $(BC) --debug
endif

BC := $(BC) $(BCOFFEE) $(BUGLIFY)

ifdef DEVEL
UGLIFY = cat 
else
UG_EXTRA = sequences,properties,dead_code,conditionals,evaluate,booleans,loops,collapse_vars,warnings
UG_EXTRA = warnings
UGLIFY := uglifyjs --compress $(UG_EXTRA) --mangle --
endif

client_js := 'public/js'

client_templates := client/gen/templates.js
src_templates := client/jade

client_bundle := $(client_js)/bundle.js
src_bundle := client/bundle.settings.js

.PHONY: client

client: $(client_bundle)
	# client done

$(client_templates): $(shell find $(src_templates) -type f)
	templatizer -d $(src_templates) -o $(client_templates)

$(client_bundle): $(shell find $(src_bundle) -type f) $(client_templates)
	$(BC) $(src_bundle) | $(UGLIFY) > $(client_bundle)

