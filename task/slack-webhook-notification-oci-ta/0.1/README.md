# slack-webhook-notification-oci-ta task

Sends message to slack using incoming webhook

## Parameters
|name|description|default value|required|
|---|---|---|---|
|SOURCE_ARTIFACT|The Trusted Artifact URI pointing to the artifact with the application source code.||true|
|files|List of file to dump. The content will be added to the message.|[]|false|
|group-ids|List of Slack group IDs to mention (e.g., S0614TZR7). If set, the groups will be mentioned in the notification.|[]|false|
|key-name|Key in the key in secret which contains webhook URL for slack.||true|
|message|Message to be sent||true|
|secret-name|Secret with at least one key where value is webhook URL for slack. eg. oc create secret generic my-secret --from-literal team1=https://hooks.slack.com/services/XXX/XXXXXX --from-literal team2=https://hooks.slack.com/services/YYY/YYYYYY |slack-webhook-notification-secret|false|
|submodules|List of submodules name to dump. Git log since previous submodule commit will be added to the message. The previous submodule commit is found by looking at the previous commit in the repository that declares the submodules.|[]|false|
|user-ids|List of Slack user IDs to mention (e.g., U024BE7LH). If set, the users will be mentioned in the notification.|[]|false|


## Additional info
