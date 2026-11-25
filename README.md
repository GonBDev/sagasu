Rails app generated with [lewagon/rails-templates](https://github.com/lewagon/rails-templates), created by the [Le Wagon coding bootcamp](https://www.lewagon.com) team.

## Local demo accounts

After installing dependencies and setting up PostgreSQL, apply the migrations and seed the development database. Replace the example password with one you choose for local testing.

```sh
SAGASU_DEMO_PASSWORD='pick-a-local-demo-password' bin/rails db:prepare
SAGASU_DEMO_PASSWORD='pick-a-local-demo-password' bin/rails db:seed
```

Use the same password in both commands. On a fresh database, `db:prepare` may seed the accounts before `db:seed` runs.

Start the app with `bin/rails server` and sign in with one of these addresses. All newly seeded accounts share the password supplied at creation.

| Email | Grants in addition to BASE |
| --- | --- |
| `base@sagasu.ai` | — |
| `buyer01@sagasu.ai` | Buyer |
| `buyer02@sagasu.ai` | Buyer, Approver |
| `boss@sagasu.ai` | Approver |
| `manager@sagasu.ai` | Approver, Viewer |
| `keyuser@sagasu.ai` | Key User |
| `auditor@sagasu.ai` | Auditor |
| `admin@sagasu.ai` | Admin |

For repeated use, set `SAGASU_DEMO_PASSWORD` in your local `.env` and run `bin/rails db:seed`. Reruns preserve existing accounts, passwords, and grants. These accounts are seeded only in development.





FOR seed-supplier.yml
A local seed-supplier.yml at the Sagasu project root gives you a file you can prepare separately and load with bin/rails db:seed

Require erp_vendor_id and name for each seed row. The app allows suppliers without an ERP ID, but the seed needs a stable key. Quote identifiers to preserve leading zeroes.
Use the existing supplier column names. Keep contact and location fields optional. Use two-letter country codes, YAML booleans for active, and a YAML list for tags. Leave tax IDs, supplier-management IDs, and AI comments out of the starter data.
Update matching suppliers by ERP ID. Apply the fields present in the YAML and preserve omitted fields. Keep suppliers absent from the file. If a row is invalid or an ID appears twice in the file, report the offending row and roll back the batch.
Commit fictional demo data. Use DEMO- IDs and example.test contacts. Include overlapping capabilities for future search tests, plus one inactive supplier and one without an email.
