package Email::MIME::Modifier;
# $Id: Modifier.pm,v 1.2 2004/07/10 04:01:47 cwest Exp $

use vars qw[$VERSION];
$VERSION = (qw$Revision: 1.2 $)[1];

package Email::MIME;
use strict;

use Email::MIME::ContentType;
use Email::MIME::Encodings;
use Email::MessageID;

=head1 NAME

Email::MIME::Modifier - Modify Email::MIME Objects Easily

=head1 SYNOPSIS

  use Email::MIME;
  use Email::MIME::Modifier;
  my $email = Email::MIME->new( join "", <> );

  remove_attachments($email);

  sub remove_attachments {
      my $email = shift;
      my @keep;
      foreach my $part ( $email->parts ) {
          push @keep, $part
            unless $part->header('Content-Disposition') =~ /^attachment/;
          remove_attachments($part)
            if $part->content_type =~ /^(?:multipart|message)/;
      }
      $email->parts_set( \@keep );
  }

=head1 DESCRIPTION

Provides a number of useful methods for manipulating MIME messages.

These method are declared in the C<Email::MIME> namespace, and are
used with C<Email::MIME> objects.

=head2 Methods

=over 4

=item content_type_set

  $email->content_type_set( 'text/html' );

Change the content type. All C<Content-Type> header attributes
will remain in tact.

=cut

sub content_type_set {
    my ($self, $ct) = @_;
    my $ct_header = parse_content_type( $self->header('Content-Type') );
    @{$ct_header}{qw[discrete composite]} = split m[/], $ct;
    $self->_compose_content_type( $ct_header );
    return $ct;
}

=pod

=item charset_set

=item name_set

=item format_set

=item boundary_set

  $email->charset_set( 'utf8' );
  $email->name_set( 'some_filename.txt' );
  $email->format_set( 'flowed' );
  $email->boundary_set( undef ); # remove the boundary

These four methods modify common C<Content-Type> attributes. If set to
C<undef>, the attribute is removed. All other C<Content-Type> header
information is preserved when modifying an attribute.

=cut

foreach my $attr ( qw[charset name format] ) {
    no strict 'refs';
    *{"$attr\_set"} = sub {
        my ($self, $value) = @_;
        my $ct_header = parse_content_type( $self->header('Content-Type') );
        if ( $value ) {
            $ct_header->{attributes}->{$attr} = $value;
        } else {
            delete $ct_header->{attributes}->{$attr};
        }
        $self->_compose_content_type( $ct_header );
        return $value;
    };
}

sub boundary_set {
    my ($self, $value) = @_;
    my $ct_header = parse_content_type( $self->header('Content-Type') );

    if ( $value ) {
        $ct_header->{attributes}->{boundary} = $value;
    } else {
        delete $ct_header->{attributes}->{boundary};
    }
    $self->_compose_content_type( $ct_header );
    
    $self->parts_set([$self->parts]) if $self->parts > 1;
}

=pod

=item encoding_set

  $email->encoding_set( 'base64' );
  $email->encoding_set( 'quoted-printable' );
  $email->encoding_set( '8bit' );

Convert the message body and alter the C<Content-Transfer-Encoding>
header using this method. Your message body, the output of the C<body()>
method, will remain the same. The raw body, output with the C<body_raw()>
method, will be changed to reflect the new encoding.

=cut

sub encoding_set {
    my ($self, $enc) = @_;
    $enc ||= '7bit';
    my $body = $self->body;
    $self->header_set('Content-Transfer-Encoding' => $enc);
    $self->body_set( $body );
}

=item body_set

  $email->body_set( $unencoded_body_string );

This method will encode the new body you send using the encoding
specified in the C<Content-Transfer-Encoding> header, then set
the body to the new encoded body.

This method overrides the default C<body_set()> method.

=cut

sub body_set {
    my ($self, $body) = @_;
    my $enc = $self->header('Content-Transfer-Encoding');
    $body = Email::MIME::Encodings::encode( $enc, $body )
       unless !$enc || $enc =~ /^(?:7bit|8bit|binary)$/i;
    $self->SUPER::body_set( $body );
}

=pod

=item disposition_set

  $email->disposition_set( 'attachment' );

Alter the C<Content-Disposition> of a message. All header attributes
will remain in tact.

=cut

sub disposition_set {
    my ($self, $dis) = @_;
    $dis ||= 'inline';
    my $dis_header = $self->header('Content-Disposition');
    $dis_header ?
      ($dis_header =~ s/^([^;]+)/$dis/) :
      ($dis_header = $dis);
    $self->header_set('Content-Disposition' => $dis_header);
}

=pod

=item filename_set

  $email->filename_set( 'boo.pdf' );

Sets the filename attribute in the C<Content-Disposition> header. All other
header information is preserved when setting this attribute.

=cut

sub filename_set {
    my ($self, $filename) = @_;
    my $dis_header = $self->header('Content-Disposition');
    my ($disposition, $attrs);
    if ( $dis_header ) {
        ($disposition) = ($dis_header =~ /^([^;]+)/);
        $dis_header =~ s/^$disposition(?:;\s*)?//;
        $attrs = Email::MIME::ContentType::_parse_attributes($dis_header) || {};
    }
    $filename ? $attrs->{filename} = $filename : delete $attrs->{filename};
    $disposition ||= 'inline';
    
    my $dis = $disposition;
    while ( my ($attr, $val) = each %{$attrs} ) {
        $dis .= qq[; $attr="$val"];
    }

    $self->header_set('Content-Disposition' => $dis);
}

=pod

=item parts_set

  $email->parts_set( \@new_parts );

Replaces the parts for an object. Accepts a reference to a list of C<Email::MIME>
objects, representing the new parts. If this message was originally a single
part, the C<Content-Type> header will be changed to C<multipart/mixed>, and given
a new boundary attribute.

=cut

sub parts_set {
    my ($self, $parts) = @_;
    my $body  = '';

    my $ct_header = parse_content_type($self->header('Content-Type'));
    $ct_header->{attributes}->{boundary} ||= Email::MessageID->new->user;
    my $bound = $ct_header->{attributes}->{boundary};

    @{$ct_header}{qw[discrete composite]} = qw[multipart mixed]
      unless grep { $ct_header->{discrete} eq $_ } qw[multipart message];
    $self->_compose_content_type( $ct_header );

    foreach my $part ( @{$parts} ) {
        $body .= "$self->{mycrlf}--$bound$self->{mycrlf}";
        $body .= $part->as_string;
    }
    $body .= "$self->{mycrlf}--$bound--$self->{mycrlf}";

    $self->body_set($body);
    $self->fill_parts;
}

sub _compose_content_type {
    my ($self, $ct_header) = @_;
    my $ct = join '/', @{$ct_header}{qw[discrete composite]};
    while ( my ($attr, $val) = each %{$ct_header->{attributes}} ) {
        $ct .= qq[; $attr="$val"];
    }
    $self->header_set('Content-Type' => $ct);
    $self->{ct} = $ct_header;
}

1;

__END__

=pod

=back

=head1 SEE ALSO

L<Email::Simple>, L<Email::MIME>, L<Email::MIME::Encodings>,
L<Email::MIME::ContentType>, L<perl>.

=head1 AUTHOR

Casey West, <F<casey@geeknest.com>>.

=head1 COPYRIGHT

  Copyright (c) 2004 Casey West.  All rights reserved.
  This module is free software; you can redistribute it and/or modify it
  under the same terms as Perl itself.

=cut
