### @Maartyl server


NODE_ENV ?= 'development'
ifeq ($(NODE_ENV),'development')
DEVEL := 'devel'
endif


### --- SERVER related ---

.PHONY: run

NODEMON_WATCH = --watch main.js --watch src

run: main.js
	util/nodemon $(NODEMON_WATCH) main.js $(RUN_ARGS)

main.js: main.coffee
	coffee -cm main.coffee

### --- CLIENT related ---

# exported variales will be accessible through this global variable
bundle_accessor = Maa

BC = browserify --standalone $(bundle_accessor)
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
UGLIFY := uglifyjs --compress $(UG_EXTRA) --mangle --screw-ie8 --
endif

client_js := 'public/js'

client_templates := client/gen/templates.js
src_templates := client/jade

client_bundle := $(client_js)/bundle.js
src_bundle := client/bundle.settings.coffee

.PHONY: client

client: $(client_bundle)
	# client done

$(client_templates): $(shell find $(src_templates) -type f)
	templatizer -d $(src_templates) -o $(client_templates)

$(client_bundle): $(shell find $(src_bundle) -type f) $(client_templates)
	$(BC) $(src_bundle) | $(UGLIFY) > $(client_bundle)

