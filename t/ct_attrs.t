use Test::More qw[no_plan];
use Test::Deep;

use_ok 'Email::MIME';
use_ok 'Email::MIME::Modifier';
use_ok 'Email::MIME::ContentType';

my $email = Email::MIME->new(<<__MESSAGE__);
Content-Type: text/plain; charset="us-ascii"
__MESSAGE__

cmp_deeply( parse_content_type($email->header('Content-Type')), {
    discrete => 'text',
    composite => 'plain',
    attributes => {
        charset => 'us-ascii',
    },
}, 'default ct worked' );

$email->charset_set( 'utf8' );

cmp_deeply( parse_content_type($email->header('Content-Type')), {
    discrete => 'text',
    composite => 'plain',
    attributes => {
        charset => 'utf8',
    },
}, 'ct with new charset worked' );

$email->charset_set( undef );

cmp_deeply( parse_content_type($email->header('Content-Type')), {
    discrete => 'text',
    composite => 'plain',
    attributes => {
    },
}, 'ct with no charset worked' );

$email->format_set( 'flowed' );

cmp_deeply( parse_content_type($email->header('Content-Type')), {
    discrete => 'text',
    composite => 'plain',
    attributes => {
        format => 'flowed',
    },
}, 'ct with format worked' );

$email->name_set( 'foo.txt' );

cmp_deeply( parse_content_type($email->header('Content-Type')), {
    discrete => 'text',
    composite => 'plain',
    attributes => {
        format => 'flowed',
        name => 'foo.txt',
    },
}, 'ct with name worked' );

is $email->header('Content-Type'),
    'text/plain; format="flowed"; name="foo.txt"',
    'ct format is correct';

$email->boundary_set( 'marker' );

cmp_deeply( parse_content_type($email->header('Content-Type')), {
    discrete => 'text',
    composite => 'plain',
    attributes => {
        boundary => 'marker',
        format => 'flowed',
        name => 'foo.txt',
    },
}, 'ct with boundary worked' );

