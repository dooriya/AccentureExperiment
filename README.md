# Reuse Existing Resources for Deployment

This is a sample notification app for demonstrating reuse existing resources for app deployment.

## Scenario
Customers don't have the permission to provision resources in a target Azure environment and M365 tenant (e.g. a `prod` environment), but they still want to deploy the app against the pre-provisioned resources.

So the toolkit should allow customers to skip provisioning all resources for a remote environment, including
  - Teams app registration
  - Bot service (including the bot AAD app)
  - Bot web app

And generate a state file for deployment.

## Assumptions
- All azure resources are already provisioned and correctly configured in an existing subscription and resource group.
- The AAD app and Teams app are already provisioned in the target M365 tenant.
- Customers have the permission to deploy to the existing web app.

## Solutions

- If you don't really need to do the provision at all you can simply go for solution 1.
- If you may need our toolkit to provision some of the resources, for example, some resources need to be reused, some need to be provisioned by our tools, then you can go to solution 2 for bicep customization.

### Solution 1
Manually create the `state.<env>.json` and provide necessary information for app deployment/preview contract.

1. [Create a new environment](https://docs.microsoft.com/en-us/microsoftteams/platform/toolkit/teamsfx-multi-env#create-a-new-environment) (e.g. a `prod` environment) for integration with pre-provisioned resources (including Teams app registration, Bot service, Bot Web app)

2.  Add a `state.prod.json` file in the `.fx\states` folder, and add the following config for app deployment and preview.
    - the `solution` and `fx-resource-bot` is the deployment contract for bot.
    - The `fx-resource-appstudio` contains the Teams app registration info which can be used for app preview.

    ```json
    {
        "solution": {
            "subscriptionId": "<Your Azure subscription ID>",
            "resourceGroupName": "<Your resource group name>",
            "provisionSucceeded": true
        },
        "fx-resource-appstudio": {
            "tenantId": "<Your M365 tenant ID>",
            "teamsAppId": "<Your Teams App ID>"
        },
        "fx-resource-bot": {
            "botWebAppResourceId": "<Your bot web app resource ID, e.g. /subscriptions/mysub/resourceGroups/myrg/providers/Microsoft.Web/sites/mywebapp>",
            "siteEndpoint": "<The site endpoint of your bot web app>"
        }
    }
    ```
3. Run `Teams: Deploy to the cloud` to deploy the app code to the `prod` environment.

4. Open the debug panel (`Ctrl+Shift+D` / `⌘⇧-D` or `View > Run`) from Visual Studio Code, select `Launch Remote (Edge)` or `Launch Remote (Chrome)` to preview your remote app.

### Solution 2
Customize the environment config files and BICEP template to let toolkit automatically generate the `state.<env-name>.json` for deployment.

You can refer to [this commit](https://github.com/dooriya/AccenstureExperiment/commit/ef6c8b055e7773cd60073db4de307bae9ae9e9f3) related code change.

1. [Create a new environment](https://docs.microsoft.com/en-us/microsoftteams/platform/toolkit/teamsfx-multi-env#create-a-new-environment) (e.g. a `prod` environment) for integration with pre-provisioned resources (including Teams app registration, Bot service, Bot Web app)

2. Set your bot password in environment variable, e.g. `BOT_PASSWORD_PROD`.

3. Modify [`config.prod.json`](https://github.com/dooriya/AccenstureExperiment/blob/main/.fx/configs/config.prod.json) to include the following section:
    ```json
    "azure": {
        "subscriptionId": "<Your existing subscription id>",
        "resourceGroupName": "<Your existing resource group name>"
    },
    "bot": {
        "appId": "<Your existing app id for your bot service>",
        "appPassword": "{{$env.BOT_PASSWORD_PROD}}"
    }
    ```

4. Modify the [`azure.parameters.prod.json`](https://github.com/dooriya/AccenstureExperiment/blob/main/.fx/configs/azure.parameters.prod.json) to include the following content for your existing bot service and bot app:
    ```json
    "existingSubscription": "<Your existing subscription id>",
    "existingResourceGroup": "<Your existing resource group name>",
    "botServerfarmsName": "<The service plan of your existing bot app>",
    "botWebAppSKU": "<The SKU of your existing bot web app>",
    "botSitesName": "<The app name of your existing bot web app>",
    "botServiceName": "<The existing bot service name>"
    ```
5. Modify the bicep template in `templates\azure` folder:
    - `main.bicep`: comment out or remove the ` teamsFxConfig` section since we assume that the existing bot app is correctly configured.
    - `provision.bicep`: comment out or remove the `userAssignedIdentityProvision` section to skip creating user-assigned identity for the bot app.
    - `provision\bot.bicep`: re-sue existing resource for bot service and bot web app.

    > Please refer to [this commit](https://github.com/dooriya/AccenstureExperiment/commit/ef6c8b055e7773cd60073db4de307bae9ae9e9f3) related code change or just copy-paste those files.

6. Manually add a `state.prod.json` file in the `.fx\states` folder, and add the following config for your existing Teams app info.
    ```json
    "fx-resource-appstudio": {
        "tenantId": "<Your M365 tenant id where your app has been registered>",
        "teamsAppId": "<Your Teams App ID>"
    }
    ```

> Note: this is a workaround since current toolkit is not able to configure the existing Teams App info through `config.<env-name>.json`.

7. Run `Teams: Provision in the cloud` against the `prod` environment to generate resource info in `state.prod.json`.
In this step

8. Run `Teams: Deploy to the cloud` to deploy the app code to the `prod` environment.

9. Open the debug panel (`Ctrl+Shift+D` / `⌘⇧-D` or `View > Run`) from Visual Studio Code, select `Launch Remote (Edge)` or `Launch Remote (Chrome)` to preview your remote app.

## Feedback / Improvement for Toolkit
- Toolkit should be able to skip provision Teams app registration by customizing the env config file (e.g. `config.prod.json`).
- More explicit contract for Teams app deployment. The app deployment should not depends on the whole `state.<env-name>.json`, ideally it only requires user to provide the web app's info for the bot code deployment. 
- More explicit contract for integration with existing resources.