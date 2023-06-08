# slack-webhook-notification task

Sends message to slack using incoming webhook

## Parameters
|name|description|default value|required|
|---|---|---|---|
|message|Message to be sent||true|
|secret-name|Secret with least one key where value is webhook URL for slack. eg. oc create secret generic my-secret --from-literal team1=https://hooks.slack.com/services/XXX/XXXXXX --from-literal team2=https://hooks.slack.com/services/YYY/YYYYYY |slack-webhook-notification-secret|false|
|key-name|Key in the key in secret which contains webhook URL for slack.||true|

