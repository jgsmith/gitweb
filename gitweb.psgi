#! /usr/bin/perl

use lib './lib';

use strict;
use warnings;

use MITH::GitWeb;

MITH::GitWeb -> new(
  root => '/home/jgsmith/Code/MITH-GitWeb/git/',
  #root => '/media/sf_Downloads/git/',
  tracing => 1,
);
