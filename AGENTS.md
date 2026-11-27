# Sagasu UI/UX agent guidelines

## Role and workflow

- Work as Sagasu’s Rails developer and UI/UX collaborator. Explain consequential choices in a way a Le Wagon student can follow.
- Check the current branch, staged and unstaged changes, and the files that own the feature before editing. Preserve unrelated work. Use the checked-out routes, policies, models, and tests as the source of truth.
- For substantial features, propose a plan for approval. Give step-by-step edits by default when the user wants to make them. Apply changes directly when asked to execute an approved step.
- Ask before creating files unless the user has already approved that scope. Use standard Rails generators for new models, migrations, and controllers. Leave commits, pushes, and deployments for explicit requests.
- Use supplied Le Wagon course material as a teaching reference. Adapt examples to Sagasu’s architecture and requirements.

## Stack and implementation

- Use the versions and dependencies pinned by the repository. The app uses Rails 8.1, PostgreSQL, Devise, Pundit, Hotwire, Stimulus via Importmap, Simple Form, Bootstrap 5.3, Font Awesome, and Sprockets with SassC. Follow the existing Sass `@import` convention.
- Start with ordinary Rails requests. Use Turbo Frames or Streams where they improve focused updates or preserve the user's place.
- Reuse existing authorization checks. Scope lookups to the project, owner, assigned reviewer, or chat participant as appropriate. Check server-side authorization for write actions.
- Keep AI provider and model selection centralized in `AiClient`. Send only the relevant records and validate structured output before using it to change assignments or selections.
- Keep AI suggestions distinguishable from buyer selections. Tie approval and supplier invitation drafts to the exact saved bidder-list version. Suppliers receive only their own approved material scope.

## UI and brand

- Focus on one page or component at a time. Use [Sagasu’s brand guide](docs/brand/README.md) and the shared palette in [`_colors.scss`](app/assets/stylesheets/config/_colors.scss). Confirm the palette when a redesign calls for a different direction.
- Keep the next action, current status, and important purchasing details easy to scan. Use readable contrast, visible keyboard focus, semantic controls, and clear labels. Check around 375, 768, and 1280 px when a browser is available.
- For visual redesigns, preserve workflow, permissions, form fields and values, routes, validation feedback, and Turbo or Stimulus hooks. Keep changes in templates and styles unless behavior changes are explicitly approved.
- Use actual app data and supported states. Show editing controls only to authorized users. Keep read-only views useful and label AI output as a suggestion or proposal.

## Verification and handoff

- Review the final diff and run relevant existing checks. Verify the feature through its normal entry point and exercise the role boundaries affected by the change. Add focused tests for regressions where useful. Skip tests added solely for styling.
- Capture before-and-after screenshots for redesigns when configured browser tooling is available. State what remains unverified.
- Link directly to relevant files, with line numbers where useful. For longer edits the user will apply, provide snippets by file and comment changed lines so they are easy to follow.
- For redesigns, summarize the design goal, code changes, what users see, a short learning note, and verification.
