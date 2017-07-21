package Net::Amazon::DynamoDB::Marshaler;

use strict;
use 5.008_005;
our $VERSION = '0.04';

use parent qw(Exporter);
our @EXPORT = qw(dynamodb_marshal dynamodb_unmarshal);

use boolean qw(true false isBoolean);
use Scalar::Util qw(blessed);
use Types::Standard qw(StrictNum);

sub dynamodb_marshal {
    my ($attrs, %args) = @_;
    my $force_type = $args{force_type} || {};
    die __PACKAGE__.'::dynamodb_marshal(): argument must be a hashref'
        unless (
            ref $attrs
            && ref $attrs eq 'HASH'
        );
    die __PACKAGE__.'::dynamodb_marshal(): force_type must be a hashref'
        unless (
            ref $force_type
            && ref $force_type eq 'HASH'
        );
    return _marshal_hashref($attrs, $force_type);
}

sub dynamodb_unmarshal {
    my ($attrs) = @_;
    die __PACKAGE__.'::dynamodb_unmarshal(): argument must be a hashref'
        unless (
            ref $attrs
            && ref $attrs eq 'HASH'
        );
    return _unmarshal_hashref($attrs);
}

sub _marshal_hashref {
    my ($attrs, $force_type) = @_;
    $force_type ||= {};
    return {
        map { $_ => _marshal_val($attrs->{$_}, $force_type->{$_}) }
        keys %$attrs
    };
}

sub _unmarshal_hashref {
    my ($attrs) = @_;
    return { map { $_ => _unmarshal_attr_val($attrs->{$_}) } keys %$attrs };
}

sub _marshal_val {
    my ($val, $type) = @_;
    $type ||= _val_type($val);

    return { $type => $val } if $type =~ /^(N|S)$/;
    return { $type => 1 } if $type eq 'NULL';
    return { $type => $val ? 1 : 0 } if $type eq 'BOOL';
    return { $type => [ $val->members ] } if $type =~ /^(NS|SS)$/;
    return { $type => [ map { _marshal_val($_) } @$val ] } if ($type eq 'L');
    return { $type => _marshal_hashref($val) } if ($type eq 'M');

    die "don't know how to marshal type of $type";
}

sub _unmarshal_attr_val {
    my ($attr_val) = @_;
    my ($type, $val) = %$attr_val;

    return undef if $type eq 'NULL';
    return $val if $type =~ /^(S|N)$/;
    return true if $type eq 'BOOL' && $val;
    return false if $type eq 'BOOL';
    return Set::Object->new(@$val) if $type =~ /^(NS|SS)$/;
    return [ map { _unmarshal_attr_val($_) } @$val ] if $type eq 'L';
    return _unmarshal_hashref($val) if $type eq 'M';

    die "don't know how to unmarshal $type";
}

sub _val_type {
    my ($val) = @_;

    return 'NULL' if ! defined $val;
    return 'NULL' if $val eq '';
    return 'N' if _is_number($val);
    return 'S' if !ref $val;

    return 'BOOL' if isBoolean($val);

    my $ref = ref $val;
    return 'L' if $ref eq 'ARRAY';
    return 'M' if $ref eq 'HASH';

    if (blessed($val) and $val->isa('Set::Object')) {
        my @types = map { _val_type($_) } $val->members;
        die "Sets can only contain strings and numbers, found $_"
            for grep { !/^(S|N)$/ } @types;
        if (grep { /^S$/ } @types) {
            return 'SS';
        } else {
            return 'NS';
        }
    }

    die __PACKAGE__.": unable to marshal value: $val";
}

sub _is_number {
    my ($val) = @_;
    return (
        (!ref $val)
        && StrictNum->check($val)
        && (
            $val == 0
            || (
                $val < '1E+126'
                && $val > '1E-130'
            )
            || (
                $val < '-1E-130'
                && $val > '-1E+126'
            )
        )
        && length($val) <= 38
    );
}


1;
__END__

=encoding utf-8

=head1 NAME

Net::Amazon::DynamoDB::Marshaler - Translate Perl hashrefs into DynamoDb format and vice versa.

=head1 SYNOPSIS

  use Net::Amazon::DynamoDB::Marshaler;

  my $item = {
    name => 'John Doe',
    age => 28,
    skills => ['Perl', 'Linux', 'PostgreSQL'],
  };

  # Translate a Perl hashref into DynamoDb format
  my $item_dynamodb = dynamodb_marshal($item);

  # $item_dynamodb looks like:
  # {
  #   name => {
  #     S => 'John Doe',
  #   },
  #   age => {
  #     N => 28,
  #   },
  #   skills => {
  #     SS => ['Perl', 'Linux', 'PostgreSQL'],
  #   }
  # };

  # Translate a DynamoDb formatted hashref into regular Perl
  my $item2 = dynamodb_unmarshal($item_dynamodb);

