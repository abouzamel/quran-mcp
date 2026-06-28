Here's the picture: 
after Flyway runs, GoodMem has an empty schema in goodmem_qwen_db — tables exist, but zero users, zero API keys, zero spaces. It's running but locked: every API call 401s because no key exists yet. The job now is to create the root identity, then point your app at it.

Step-by-step (after Flyway completes)

Step 1 — Confirm the DB is fresh (0 users).
docker exec -it db psql -U quran_mcp_user -d goodmem_qwen_db -c \
  "SELECT count(*) FROM goodmem.\"user\";"

Expect 0. If 0, you bootstrap. If not 0, it's already initialized — skip to Step 3 and find the existing key instead.

Step 2 — Bootstrap the root user + API key (one unauthenticated call).
This is the step that confused you. GoodMem has a built-in REST endpoint, POST /v1/system/init, that works once on a fresh DB with no auth. It creates the root user and prints the first API key. 
That's the entire bootstrap — no Go CLI, no SDK, no private repo needed.

curl -sk -X POST https://localhost:8080/v1/system/init \
  -H "Content-Type: application/json" -d '{}'

It returns JSON like:
{"alreadyInitialized":false,"message":"System initialized successfully",
 "rootApiKey":"gm_xxxxxxxxxxxx","userId":"019e..."}

json{"alreadyInitialized":false,"message":"System initialized successfully","rootApiKey":"gm_coxrd47fiztqhm2qf3srpn52ae","userId":"019eee78-58e0-74..."}

"alreadyInitialized":false = success, this was a real fresh init.
"alreadyInitialized":true = it was already done; the key won't be re-shown (you'd need to mint a new one with an existing key).

Copy rootApiKey immediately — it's shown only once. Save it somewhere durable.

Step 3 — Put the key into .env.
dotenvGOODMEM_API_KEY=gm_xxxxxxxxxxxx
(Replace the old value.)

Step 4 — Restart the app so it picks up the key.
Only the app container reads GOODMEM_API_KEY for space discovery. Restart just it:
docker compose up -d app

Step 5 — Verify the 401 is gone.
docker compose logs --tail=40 app | grep -iE "goodmem|space|401|200"
You want the GoodMem init line to succeed (200), not the earlier init failed (401). It will report 0 spaces — correct, because a fresh DB has none yet.

Step 6 — Confirm identity persisted.
docker exec -it db psql -U quran_mcp_user -d goodmem_qwen_db -c \
  "SELECT user_id, display_name FROM goodmem.\"user\"; \
   SELECT api_key_id, user_id, status FROM goodmem.apikey;"
Expect exactly one user and one active key.

