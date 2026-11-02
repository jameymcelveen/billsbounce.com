# Cursor prompt: publish billsbounce.com

Paste everything between the lines into Cursor (agent mode), opened in
`~/dev/billsbounce.com`. The site is ALREADY BUILT in `site/`. Cursor's job
is publishing, not creating.

---

You are deploying a finished static website. Do not redesign it, do not add
a framework, do not touch the `api/` or `frontend/` folders. The deployable
site is the `site/` directory: `index.html`, `vercel.json`, and `assets/`.

GATE FIRST: run `pwd` and `ls site/` and confirm you are in
`~/dev/billsbounce.com` and that `site/index.html` exists. If not, STOP and
say so. This folder is not yet a git repository; you will create it. If a
`git remote -v` ever shows a repo that is not billsbounce, STOP cold.

RULES
- Plain keyboard characters only in anything you write: no em dashes, no
  smart quotes, no typographic ellipses.
- Never invent URLs. The Facebook page link in `site/index.html` is a TODO
  comment; leave it unless Jamey gives you the real URL.
- Phone number is (843) 992-2317 everywhere. Do not change it.
- If any step fails twice, stop and report instead of improvising.

STEP 1: Sanity-check the site locally.
- Open `site/index.html` in a browser (or `npx serve site`) and confirm: the
  page renders, the trailer photo shows, and the Call button href is
  `tel:+18439922317`.

STEP 2: Git and GitHub.
- `git init`, create a `.gitignore` (node_modules, .vercel, .DS_Store),
  commit everything with message "Bill's Bounce presence site".
- `gh auth status` to confirm login, then:
  `gh repo create billsbounce.com --private --source=. --push`

STEP 3: Deploy to Vercel.
- `cd site`
- `vercel whoami` to confirm login (run `vercel login` if not).
- `vercel deploy --prod --yes` and link it as a NEW project named
  `billsbounce` when prompted.
- Confirm the returned .vercel.app URL serves the page (curl -I expects 200).

STEP 4: Attach the domains to the Vercel project (still in `site/`):
- `vercel domains add billsbounce.com`
- `vercel domains add www.billsbounce.com`
- `vercel domains add billsbounce.party`
- `vercel domains add www.billsbounce.party`
- `vercel.json` already redirects www and .party to https://billsbounce.com.

STEP 5: DNS at GoDaddy, for BOTH domains (billsbounce.com and
billsbounce.party). Set exactly these records and delete any conflicting
A/CNAME parking records GoDaddy put there:
- A record:    host `@`   value `76.76.21.21`
- CNAME record: host `www` value `cname.vercel-dns.com`
If a GoDaddy CLI is available and authenticated, use it; otherwise print
these records clearly and tell Jamey to set them in the GoDaddy DNS
dashboard. If Vercel's domain output shows different required values, the
Vercel output wins; report the difference.

STEP 6: Verify (DNS can take minutes to an hour):
- `curl -sI https://billsbounce.com` expects HTTP 200.
- `curl -sI https://billsbounce.party` expects a 308 redirect to
  https://billsbounce.com.
- `curl -sI https://www.billsbounce.com` expects a 308 to the apex.
Report each result. If DNS has not propagated yet, say so and give Jamey
the exact command to re-run later instead of looping.

DONE means: repo pushed to GitHub, production deploy live, both domains
attached, DNS records set or handed to Jamey, and the three curl checks
reported.

---

## Notes for Jamey (not part of the prompt)

- The site is one static HTML file. Content changes are text edits to
  `site/index.html`; redeploy is `cd site && vercel deploy --prod`.
- Still open, worth 5 minutes with Bill: the real Facebook page URL, any
  photos of actual inflatables (swap into `assets/` later), and whether he
  wants prices listed (current page says call, which is fine).
- billsbounce.party redirects to billsbounce.com so the trailer's painted
  URL keeps working forever.
