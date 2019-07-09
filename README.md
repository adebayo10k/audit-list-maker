Welcome
===

The purpose of this GitHub repository is to be a source of ideas for anyone interested.
Feel free to download or fork any of the work contained here. This project is being updated over time.

Creating audit listings
===

**audit_list_maker** creates independently (on a separate device) stored 'reference listings' of the media files on a drive when the backup of those files is not justified.

**Use Case:**
We have a large collection of media files, stored on an external drive.
Even if we lost this content due to drive failure, accidental formatting (oops), physical damage etc, the process of reacquiring this content would be trivial, so we're not bothered about backing it up.
All we'd need in order to go about rebuilding would be an up to date listing of those media files.

Project Background
===
By *audit* I just mean a text file 'nested summary of all the directories and files contained on a device'. This might be most useful when we have hundreds or even thousands of these files. The word *audit* was the most appropriate noun I could think of, but I'll probably change that if I come across something better. Any ideas?

Although it's a pretty trivial task to create such a text file audit - I've been issuing the following command from time to time...

`ls -R /media/algo/media_device > ~/audit_dir/media_file_lists`

... I wanted to build a configurable program around such a command. Additional relevant functionality (like encryption of audit data) could then be added later.

---

**Getting creative** by solving problems.


That's the purpose of this project.



