# **audit-list-maker**
Creates text files that list the files in all directories on a media drive.

## Project Background

We have a large collection of not-so-important media files, stored on an external drive.
Even if we lost this content due to drive failure, accidental formatting (oops), physical damage etc, the process of reacquiring this content would be trivial, so we're not bothered about going to the effort of backing it up.
All we'd need in order to go about rebuilding would be an up to date listing of those media files.

Although it's a pretty trivial task to create such summary listings in text files, perhaps issuing the command...

``` bash
ls -R /media/algo/media_device > ~/audit_dir/media_file_lists
```

... this program provides additional functionality like:

- Configuring multiple source and destination directories.
- Configuring which directories to ignore.
- Configuring which listings of secret files to encrypt.


---
:cd: >> :file-folder:



