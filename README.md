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
