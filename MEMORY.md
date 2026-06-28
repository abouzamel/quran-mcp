


**WHO & WHAT**
The mcp.quran.ai MCP belongs to quran.com company. The mcp.quran.ai MCP source code is open source code available in github, But becuase of copy right, both its databases and both phases for seeding the DBs and the the sources are not available in the open source quran-mcp in the Github.

Tareq forked the open source code for the published **quran-mcp** project from the Github, But the code does not include DBs, any information about seeding, no resources materilas for feeding with the seeding process. 

Tareq then fined the most of the needed resources from (quran scripts from Tanzil.com, quran metadata, Mushaf, tafsir and translations from https://qul.tarteel.ai/, quranic-corpus-morphology-0.4.txt from https://corpus.quran.com  )  
Now Tareq started an under development, self-hosted MCP server, for Quranic text, translations, tafsir, and mushaf layout. 
Core goal: reverse-engineer missing DB schemas and create codes and scripts for seeding the DBs by reading SQL queries already written in the source of truth (SoT) src code.

---

**TWO MCP INSTANCES — always compare these**

| | mcp-quran-ai | quran-no |
|---|---|---|
| URL | mcp.quran.ai | quran.ai2.no |
| Role | forien company running Production MCP which si our SoT | Dev, active construction |
| Access mode | API tool calls only | Full access |
| Status | Complete & stable | schemas + seeding are under-development |

---

**THREE HELPER MCPs — all target under development  quran-mcp  quran.ai2.no @ 192.168.10.140**

**postgres MCP** — query live DB schemas and data

first DB is quran_mcp_db
| DSN | Schemas |
|---|---|
| `postgresql://quran_mcp_user:iloveiotat2025@localhost:5432/quran_mcp_db` | `quran_com` (corpus), `quran_mcp` (app runtime), `quran_mcp.edition_content` (Quran scripts, tafsir, translations) |

Second DB is goodmem_qwen_db
| `postgresql://quran_mcp_user:iloveiotat2025@localhost:5432/goodmem_qwen_db` | `goodmem` |

**shell-mcp** —  run commands on target ubuntu read src code, seeding phases, scripts, migrations, DB configs (root: `/quran-mcp`)
**filesystem MCP** — read src code, seeding phases, scripts, migrations, DB configs (root: `/quran-mcp`)

---

**ACCEPTABLE WRITABLE PATHS — Tareq only, nothing else is ever modified**
```
/quran-mcp/src/quran_mcp/lib/db/migrations/*   ← schema fixes
/quran-mcp/scripts/*                            ← seeder pipeline
/quran-mcp/.db/*                                ← DB init/config
```

---

**KEY SOURCE PATHS**
```
/quran-mcp/src/quran_mcp/          ← main Python package
/quran-mcp/src/quran_mcp/lib/      ← all library modules (db, morphology, tafsir, translation, mushaf, etc.)
/quran-mcp/src/quran_mcp/lib/db/   ← DB pool, migrations, turn manager
/quran-mcp/scripts/                ← seeder pipeline scripts
/quran-mcp/.db/                    ← DB init/config
/quran-mcp/SCHEMA_REFERENCE.md     ← The under development schema documentation (39 KB)
/quran-mcp/MEMORY.md               ← project memory (updated live)
/quran-mcp/AGENTS.md               ← agent instructions (20 KB)
```

---

**INFRASTRUCTURE**
Proxmox privileged LXC · NVMe2 · 1TB ZFS · 64GB RAM · AMD RX 5500 XT 8GB (Vulkan)

---

**HARD RULES — enforce in every session**
1. Never read files in full — always use `head_file` / `tail_file` / `peek` / `grep` first
2. Never save files directly — hand all content to Tareq in chat; he saves it himself
3. Never modify anything in `/quran-mcp/src/quran_mcp/` outside the three writable paths
4. Always run fresh MCP / filesystem / postgres queries at session start — never rely on cached state
5. On any tool failure — stop and ask Tareq before trying an alternate approach
6. Always explicitly state whether a schema structure was derived from SQL queries in src code or from the live DB — never assume or mix sources silently
7. Alway fetch mcp.quran.ai and quran.ai2.no MCPs servers by call fetch_grounding_rules first. then you get the the information about each avialble tools and how you can call them.


### Nest bugs fix 

fetch_tafsir diffs found — same scholarly text content, but three structural differences in the dev instance:

Markup differs: SoT stores inline <span class="blue/green"> highlight spans; dev wraps in <div class=ar lang=ar><p> and has stripped the highlight spans.
citation_url is null on dev (SoT = https://quran.com/ar/2/255/tafsirs?tafsirId=16).
passage_ayah_range is null on dev (SoT = 2:255).

So dev's edition_content seeding for tafsir is missing the citation_url / passage_ayah_range columns and used a different HTML-cleaning pipeline. Continuing — metadata next:
