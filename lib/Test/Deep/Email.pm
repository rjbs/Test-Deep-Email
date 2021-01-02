use v5.26.0;
use warnings;

package Test::Deep::Email;

use Sub::Exporter -setup => {
  exports => [ qw( email_like ) ],
  groups  => { default => [ qw( email_like ) ] },
};

sub email_like { Test::Deep::Email::Cmp->new(@_) }

package Test::Deep::Email::Cmp {

  use Test::Deep::Cmp;
  use Scalar::Util ();

  sub init {
    my ($self, $val) = @_;
    $self->{want} = $val;

    # args can be: phrase, address
    # comments are ignored, because I really just don't care about them
    $self->{want_phrase}  = $val->{phrase}  if exists $val->{phrase};
    $self->{want_address} = $val->{address} if exists $val->{address};

    Carp::croak("can't compare an email without either a phrase or address")
      unless exists $val->{phrase} or $val->{address};

    return;
  }

  sub descend {
    my ($self, $got) = @_;

    my @problems;
    $self->data->{email_problems} = \@problems;

    unless (
      Scalar::Util::blessed($got)
      && ($got->isa('Email::Address::XS') || $got->isa('Email::Address'))
    ) {
      my $type = Scalar::Util::blessed($got)
               ? (ref $got . " object")
               : ref $got ? (ref $got . " reference") : ref \$got;

      @problems = "we expected an email object but got a $type";
      return 0;
    }

    for my $method (qw( address phrase )) {
      next unless exists $self->{"want_$method"};
      my $have_this = $got->$method;
      my $want_this = $self->{"want_$method"};

      next if ! defined $have_this && ! defined $want_this;
      next if defined $have_this && defined $want_this && $have_this eq $want_this;

      push @problems,
        "want $method: " . ($want_this // '(undef)'),
        "have $method: " . ($have_this // '(undef)');
    }

    return 0 if @problems;
    return 1;
  }

  sub diagnostics {
    my ($self, $where, $frame) = @_;
    if ($frame->{email_problems}) {
      my $diag = "Considered $where as an email header:";
      $diag .= "\n  $_" for $frame->{email_problems}->@*;
      return $diag;
    }

    return "Compared $where as an email mailbox header.  Didn't match!";
  }
}

1;
