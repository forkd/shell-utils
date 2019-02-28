# shell-utils
This repository is just a compilation of all relevant Shell Scripts I already wrote.  Note that some of those are too old and maybe doesn't work anymore, so test them before using in production.

-----
## Capivara
Some pentesters prefer to setup their own testing machines, instead of using distributions like Kali.  While it is good to have a distro with only those tools you'll really use, the process to configure this computer and install certain tools could be very frustrating.  The idea of this project is to aggregate installers and setup routines I use to configure my own pentest machine based on Fedora 25 Linux.

### Networking
Networking tools are pretty important to evaluate any scenario.  This Docker image aggregates some of these tools inside a container.

```
# docker build -f capivara .  # builds up a container using the provided dockerfile
# docker run capivara sh      # instatiates a container with a shell 
```

### Installation

```
$ git clone https://github.com/forkd/capivara
$ cd capivara/scripts
$ for s in *; do sudo bash "$s"; done
```

### Password Tools

#### Hashcat
Hashcat is a powerful password ~~cracker~~ recovery tool.  Note: in order to properly work, Hashcat requires third-party drivers for OpenCL, such as Intel, AMD, Nvidia, and so on.  For Intel for example, you must access [their driver's page](https://software.intel.com/en-us/articles/opencl-drivers#latest_CPU_runtime), download the CPU/GPU driver package, untar it, and install the RPMs<sup>1</sup>.

```
$ echo -n "capivara" |md5sum |tr -d " -" > passwd  # create the file with hashed pass
$ hashcat -m 0 -a 3
$ hashcat --help  # useful help
```

<sup>1</sup> Luckly, `dnf` does all the job for us:
```
$ unzip SRB4.1_linux64.zip -d "intel-opencl"
$ cd intel-opencl
$ sudo dnf install ./*rpm
```

#### John The Ripper
John the Ripper is a well known password cracker distributed in, at least, 2 versions, the default and the "Jumbo" version.  Capivara installs John both, by `dnf` package and Jumbo by compiling --it is stored under `/tmp` directory and must be executed locally.

```
$ john  # displays help
$ sudo /etc/JohnTheRipper-1.8.0-jumbo-1/run/john  # jumbo help
```

### DoS Tools

#### Low Orbit Ion Cannon (LOIC)
Originally written for Windows, LOIC is an open source network stress tool.  It can be executed under Linux either with Mono or Wine --this project uses the first option.

```
$ loic.sh  # LOIC is GUI-based and self explanatory
```

#### Slowloris (Perl)
This is the original version of Slowloris.  Although it works fine nowadays, this code isn't been updated for a while.  This Slowloris 0.7 was released on 2009-17-06.

```
$ slowloris.pl -dns 192.168.200.48
$ perldoc slowloris.pl  # a very useful help
```

### Slowloris (Python)
Some guys rewrote Slowloris in Python and this is the result of their job.  This is a straight forward software, so reading the help page is enough to learn how it works.  The main difference between the Slowloris versions (Perl & Python) is that this has no extension and the other ends with `.pl`.

```
$ sudo slowloris -s 1000 192.168.200.48
$ sudo slowloris -h  # for help
```

-----
## Pilsner
Pilsner was my personal external HDD backup system.  I chose which folders inside my `$HOME` dir should be backed up, and it syncs all files, managing file changes. 

### `pilsner.sh`
Pilsner uses [rsync](https://rsync.samba.org/) to make all the magic between the sources and target directories.  The help message will bring everything you need to know to start using Pilsner.

### About
Why "Pilsner"?  Because when I started coding this program, in September 7th, 2016, I had no idea of names to it.  As I was drinking a pilsner-style beer, I decided to use that name.  :D


## Weback
Weback was first designed to used in shared web servers, to backup the user's files and MySQL databases.  These files were filled in the server and mirrored in Dropbox.  Nowadays, Weback can be used even in personal systems and to backup whatever directory the user chooses.

### Usage
Run Weback with `-h` option to view the complete help:

`$ ./weback.sh -h`

To backup all files [and directories] under your home directory, as well as your databases, and send an email to confirm that:

`$ weback.sh -s $HOME -m foo:bar:localhost -e me@example.com`

Note that MySQL informations are separated by colons: `user`, `password` and `hostname`.  [Dropbox Uploader](https://github.com/andreafabrizi/Dropbox-Uploader) must be set before start mirroring files.  Save Dropbox Uploader inside `weback/dbu`.

Alternatively you can set your server's name:

`$ ./weback.sh -n Foobar -s $HOME -m foo:bar:localhost -d -e me@example.com`

You can even define where the files will be saved in the host, like:

`$ ./weback.sh -n Foobar -m foo:bar:localhost -t /var/local/foobar`

Now, with `--keep` option, you're able to set the maximum number of files that will be kept in your backup directory.  It's turned off by default, but to use it, do as the example below, where only the latest 3 files will be kept.

`$ ./weback.sh -n Foobar -s "$HOME" -t /var/local/backup -k 3`

### Notes

* Grant execution permissions to `weback.sh` and `dbu/dropbox_uploader.sh`.
* When using the `-t` option, remember to check out if the user have write permissions in target.

### Examples
I have 2 servers on my job where I use Weback.  I configured Weback in one of them like this: first, I cloned Weback there.  Then, I created the directory `agulha` to store the backups in `/var/local`, changed its ownership for my user and added a line in my user's crontab to run Weback every fridays, at 1 AM:

`0 1 * * 5 /home/lopes/weback/weback.sh -n Agulha -m user:pass:localhost -t /var/local/agulha`

As you can notice, I didn't want to mirror the backup in Dropbox.  So, I run `rsync` in my workstation to sync with the backup directory, like:

`$ rsync -e "ssh -s 12345" -avz lopes@10.0.1.2:/var/local/agulha /home/lopes/Documents/backups`

And that's all.  With this I have a copy of MySQL databases in my machine and in the server.  If I wanted to, I could use Dropbox and mirror the backup there and have a third copy of my files.


-----
## Narkissos
Narkissos is an image manipulation tool in batch.  It can handle all image files inside a directory tree with a single command.  Furthermore, Narkissos can generate thumbnails and set the names of each image file.

### Usage
Run Narkissos with -h option to view help:

`$ ./narkissos -h`

To edit only the pictures inside `~/Pictures`, change the dates, normalize colors, file names, set the size to 700 pixels and creating thumbnails:

`$ narkissos.sh -p ~/Pictures -f -d -n -s 700 -t`

To edit recursively the pictures in `~/Puctures/handle-this`, change the file names, normalize colors, set the size to 700 pixels, create thumbnails and with verbosity:

`$ narkissos.sh -p ~/Pictures/handle-this -f -n -s 700 -t -v -r`

### Notes

* Some file systems could lead to case insensitive filename check.  For example: `DSC001.JPG` could be equal to `dsc001.jpg`.  So, the new name of this file would be `_dsc001.jpg`.


## License
All scripts are released under MIT license.  Third party softwares have their own licenses.
