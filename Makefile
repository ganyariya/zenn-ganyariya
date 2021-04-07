L_FILE=articles/**.md
PORT=8100


.PHENY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

.PHONY: article
article: ## SLUG option
	npx zenn new:article --slug $(SLUG)

.PHONY: prev iew
preview: ## PORT option
	npx zenn preview -p $(PORT) &

.PHONY: lint
lint: ## L_FILE option
	npx textlint $(L_FILE)

.PHONY: install
install:
	npm install
	npm audit fix
