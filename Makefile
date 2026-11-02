# =====================================================================
# Bill's Bounce - publish pipeline (v2, post-first-run fixes)
# Usage:
#   make publish      check -> repo -> deploy -> domains -> dns -> verify
#   make check        vet that gh and vercel are installed AND authenticated
#   make deploy       redeploy site/ to Vercel production (after content edits)
#   make verify       checks the LIVE CONTENT, not just status codes
#
# v2 changes after the first run:
#   - domains: passes the project name (new CLI requires it for subdomains)
#   - dns: uses Vercel's current recommended records (pulled 2026-11-02);
#     the old 76.76.21.21 still works but these are rank 1
#   - verify: greps the page body for the phone number, because GoDaddy
#     parking pages return 200 and fooled v1
# =====================================================================

SHELL := /bin/bash
SITE := site
PROJECT := site
COM := billsbounce.com
PARTY := billsbounce.party
# Vercel recommended records (rank 1) as of 2026-11-02:
VERCEL_A1 := 216.198.79.1
VERCEL_A2 := 64.29.17.1
VERCEL_CNAME := 4878ff4f394d62d5.vercel-dns-017.com
MARKER := 992-2317

.PHONY: publish check repo deploy domains dns verify

publish: check repo deploy domains dns verify
	@echo ""
	@echo "publish: done. If verify shows PARKED, set the DNS records and re-run 'make verify'."

check:
	@command -v git >/dev/null    || { echo "MISSING: git"; exit 1; }
	@command -v gh >/dev/null     || { echo "MISSING: gh CLI (brew install gh)"; exit 1; }
	@command -v vercel >/dev/null || { echo "MISSING: vercel CLI (npm i -g vercel)"; exit 1; }
	@gh auth status >/dev/null 2>&1     || { echo "NOT AUTHENTICATED: run 'gh auth login' first"; exit 1; }
	@vercel whoami  >/dev/null 2>&1     || { echo "NOT AUTHENTICATED: run 'vercel login' first"; exit 1; }
	@echo "gh:     authenticated as $$(gh api user -q .login 2>/dev/null || echo ok)"
	@echo "vercel: authenticated as $$(vercel whoami 2>/dev/null)"
	@if [ -n "$$GODADDY_API_KEY" ] && [ -n "$$GODADDY_API_SECRET" ]; then \
		echo "godaddy: API keys found, 'make dns' will set records automatically"; \
	else \
		echo "godaddy: no GODADDY_API_KEY / GODADDY_API_SECRET exported;"; \
		echo "         'make dns' will print the records for manual entry (still fine)"; \
	fi
	@echo "check: PASS"

repo:
	@if [ ! -d .git ]; then git init -b main; echo "repo: initialized"; fi
	@git add -A
	@git diff --cached --quiet || git commit -m "site update"
	@if git remote get-url origin >/dev/null 2>&1; then \
		git push -u origin main; \
	else \
		gh repo create $(COM) --private --source=. --push; \
	fi
	@echo "repo: pushed"

deploy:
	@cd $(SITE) && vercel deploy --prod --yes
	@echo "deploy: production deploy sent"

domains:
	@cd $(SITE) && for d in $(COM) www.$(COM) $(PARTY) www.$(PARTY); do \
		vercel domains add $$d $(PROJECT) 2>&1 | tail -1 || true; \
	done
	@echo "domains: attached to project '$(PROJECT)' (already-in-use errors are fine)"

dns:
	@if [ -z "$$GODADDY_API_KEY" ] || [ -z "$$GODADDY_API_SECRET" ]; then \
		echo "Set these records in the GoDaddy DNS dashboard for BOTH domains"; \
		echo "($(COM) and $(PARTY)). Delete the parked A records first:"; \
		echo "  A      @     $(VERCEL_A1)"; \
		echo "  A      @     $(VERCEL_A2)"; \
		echo "  CNAME  www   $(VERCEL_CNAME)"; \
	else \
		for d in $(COM) $(PARTY); do \
			echo "dns: setting records for $$d"; \
			curl -fsS -X PUT "https://api.godaddy.com/v1/domains/$$d/records/A/@" \
				-H "Authorization: sso-key $$GODADDY_API_KEY:$$GODADDY_API_SECRET" \
				-H "Content-Type: application/json" \
				-d '[{"data":"$(VERCEL_A1)","ttl":600},{"data":"$(VERCEL_A2)","ttl":600}]' \
				&& echo "  A @ -> $(VERCEL_A1), $(VERCEL_A2)" \
				|| echo "  GoDaddy API refused A records for $$d; set them manually (see 'make dns' without keys)"; \
			curl -fsS -X PUT "https://api.godaddy.com/v1/domains/$$d/records/CNAME/www" \
				-H "Authorization: sso-key $$GODADDY_API_KEY:$$GODADDY_API_SECRET" \
				-H "Content-Type: application/json" \
				-d '[{"data":"$(VERCEL_CNAME)","ttl":600}]' \
				&& echo "  CNAME www -> $(VERCEL_CNAME)" \
				|| echo "  GoDaddy API refused CNAME for $$d; set it manually"; \
		done; \
	fi

verify:
	@for u in https://$(COM) https://www.$(COM) https://$(PARTY) https://www.$(PARTY); do \
		code=$$(curl -sL -o /tmp/bb_verify.html --max-time 10 -w "%{http_code}" $$u 2>/dev/null); \
		if grep -q "$(MARKER)" /tmp/bb_verify.html 2>/dev/null; then \
			printf "%-34s %s LIVE (Bill's site is serving)\n" $$u $$code; \
		else \
			printf "%-34s %s PARKED or propagating (body is not our site yet)\n" $$u $$code; \
		fi; \
	done
	@rm -f /tmp/bb_verify.html
