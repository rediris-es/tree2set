tree2set
========

Perl script to generate a Junos "set file" from a tree configuration , use as a filter:

 tree2set.pl < config-file > config.set

currently is generic so it will work (most of less) with any vendor config file that use a configuration similar to  Junos.

About comments:

Two options for comments

--nocom == remove the comments /\* ..... \*/ from the output needed as this line is invalid

set snmp /\* Warnings  \*/ trap-group name version v2

--annotate == Remove the commments from the code, but also generate at the end edit/annotate sequences  with the comments

set snmp  trap-group name  version v2

and at the end

edit snmp
annotate   trap-group Avisos version v2  " Avisos urgentes "

Note this last part has not been tested

