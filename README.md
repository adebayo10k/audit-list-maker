Welcome
===

The purpose of this GitHub repository is to be a source of ideas for anyone interested.
Clone, fork as you wish. This project is being updated over time.

Creating audit listings
===

**audit-list-maker** creates text files that list the contents of all directories on a media drive when the backup of that content is not really justified.

Project Background
===

We have a large collection of important media files, stored on an external drive.
Even if we lost this content due to drive failure, accidental formatting (oops), physical damage etc, the process of reacquiring this content would be trivial, so we're not bothered about going to the expense of backing it up.
All we'd need in order to go about rebuilding would be an up to date listing of those media files.

Although it's a pretty trivial task to create such summary listings in text files - I've been issuing the following command from time to time...

`ls -R /media/algo/media_device > ~/audit_dir/media_file_lists`

... I wanted to build a program around such a command that could be configured by the user. Additional functionality like specifying which source and destination directories to use, which directories to ignore and which listings of secret files to encrypt could then be offered to the user (me) at runtime.

---
:cd: >> :file-folder:



