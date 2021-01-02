use v5.24.0;
use warnings;

use Test::Tester;
use Test::More;
use Test::Deep;
use Test::Deep::Email;
use Email::Address::XS;

expect_pass(
  email(q{rjbs@cpan.org}, 'R. Signes'),
  email_like({ address => 'rjbs@cpan.org' }),
);

expect_fail(
  email(q{rjbs@cpan.org}, 'R. Signes'),
  email_like({ address => 'alias@cpan.org' }),
  <<~'END',
  Considered $data as an email header:
    want address: alias@cpan.org
    have address: rjbs@cpan.org
  END
);

sub email {
  my ($address, $phrase) = @_;
  return Email::Address::XS->new(address => $address, phrase => $phrase);
}

sub expect_pass {
  my ($have, $want, $desc) = @_;
  $desc //= "expecting to pass...";

  subtest $desc => sub {
    my ($premature, @results) = run_tests(
      sub { cmp_deeply($have, $want) },
    );

    is($premature, '', 'no early diag');
    ok($results[0]->{ok}, 'test passed');
  };
}

sub expect_fail {
  my ($have, $want, $diag, $desc) = @_;
  $desc //= "expecting to fail...";

  subtest $desc => sub {
    my ($premature, @results) = run_tests(
      sub { cmp_deeply($have, $want) },
    );

    is($premature, '', 'no early diag');
    ok(! $results[0]->{ok}, 'test failed');
    is($results[0]->{diag}, $diag, "correct diagnostics");
  };
};

done_testing;
