.PHONY: help release push-release

# Capture positional arguments
ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
$(eval $(ARGS):;@:)

.DEFAULT_GOAL := help

help:
	@echo "TomoBar Release Management"
	@echo ""
	@echo "Usage:"
	@echo "  make release VERSION       Create and push a new release"
	@echo "  make push-release          Push previously created release"
	@echo ""
	@echo "Example:"
	@echo "  make release v4.1.0"
	@echo "  make push-release"

release:
	@VERSION=$(word 1,$(ARGS)); \
	if [ -z "$$VERSION" ]; then \
		echo "❌ Error: VERSION is required"; \
		echo ""; \
		echo "Usage: make release VERSION"; \
		echo "Example: make release v4.1.0"; \
		exit 1; \
	fi; \
	if ! echo "$$VERSION" | grep -qE '^v[0-9]+\.[0-9]+\.[0-9]+$$'; then \
		echo "❌ Error: VERSION must be in vX.Y.Z format (e.g. v4.1.0)"; \
		exit 1; \
	fi; \
	LAST_TAG=$$(git tag -l 'v*' | sort -V | tail -n 1); \
	if [ -n "$$LAST_TAG" ]; then \
		LAST_VERSION=$${LAST_TAG#v}; \
		NEW_VERSION=$${VERSION#v}; \
		if [ "$$VERSION" = "$$LAST_TAG" ]; then \
			echo "❌ Error: Version $$VERSION already exists"; \
			exit 1; \
		fi; \
		NEW_NUM=$$(echo "$$NEW_VERSION" | awk -F. '{print $$1*10000 + $$2*100 + $$3}'); \
		LAST_NUM=$$(echo "$$LAST_VERSION" | awk -F. '{print $$1*10000 + $$2*100 + $$3}'); \
		if [ $$NEW_NUM -le $$LAST_NUM ]; then \
			echo "❌ Error: New version $$NEW_VERSION must be greater than last version $$LAST_VERSION"; \
			echo "   Last release: $$LAST_TAG"; \
			echo "   Attempting:   $$VERSION"; \
			exit 1; \
		fi; \
		echo "📦 Creating release $$VERSION (previous: $$LAST_TAG)"; \
	else \
		echo "📦 Creating first release $$VERSION"; \
	fi; \
	echo "🔧 Auto-incrementing build number..."; \
	agvtool next-version -all; \
	BUILD=$$(agvtool what-version -terse); \
	echo "   New build number: $$BUILD"; \
	echo "🔧 Setting marketing version to $$NEW_VERSION..."; \
	sed -i '' "s/MARKETING_VERSION = [^;]*/MARKETING_VERSION = $$NEW_VERSION/g" TomoBar.xcodeproj/project.pbxproj; \
	if git diff --quiet TomoBar.xcodeproj/project.pbxproj; then \
		echo "ℹ️  No version changes needed"; \
	else \
		echo "💾 Committing version changes..."; \
		git add TomoBar.xcodeproj/project.pbxproj; \
		git commit -m "chore: bump version to $$NEW_VERSION (build $$BUILD)"; \
	fi; \
	echo "🏷️  Creating tag $$VERSION..."; \
	git tag "$$VERSION"; \
	echo "🚀 Pushing to GitHub..."; \
	git push && git push origin "$$VERSION"; \
	echo ""; \
	echo "✅ Release $$VERSION created successfully!"; \
	echo "   Build number: $$BUILD"; \
	echo "   GitHub Actions: https://github.com/ArtemYurov/TomoBar/actions"

push-release:
	@LAST_TAG=$$(git tag -l 'v*' | sort -V | tail -n 1); \
	if [ -z "$$LAST_TAG" ]; then \
		echo "❌ Error: No release tag found"; \
		exit 1; \
	fi; \
	echo "🚀 Pushing release $$LAST_TAG to GitHub..."; \
	git push && git push origin "$$LAST_TAG"; \
	echo ""; \
	echo "✅ Release $$LAST_TAG pushed successfully!"; \
	echo "   GitHub Actions: https://github.com/ArtemYurov/TomoBar/actions"
