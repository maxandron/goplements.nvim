ci:
	echo "===> Running ci"
	@make fmt
	@make lint
	@make test

fmt:
	echo "===> Formatting"
	stylua lua/ --config-path=stylua.toml

lint:
	echo "===> Linting"
	selene lua/

test:
	echo "===> Testing"
	@nvim -l tests/minit.lua tests
