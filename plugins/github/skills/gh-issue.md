# GitHub Issues Management Skill

You have access to the `gh issue` command for managing GitHub issues from the command line.

## Common Operations

### Creating Issues
- `gh issue create` - Interactive issue creation
- `gh issue create --title "..." --body "..."` - Create with title and body
- `gh issue create --label bug,priority` - Add labels during creation
- `gh issue create --assignee @me` - Assign to yourself
- `gh issue create --milestone "v1.0"` - Assign to milestone

### Listing Issues
- `gh issue list` - List open issues
- `gh issue list --state all` - List all issues (open and closed)
- `gh issue list --label bug` - Filter by label
- `gh issue list --assignee @me` - Filter by assignee
- `gh issue list --author username` - Filter by author

### Viewing Issues
- `gh issue view <number>` - View issue details
- `gh issue view <number> --web` - Open issue in browser

### Updating Issues
- `gh issue edit <number> --title "New title"` - Update title
- `gh issue edit <number> --body "New description"` - Update body
- `gh issue edit <number> --add-label bug` - Add labels
- `gh issue edit <number> --remove-label feature` - Remove labels
- `gh issue edit <number> --add-assignee user` - Add assignee

### Closing and Reopening
- `gh issue close <number>` - Close an issue
- `gh issue close <number> --comment "Fixed in PR #123"` - Close with comment
- `gh issue reopen <number>` - Reopen an issue

### Comments
- `gh issue comment <number> --body "Comment text"` - Add comment to issue

## Best Practices

1. Always use `--title` and `--body` for programmatic issue creation
2. Add relevant labels to help with organization
3. Reference related issues or PRs in the body using #number syntax
4. Use markdown formatting in issue bodies for better readability
5. When creating issues, provide clear, actionable descriptions

## Issue Templates

When creating issues, check for issue templates in the repository:
- Templates are typically in `.github/ISSUE_TEMPLATE/` directory
- Use `gh issue create --template <template-name>` to use a template
- List available templates by checking the `.github/ISSUE_TEMPLATE/` directory
- If templates exist, prefer using them to maintain consistency
- Templates may define fields that need to be filled in

## Issue Body Formatting

Issue bodies support GitHub Flavored Markdown:
- Use `## Headings` for structure
- Use bullet lists for steps or requirements
- Use code blocks with ``` for code examples
- Use `> quotes` for important notes
- Use checkboxes `- [ ]` for task lists