=head1 DESCRIPTION

AWS' L<DynamoDB|http://aws.amazon.com/dynamodb/> service expects attributes in a somewhat cumbersome format in which you must specify the attribute type as well as its name and value(s). This module simplifies working with DynamoDB by abstracting away the notion of types and letting you use more intuitive data structures.

There are a handful of CPAN modules which provide a DynamoDB client that do similar conversions. However, in all of these cases the conversion is tightly bound to the client implementation. This module exists in order to decouple the functionality of formatting with the functionality of making AWS calls.

NOTE: this module does not yet support Binary or Binary Set types. Pull requests welcome.

=head1 CONVERSION RULES

See <the AWS documentation|http://docs.aws.amazon.com/amazondynamodb/latest/developerguide/HowItWorks.NamingRulesDataTypes.html#HowItWorks.DataTypes> for more details on the various types supported by DynamoDB.

For a given Perl value, we use the following rules to pick the DynamoDB type:

=over 4

=item 1.

If the value is undef or an empty string, use Null ('NULL').

=item 2.

If the value is a number (per StrictNum in L<Types::Standard>), and falls within the accepted range for a DynamoDB number, use Number ('N').

=item 3.

For any other non-reference, use String ('S').

=item 4.

If the value is an arrayref, use List ('L').

=item 5.

If the value is a hashref, use Map ('M').

=item 6.

If the value isa L<boolean>, use Boolean ('BOOL').

=item 7.

If the value isa L<Set::Object>, use either Number Set ('NS') or String Set ('SS'), depending on whether all members are numbers or not. All members must be defined, non-reference values, or an error will be thrown.

=item 8.

Any other value will throw an error.

=back

When doing the opposite - un-marshalling a hashref fetched from DynamoDB - the module applies the rules above in reverse. Please note that NULLs get unmarshalled as undefs, so an empty string will be re-written to undef if it goes through a marshal/unmarshal cycle. DynamoDB does not allow for a way to store empty strings as distinct from NULL.

=head1 EXPORTS

By default, dynamodb_marshal and dynamodb_unmarshal are exported.

=head2 dynamodb_marshal

Takes in a "normal" Perl hashref, transforms it into DynamoDB format.

  my $attrs_marshalled = dynamodb_marshal($attrs[, force_type => {}]);

=head3 force_type

Sometimes you want to explicitly choose a type for an attribute, overridding the rules above. Most commonly this issue occurs for key attributes, as DynamoDB enforces consistent typing on these attributes that it doesn't enforce otherwise.

For instance, you might have a table named 'users' whose partition key is a string named 'username'. If you have incoming data with a username of '1234', this module will tell DynamoDB to store that as a number, which will result in an error.

Use force_type in that situation:

  my $item = {
      username => '1234',
      ...
  };

  my $force_type = {
      username => 'S',
  };

  my $item_dynamodb = dynamodb_marshal($item, force_type => $force_type);

  # $item_dynamodb looks like:
  # {
  #   username => {
  #     S => '1234',
  #   },
  #   ...
  # };

=head2 dynamodb_unmarshal

The opposite of dynamodb_marshal.

  my $attrs = dynamodb_unmarshal($attrs_marshalled);

=head1 AUTHOR

Steve Caldwell E<lt>scaldwell@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2017- Steve Caldwell

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=over 4

=item L<Paws::DynamoDB> - the most up-to-date DynamoDB client.

=item L<DynamoDB's attribute format|http://docs.aws.amazon.com/amazondynamodb/latest/APIReference/API_AttributeValue.html>

=item L<Amazon::DynamoDB> - DynamoDB client that does conversion for you.

=item L<Net::Amazon::DynamoDB> - DynamoDB client that does conversion for you.

=item L<WebService::Amazon::DynamoDB> - DynamoDB client that does conversion for you.

=item L<Net::Amazon::DynamoDB::Table> - DynamoDB client that does conversion for you.

=item L<dynamoDb-marshaler|https://github.com/CascadeEnergy/dynamoDb-marshaler> - JavaScript library that performs a similar function.

=back

=head1 ACKNOWLEDGEMENTS

Thanks to L<Campus Explorer|http://www.campusexplorer.com>, who allowed me to release this code as open source.

=cut
