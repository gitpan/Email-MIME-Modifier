use Test::More qw[no_plan];

use_ok 'Email::MIME';
use_ok 'Email::MIME::Modifier';

my $email = Email::MIME->new(<<__MESSAGE__);
Content-Disposition: inline

Engine Engine number nine.
__MESSAGE__

isa_ok $email, 'Email::MIME';

is scalar($email->parts), 1, 'only one part';

$email->parts_set([ Email::MIME->new(<<__MESSAGE__), Email::MIME->new(<<__MESSAGE2__) ]);
Content-Type: text/plain

Part one, part one!
__MESSAGE__
Content-Transfer-Encoding: base64

UGFydCB0d28sIHBhcnQgdHdvIQo=
__MESSAGE2__


is scalar($email->parts), 2, 'two parts';
is +($email->parts)[1]->body, qq[Part two, part two!\n], 'part two decoded';
