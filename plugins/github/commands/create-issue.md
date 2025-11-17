Create a new GitHub issue in the current repository using issue templates.

Follow these steps:

1. **Check for issue templates**: Look for templates in `.github/ISSUE_TEMPLATE/` directory
   - If templates exist, list them for the user to select from
   - Use the AskUserQuestion tool to let the user choose a template
   - If no templates exist, inform the user and proceed with basic issue creation

2. **Read the selected template** (if applicable):
   - Read the template file to understand its structure
   - Identify any fields or sections that need to be filled in

3. **Gather information from the user**:
   - Ask for the issue title
   - If using a template, ask the user to provide content for each section
   - If not using a template, ask for the issue body/description

4. **Create the issue**:
   - Use `gh issue create --title "..." --body "..."` to create the issue
   - If templates support it, you can use `gh issue create --template <template-name>` but you'll still need to fill in fields
   - Show the user the created issue URL

5. **Handle errors gracefully**: If issue creation fails, explain the error to the user
