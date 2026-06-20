---
name: resolve-github-issue
description: Resolves a specified GitHub issue by checking out a branch, fixing the issue, verifying with tests, committing, and creating a pull request autonomously without interactive questions.
---
# Resolve GitHub Issue

This skill provides step-by-step instructions on how to autonomously resolve a GitHub issue from the codebase to a Pull Request (PR) without asking interactive questions.

## Workflow

### 1. Retrieve the Issue Details
- Run the command: `gh issue view <issue_number>` to read the title, body, and comments of the issue.
- Identify the core request, bug report, or feature description.

### 2. Prepare the Working Branch
- Check out a new local branch named after the issue to isolate your changes (e.g., `git checkout -b fix-<issue_number>` or `git checkout -b feature-<issue_number>`).

### 3. Locate Relevant Code
- Use tools like `grep_search` and `list_dir` to find the files related to the issue.
- Examine file content using `view_file` to understand current behavior, logic flows, and dependencies.

### 4. Formulate the Solution
- Plan the fix or feature addition, keeping in mind the codebase architecture, existing patterns, and conventions.
- Make reasonable, logical assumptions if the issue details are slightly underspecified, avoiding any unnecessary questions to the user.

### 5. Implement the Changes
- Edit the necessary files using code-editing tools (`replace_file_content`, `multi_replace_file_content`, `write_to_file`).
- Ensure code style aligns with existing patterns and conforms to standard coding conventions.
- Retain existing comments/documentation unless they are deprecated by the change.

### 6. Verify and Test
- Run the project's build and test suites to verify that:
  - Your changes compile correctly.
  - The issue is resolved.
  - No existing tests or functionality are broken.
- Use commands like `flutter test` or project-specific test runners.

### 7. Commit the Changes
- Use conventional commit messages that accurately reflect the change type (e.g., `feat: ...`, `fix: ...`, `refactor: ...`).
- Include the issue reference (e.g., `(#<issue_number>)`) in the commit message if appropriate.
- Stage and commit the changes using `git add` and `git commit`.

### 8. Create a Pull Request
- Push the local branch to the remote repository.
- Use `gh pr create --fill` or specify the title/body to create a pull request.
- Ensure the PR description links to the issue (e.g., "Closes #<issue_number>").
