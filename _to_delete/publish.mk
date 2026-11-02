# =====================================================================
# Bill's Bounce - publish pipeline
# Usage:
#   make publish      the whole thing: check -> repo -> deploy -> domains -> dns -> verify
#   make check        vet that gh and vercel are installed AND authenticated
#   make deploy       redeploy site/ to Vercel production (use after content edits)
#   make verify       curl the live domains and report status codes
#
# DNS: if GODADDY_API_KEY and GODADDY_API_SECRET are exported, 'make dns'
# sets the records via the GoDaddy API. If not, it prints the exact records
# to enter in the GoDaddy dashboard. Either way works.
# =====================================================================

SHELL := /bin/bash
SITE := site
COM := billsbounce.com
PARTY := billsbounce.party
VERCEL_IP := 76.76.21.21
VERCEL_CNAME := cname.vercel-dns.com

.PHONY: publish check repo deploy domains dns verify

publish: check repo deploy domains dns verify
	@echo ""
	@echo "publish: done. If verify showed propagation waits, re-run 'make verify' in a bit."

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
	@git diff --cached --quiet || git commit -m "Bill's Bounce presence site"
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
		vercel domains add $$d 2>&1 | tail -1 || true; \
	done
	@echo "domains: attached (already-added errors are fine)"

dns:
	@if [ -z "$$GODADDY_API_KEY" ] || [ -z "$$GODADDY_API_SECRET" ]; then \
		echo "Set these records in the GoDaddy DNS dashboard for BOTH domains"; \
		echo "($(COM) and $(PARTY)), and delete any conflicting parked A records:"; \
		echo "  A      @     $(VERCEL_IP)"; \
		echo "  CNAME  www   $(VERCEL_CNAME)"; \
	else \
		for d in $(COM) $(PARTY); do \
			echo "dns: setting records for $$d"; \
			curl -fsS -X PUT "https://api.godaddy.com/v1/domains/$$d/records/A/@" \
				-H "Authorization: sso-key $$GODADDY_API_KEY:$$GODADDY_API_SECRET" \
				-H "Content-Type: application/json" \
				-d '[{"data":"$(VERCEL_IP)","ttl":600}]' \
				&& echo "  A @ -> $(VERCEL_IP)" \
				|| echo "  GoDaddy API refused A record for $$d; set it manually (A @ $(VERCEL_IP))"; \
			curl -fsS -X PUT "https://api.godaddy.com/v1/domains/$$d/records/CNAME/www" \
				-H "Authorization: sso-key $$GODADDY_API_KEY:$$GODADDY_API_SECRET" \
				-H "Content-Type: application/json" \
				-d '[{"data":"$(VERCEL_CNAME)","ttl":600}]' \
				&& echo "  CNAME www -> $(VERCEL_CNAME)" \
				|| echo "  GoDaddy API refused CNAME for $$d; set it manually (CNAME www $(VERCEL_CNAME))"; \
		done; \
	fi

verify:
	@for u in https://$(COM) https://www.$(COM) https://$(PARTY); do \
		printf "%-32s " $$u; \
		curl -sI -o /dev/null --max-time 10 -w "%{http_code} %{redirect_url}\n" $$u \
			|| echo "unreachable (DNS likely still propagating; re-run 'make verify' later)"; \
	done
	@echo "expect: $(COM) 200; the www and .party URLs 308 redirecting to https://$(COM)/"
