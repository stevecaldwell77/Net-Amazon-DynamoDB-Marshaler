# NAME

Net::Amazon::DynamoDB::Marshaler - Translate Perl hashrefs into DynamoDb format and vice versa.

# SYNOPSIS

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

# DESCRIPTION

AWS' [DynamoDB](http://aws.amazon.com/dynamodb/) service expects attributes in a somewhat cumbersome format in which you must specify the attribute type as well as its name and value(s). This module simplifies working with DynamoDB by abstracting away the notion of types and letting you use more intuitive data structures.

There are a handful of CPAN modules which provide a DynamoDB client that do similar conversions. However, in all of these cases the conversion is tightly bound to the client implementation. This module exists in order to decouple the functionality of formatting with the functionality of making AWS calls.

NOTE: this module does not yet support Binary or Binary Set types. Pull requests welcome.

# CONVERSION RULES

See &lt;the AWS documentation|http://docs.aws.amazon.com/amazondynamodb/latest/developerguide/HowItWorks.NamingRulesDataTypes.html#HowItWorks.DataTypes> for more details on the various types supported by DynamoDB.

For a given Perl value, we use the following rules to pick the DynamoDB type:

1. If the value is undef or an empty string, use Null ('NULL').
2. If the value is a number (per StrictNum in [Types::Standard](https://metacpan.org/pod/Types%3A%3AStandard)), and falls within the accepted range for a DynamoDB number, use Number ('N').
3. For any other non-reference, use String ('S').
4. If the value is an arrayref, use List ('L').
5. If the value is a hashref, use Map ('M').
6. If the value isa [boolean](https://metacpan.org/pod/boolean), use Boolean ('BOOL').
7. If the value isa [Set::Object](https://metacpan.org/pod/Set%3A%3AObject), use either Number Set ('NS') or String Set ('SS'), depending on whether all members are numbers or not. All members must be defined, non-reference values, or an error will be thrown.
8. Any other value will throw an error.

When doing the opposite - un-marshalling a hashref fetched from DynamoDB - the module applies the rules above in reverse. Please note that NULLs get unmarshalled as undefs, so an empty string will be re-written to undef if it goes through a marshal/unmarshal cycle. DynamoDB does not allow for a way to store empty strings as distinct from NULL.

# EXPORTS

By default, dynamodb\_marshal and dynamodb\_unmarshal are exported.

## dynamodb\_marshal

Takes in a "normal" Perl hashref, transforms it into DynamoDB format.

    my $attrs_marshalled = dynamodb_marshal($attrs[, force_type => {}]);

### force\_type

Sometimes you want to explicitly choose a type for an attribute, overridding the rules above. Most commonly this issue occurs for key attributes, as DynamoDB enforces consistent typing on these attributes that it doesn't enforce otherwise.

For instance, you might have a table named 'users' whose partition key is a string named 'username'. If you have incoming data with a username of '1234', this module will tell DynamoDB to store that as a number, which will result in an error.

Use force\_type in that situation:

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

You can only specify 'S' or 'N' for force\_type values. If the attribute you specify is a list or map, the forced type will be applied recursively through the data structure. Sets are not currently available for force\_type.

Undefs or empty string values for force\_type attributes will be removed from the marshalled hashref. While this behavior might not seem intuitive at first, it's almost certainly what you want. For instance, if you have a global secondary index on a string attribute, and your item has an undef value for that attribute, you want to avoid sending that attribute (using NULL would be rejected by DynamoDB, and you can't send empty strings). If you have an undef value for a primary key string attribute, you have a bug in your application somewhere.

If you specify 'N', and a non-number value is encountered, it will also be removed.

## dynamodb\_unmarshal

The opposite of dynamodb\_marshal.

    my $attrs = dynamodb_unmarshal($attrs_marshalled);

# AUTHOR

Steve Caldwell <scaldwell@gmail.com>

# COPYRIGHT

Copyright 2017- Steve Caldwell

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# SEE ALSO

- [Paws::DynamoDB](https://metacpan.org/pod/Paws%3A%3ADynamoDB) - the most up-to-date DynamoDB client.
- [DynamoDB's attribute format](http://docs.aws.amazon.com/amazondynamodb/latest/APIReference/API_AttributeValue.html)
- [Amazon::DynamoDB](https://metacpan.org/pod/Amazon%3A%3ADynamoDB) - DynamoDB client that does conversion for you.
- [Net::Amazon::DynamoDB](https://metacpan.org/pod/Net%3A%3AAmazon%3A%3ADynamoDB) - DynamoDB client that does conversion for you.
- [WebService::Amazon::DynamoDB](https://metacpan.org/pod/WebService%3A%3AAmazon%3A%3ADynamoDB) - DynamoDB client that does conversion for you.
- [Net::Amazon::DynamoDB::Table](https://metacpan.org/pod/Net%3A%3AAmazon%3A%3ADynamoDB%3A%3ATable) - DynamoDB client that does conversion for you.
- [dynamoDb-marshaler](https://github.com/CascadeEnergy/dynamoDb-marshaler) - JavaScript library that performs a similar function.

# ACKNOWLEDGEMENTS

Thanks to [Campus Explorer](http://www.campusexplorer.com), who allowed me to release this code as open source.
