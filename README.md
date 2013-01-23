GitWeb
======

This is a simple REST interface for accessing versions of files in a
Git repo based on date/time using the Accept-Datetime header. 

This requires the Web::Machine version in https://github.com/jgsmith/webmachine-perl.

Tweak the configuration in gitweb.psgi to point to where the git repos are
stored on the filesystem.

We require the following modules (plus a few that are standard with Perl):

* DateTime::Format::Strptime
* DateTime::Infinite
* File::Type
* Moose
* VCI
* Web::Machine
