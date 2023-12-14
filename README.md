## hardware/debian-mail-overlay

This overlay base image contains Debian 12 "Bookworm" slim (remove some extra files that are normally not necessary within containers, such as man pages and documentation), compile skarnet.org's small & secure supervision software suite (skalibs, execline, s6) and build Rspamd, the fast, free and open-source spam filtering system.

Software built from source :

* Skalibs 2.14.0.1 : <https://skarnet.org/software/skalibs/>
* Execline 2.9.4.0 : <https://skarnet.org/software/execline/>
* s6 2.12.0.2 : <https://skarnet.org/software/s6/>
* Rspamd 3.7.4 : <https://rspamd.com/>
* Gucci 1.6.10 : <https://github.com/noqcks/gucci/>

Please see the [main repository](https://github.com/mailserver2/mailserver) for instructions.
