---
description: Install a plugin from the marketplace into project settings
---

Install a plugin from the Claude plugin marketplace into the current project's settings.

Follow these steps:

1. **Locate the marketplace repository**:

   - Read the `known_marketplaces.json` file from the user's Claude configuration directory
   - Find the marketplace entry (look for the marketplace name that matches this repository)
   - Get the path to the marketplace from the configuration

2. **List available plugins**:

   - Read the `plugins/` directory in the marketplace repository path
   - For each plugin, read its `.claude-plugin/plugin.json` file to get the name and description
   - Show the user the available plugins with their descriptions

3. **Select plugin to install**:

   - Use AskUserQuestion to let the user choose which plugin to install
   - Options should include the plugin name and description

4. **Update project settings**:

   - Check if `.claude/settings.json` exists in the current working directory
   - If not, create `.claude/` directory and `settings.json` with an empty object `{}`
   - Read the current settings.json
   - Add or update the `enabledPlugins` array to include the path to the selected plugin
   - The path should be relative or absolute to the marketplace plugin directory
   - Example settings.json entry:
     ```json
     {
       "enabledPlugins": [
         "plugin-name@marketplace-name"
       ]
     }
     ```

5. **Confirm installation and prompt restart**:

   - Inform the user that the plugin has been added to their project settings
   - Show them the value that was added to enabledPlugins
   - **Important**: Prompt the user to restart Claude for the changes to take effect
