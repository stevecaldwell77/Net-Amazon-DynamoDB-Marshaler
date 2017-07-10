package Net::Amazon::DynamoDB::Marshaler;

use strict;
use 5.008_005;
our $VERSION = '0.01';

1;
__END__

=encoding utf-8

=head1 NAME

Net::Amazon::DynamoDB::Marshaler - Translate Perl hashrefs into DynamoDb format and vice versa.

=head1 SYNOPSIS

  use Net::Amazon::DynamoDB::Marshaler qw(dynamodb_marshal dynamodb_unmarshal);

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

  # Use with Paws:
  Paws->service('DynamoDB')->PutItem(
    TableName => 'users',
    Item => dynamodb_marshal($item),
  );

  my $user_dynamodb = Paws->service('DynamoDB')->GetItem(
    TableName => 'users',
    Key => dynamodb_marshal({
      name => 'John Doe',
    })
  );

  my $user = dynamodb_unmarshal($user_dynamodb);

=head1 DESCRIPTION

AWS' L<DynamoDB|http://aws.amazon.com/dynamodb/> service expects attributes in a somewhat cumbersome format in which you must specify the attribute type as well as its name and value(s). This module simplifies working with DynamoDB by abstracting away the notion of types and letting you use more intuitive data structures.

There are a handful of CPAN modules which provide a DynamoDB client that do similar conversions. However, in all of these cases the conversion is tightly bound to the client implementation. This module exists in order to decouple the functionality of formatting with the functionality of making AWS calls.

NOTE: this module does not yet support Binary or Binary Set types. Pull requests welcome.

=head1 CONVERSION RULES

See <the AWS documentation|dynamoDb-marshaler|http://docs.aws.amazon.com/amazondynamodb/latest/developerguide/HowItWorks.NamingRulesDataTypes.html#HowItWorks.DataTypes> for more details on the various types supported by DynamoDB.

For a given Perl value, we use the following rules to pick the DynamoDB type (and vice-versa for un-marshaling):

=over 4

=item 1.

If the value is undef, use Null ('NULL')

=item 2.

If the value looks like a number, use Number ('N').

=item 3.

For any other non-reference, use String ('S').

=item 4.

If the value is an arrayref, use List ('L').

=item 5.

If the value is a hashref, use Map ('M').

=item 6.

If the value isa L<boolean>, use Boolean ('BOOL').

=item 7.

If the value isa L<Set::Object>, use either Number Set ('NS') or String Set ('SS'), depending on whether all members look like numbers or not. All members must be defined, non-reference values, or an error will be thrown.

=item 8.

Any other value will throw an error.

=back

=head1 EXPORTS

Nothing is exported by default.

=head2 dynamodb_marshal

Takes in a "normal" Perl hashref, transforms it into DynamoDB format.

  my $attrs_marshalled = dynamodb_marshal($attrs);

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

=item L<Paws> - the author's preferred way to interact with AWS in Perl.

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
