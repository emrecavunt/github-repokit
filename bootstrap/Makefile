# Forward to the GitHub stack so `cd bootstrap && make` still works.
.DEFAULT_GOAL := help

.PHONY: help show fmt validate lint scan tg-init tg-plan tg-import-repo-settings apply check all

help show fmt validate lint scan tg-init tg-plan apply check all:
	@$(MAKE) -C github $@

tg-import-repo-settings:
	@$(MAKE) -C github tg-import-repo-settings REPO_NAME="$(REPO_NAME)"
