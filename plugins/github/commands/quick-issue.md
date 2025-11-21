Create a GitHub issue quickly using conversation context as the issue body.

Arguments: `[title]` (optional) - The issue title

Follow these steps:

1. **Get the issue title**:

   - If a title argument was provided, use it
   - If no title was provided, use the AskUserQuestion tool to prompt for a title

1. **Generate issue body from context**:

   - Analyze the recent conversation to understand what the issue is about
   - Create a well-structured issue body that includes:
     - A brief summary of the problem or feature request
     - Relevant details from the conversation (e.g., error messages, code snippets, context)
     - Any steps to reproduce (if applicable)
     - Expected vs actual behavior (for bugs)
   - Keep it concise but informative

1. **Create the issue**: Follow the implementation guidelines in the gh-issue skill

   - Use HEREDOC format for multiline bodies
   - Use GitHub Flavored Markdown for formatting
