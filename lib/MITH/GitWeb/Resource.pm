package MITH::GitWeb::Resource;

use Moose;
extends 'Web::Machine::Resource';

use DateTime::Infinite;
use File::Type;
use VCI;

use DateTime::Format::Strptime qw[
    strftime
    strptime
];

has root => (
  is => 'rw',
  isa => 'Str',
);

has _git => (
  is => 'rw',
  lazy => 1,
  default => sub {
    VCI->connect(
      type => 'Git',
      repo => $_[0] -> root . '/' . $_[0] -> repo,
    );
  },
);

has _ft => (
  is => 'rw',
  lazy => 1,
  default => sub { File::Type -> new },
);

has repo => (
  is => 'rw',
  lazy => 1,
  default => sub {
    my $path = $_[0] -> request -> path;
    $path =~ m{^/([^/]+)/};
    $1;
  },
);

has project => (
  is => 'rw',
  lazy => 1,
  default => sub {
    my $path = $_[0] -> request -> path;
    $path =~ m{^/[^/]+/([^/]+)/};
    $1;
  },
);

has _project => (
  is => 'rw',
  lazy => 1,
  default => sub {
    $_[0] -> _git -> get_project( name => $_[0] -> project )
  },
);

has file => (
  is => 'rw',
  lazy => 1,
  default => sub {
    my $path = $_[0] -> request -> path;
    $path =~ m{^/[^/]+/[^/]+/(.*)$};
    $1;
  },
);

has _file => (
  is => 'rw',
  lazy => 1,
  default => sub {
    print STDERR "File: [", $_[0]->file, "]\n";
    my $f = $_[0] -> _project -> get_path(path => $_[0] -> file);
    $f;
  },
);

has _commit => (
  is => 'rw',
  lazy => 1,
  default => sub {
    my $self = shift;
    my $datetime;
    if( $datetime = $self -> request -> header('Accept-Datetime') ) {
      $datetime = strptime("%a, %d %b %Y %r", $datetime);
    }
    $datetime = DateTime -> now unless $datetime;
    $self -> _choose_datetime($datetime);
  },
);

sub _choose_datetime {
  my($self, $datetime) = @_;
  my $file = $self -> _file;
  print STDERR "file: $file\n";
  return unless $file;
  print STDERR "date: $datetime; path: ", $file->path->get, "\n";
  print STDERR "History:\n  ", join("\n  ", map {
    $_->time . ' ' . join(", ", map { $_ -> path->get } @{$_->contents})
  } @{$file -> history -> commits});
  my @commits = 
    sort { $a->time <=> $b->time }
    grep { $_ -> time <= $datetime }
    @{$file -> history -> commits};
  if(@commits) {
    # pull out committed file that matches our filename
    my $path = $file->path->get;

    my $commit = $commits[0];
    # removed files indicate an invalid datetime
    @commits = grep { $_->path->get eq $path } (@{$commit->removed});
    return 0 if @commits;

    # otherwise, look for modified or added files
    @commits = grep { $_->path->get eq $path } (@{$commit->modified}, @{$commit->added});
    print STDERR $commits[0],"\n" if @commits;
    return $commits[0] if @commits;
  }
  return;
};

sub resource_exists { $_[0] -> _project && $_[0] -> _file && $_[0] -> _commit }

sub last_modified {
  $_[0] -> _commit ? $_[0] -> _commit -> time : undef
}

has is_directory => (
  is => 'rw',
  lazy => 1,
  default => sub {
    $_[0] -> _file && $_[0] -> _file -> DOES('VCI::Abstract::FileContainer')
  },
);
  
has content_types_provided => (
  is => 'rw',
  lazy => 1,
  default => sub {
    # given a datetime, which content types are available for this file?
    my $self = shift;
    my @handlers;
    if($self -> is_directory) {
      @handlers = ( { 
        'text/html' =>, 'directory_as_html'
      }, { 
        'application/json' => 'directory_as_json'
      } );
    }
    else {
      # only return the content type we have as well as application/octet-stream
      @handlers = ( {
        'application/octet-stream' => 'content'
      } );
      push @handlers, {
        $self -> content_type => 'content'
      };
    }
    return \@handlers;
  },
);

has content_type => (
  is => 'rw',
  lazy => 1,
  default => sub {
    my $self = shift;
    if($self -> resource_exists) {
      $self -> _ft -> checktype_contents( $self -> content );
    }
    else {
      '';
    }
  },
);

sub choose_datetime {
  my($self, $dt) = @_;

  print STDERR "Choosing datetime [$dt]\n";
  # return true if $dt is a valid datetime for the path
  my $choice;
  $self -> _commit($choice = $self -> _choose_datetime($dt));
  return defined($choice);
}

sub directory_as_html {
}

sub directory_as_json {
}

sub content { 
  my $self = shift;

  if($self -> is_directory) {
    # eventually, we'll return a list of files
    return "";
  }
  else {
    return $self -> _commit -> content;
  }
}

1;
