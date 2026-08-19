/**
 * Commit message rules — Conventional Commits.
 *
 * A `.js` file rather than `.commitlintrc.json` so these comments can live
 * here. The package is `"type": "module"`, hence `export default` and not
 * `module.exports`.
 *
 * Format enforced:
 *
 *   type(optional-scope): subject
 *
 *   optional body
 *
 *   optional footer
 *
 * Run `pnpm exec commitlint --print-config` to see every active rule.
 */
export default {
  extends: ["@commitlint/config-conventional"],

  rules: {
    // The allowed types. This is config-conventional's default list, spelled
    // out here so it is visible rather than inherited silently.
    "type-enum": [
      2,
      "always",
      [
        "feat", // a user-facing feature
        "fix", // a bug fix
        "docs", // documentation only
        "style", // formatting, no behaviour change
        "refactor", // neither a fix nor a feature
        "perf", // performance
        "test", // tests
        "build", // build system, dependencies
        "ci", // CI configuration
        "chore", // everything else
        "revert", // reverts a previous commit
      ],
    ],

    // 100 characters matches the `printWidth` in .oxfmtrc.json, so a subject
    // line and a line of code wrap at the same place.
    "header-max-length": [2, "always", 100],

    // Forces a lowercase first letter: `feat: add x`, never `feat: Add x`.
    // Beware the names — "upper-case" means ALL CAPS and "pascal-case" means
    // AddX; a plain leading capital is "sentence-case". Listing only the first
    // two would silently loosen config-conventional's default rather than
    // restate it.
    //
    // Trade-off: this also rejects a leading acronym, so write
    // `fix: ci workflow fetch depth`, not `fix: CI workflow fetch depth`.
    // Drop to `1` to make it a warning instead of a hard failure.
    "subject-case": [2, "never", ["sentence-case", "start-case", "pascal-case", "upper-case"]],
  },
};
