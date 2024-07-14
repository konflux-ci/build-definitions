# Migration from 0.1 to 0.2
The default values for `COMPOSE_INPUTS` and `COMPOSE_OUTPUTS` parameters was changed.

## Action from users
If you were using the default value for those parameters, you should manually set them
to their previous defaults before upgrading in order to retain the same behavior.

Consult the table below for the old and updated defaults:

| Parameter Name  | Old Default         | New Default                   |
| ---             | ---                 | ---                           |
| COMPOSE_INPUTS  | compose_inputs.yaml | source/compose_inputs.yaml    |
| COMPOSE_OUTPUTS | repos               | fetched.repos.d               |
