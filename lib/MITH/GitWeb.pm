package MITH::GitWeb;

# ABSTRACT: Exposes a git repo as a REST service

use strict;
use warnings;

use MITH::GitWeb::Resource;

use Carp qw( confess );

use parent 'Web::Machine';

sub new {
  my($class, %args) = @_;

  (exists $args{'root'})
     || confess 'You must pass in a directory path to the root git repository area';

  $args{'resource'} ||= 'MITH::GitWeb::Resource';
  
  $class->SUPER::new( %args );
}

sub create_resource {
  my($self, $request) = @_;

  my $resource = $self->SUPER::create_resource($request);
  $resource->root($self->{'root'});
  $resource;
}

1;
