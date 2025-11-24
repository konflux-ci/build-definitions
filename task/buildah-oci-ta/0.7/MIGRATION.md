# Migration from 0.6 to 0.7

~~Version 0.7:~~

* ~~Changes default value of **INHERIT_BASE_IMAGE_LABELS** from `true` to `false`.~~
* ~~If you are building on top of a base image like ubi9, and you inherit all
  labels, then your resulting image will bear labels like name=ubi9 and the cpe
  label of ubi9. This makes your image look like it _is_ ubi9, which is not
  correct.~~

## ~~Action from users~~
~~No specific migration activity is required to absorb this change, however..~~

~~For any team that is not explicitly setting the name, cpe, and other required
labels, your images may begin to fail conforma policy checks until those labels
are explicitly set on your image. You were previously inheriting values
erroneously from your base image.~~

Version 0.7.1:

* Reverts the change from version 0.7. The task now inherits labels by default again.
