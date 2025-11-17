Initialize basic GitHub issue templates in the current repository.

Follow these steps:

1. **Check if templates already exist**:
   - Look for `.github/ISSUE_TEMPLATE/` directory
   - If templates already exist, ask the user if they want to overwrite them

2. **Create the template directory**:
   - Create `.github/ISSUE_TEMPLATE/` if it doesn't exist

3. **Copy template files**:
   - Read the template files from the plugin's `templates/` directory:
     - `bug_report.md` - For bug reports
     - `feature_request.md` - For feature requests
   - Create these files in `.github/ISSUE_TEMPLATE/`

4. **Confirm completion**:
   - List the created templates
   - Inform the user that issue templates are now available
   - Suggest using `/create-issue` to create issues with these templates
