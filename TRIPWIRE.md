# How to install and configure Tripwire on Suse Leap

Just use zypper to install.

```sh
zypper install tripwire
```

then create the local and the site keyfiles.

```sh
twadmin --generate-keys --local-keyfile /etc/tripwire/server29-local.key
twadmin --generate-keys --site-keyfile /etc/tripwire/site.key
```

then create the config file
```
twadmin --create-cfgfile -S /etc/tripwire/site.key /etc/tripwire/twcfg.txt
```

create a file in `/etc/tripwire/` called `twpol.txt` and add this content:

```
 (
  rulename = "Tripwire Data Files",
  severity = 100
)
{
  /var/lib/tripwire                    -> $(Dynamic) -i ;
  /var/lib/tripwire/report             -> $(Dynamic) (recurse=0) ;
}

(
  rulename = "Root & Home",
  severity = 100
)
{
  /                                    -> $(IgnoreAll) (recurse=1) ;
  /home                                -> $(IgnoreAll) (recurse=1) ;
}

(
  rulename = "System Directories",
  severity = 100
)
{
  /bin                                 -> $(IgnoreNone)-SHa ;
  /boot                                -> $(IgnoreNone)-SHa ;
  /etc                                 -> $(IgnoreNone)-SHa ;
  /lib                                 -> $(IgnoreNone)-SHa ;
  /opt                                 -> $(IgnoreNone)-SHa ;
  /root                                -> $(IgnoreNone)-SHa ;
  /sbin                                -> $(IgnoreNone)-SHa ;
  /usr                                 -> $(IgnoreNone)-SHa ;
}
```

then copy config and rules:

```sh
cp twcfg.txt tw.cfg
cp twpol.txt tw.pol
```

and create the polfile

```sh
twadmin --create-polfile -S site.key /etc/tripwire/twpol.txt
```

now we can initiate the database

```sh
tripwire --init
```

and check if it all works

```sh
tripwire --check
```

[sources](https://www.security-exposed.com/2018/04/installing-tripwire-on-suse.html)

