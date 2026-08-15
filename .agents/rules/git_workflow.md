# Git & Commit Guidelines

Agents working in this repository must adhere to the following workflow for all version control operations:

1. **Successful Build Before Committing**:
   - Always verify that the project builds cleanly and tests pass before making any commit.
   - Never commit code that causes compilation errors or breaks the build.

2. **Atomic Commits**:
   - Make atomic commits where each commit encapsulates a single logical change, bug fix, or feature.
   - Avoid combining unrelated modifications, refactors, or fixes into a single commit.

3. **Conventional Commit Messages**:
   - Format all commit messages according to the [Conventional Commits](https://www.conventionalcommits.org/) specification (`<type>(<optional scope>): <description>`).
   - Use standard types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`.
   - Write clear, concise, imperative descriptions (e.g., `feat: Add fetchTimeSeriesData to MetricsService`, `fix: Resolve crash in CSVImporter`).

4. **Update Changelog on Every Commit**:
   - Update [`CHANGELOG.md`](file:///Users/tyleryang/Developer/Jobz/CHANGELOG.md) on every commit that introduces user-facing or noteworthy changes.
   - Place updates in the appropriate section under `## [Unreleased]` (`### Added`, `### Fixed`, `### Changed`, `### Removed`, etc.).
   - Include the changelog update in the same atomic commit as the corresponding code changes.
