# BEGIN tornado-recipe
tornado *args:
    opz z.ai -- tornado --config=tornado.json {{args}}
# END tornado-recipe

# BEGIN tornado-validate-recipe
tornado-validate:
    opz z.ai -- tornado validate tornado.json
# END tornado-validate-recipe
