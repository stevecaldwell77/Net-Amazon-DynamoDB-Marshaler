use strict;
use Test::More;
use Test::Deep;
use Test::Fatal;

use boolean;
use IO::Handle;
use Set::Object;

BEGIN { use_ok('Net::Amazon::DynamoDB::Marshaler'); }

# If the value is undef, use Null ('NULL')
sub test_undef() {
    cmp_deeply(
        dynamodb_marshal({
            user_id => undef,
        }),
        {
            user_id => { NULL => '1' },
        },
        'undef marshalled to NULL',
    );
}

# If the value looks like a number, use Number ('N').
sub test_number() {
    cmp_deeply(
        dynamodb_marshal({
            user_id => '1234',
            pct_complete => 0.33,
        }),
        {
            user_id => { N => '1234' },
            pct_complete => { N => '0.33' },
        },
        'numbers marshalled to N',
    );
}

# For any other non-reference, use String ('S').
sub test_scalar() {
    cmp_deeply(
        dynamodb_marshal({
            first_name => 'John',
            description => 'John is a very good boy',
        }),
        {
            first_name => { S => 'John' },
            description => { S => 'John is a very good boy' },
        },
        'strings marshalled to S',
    );
}

# If the value is an arrayref, use List ('L').
sub test_list() {
    cmp_deeply(
        dynamodb_marshal({
            tags => [
                'complete',
                'development',
                1234,
            ],
        }),
        {
            tags => {
                L => [
                    { S => 'complete' },
                    { S => 'development' },
                    { N => '1234' },
                ],
            },
        },
        'arrayrefs marshalled to L',
    );
}

# If the value is a hashref, use Map ('M').
sub test_map() {
    cmp_deeply(
        dynamodb_marshal({
            scores => {
                math => 95,
                english => 80,
            },
        }),
        {
            scores => {
                M => {
                    math => { N => '95'},
                    english => { N => '80'},
                },
            },
        },
        'hashref marshalled to M',
    );
}

# If the value isa boolean, use Boolean ('BOOL').
sub test_boolean() {
    cmp_deeply(
        dynamodb_marshal({
            active => true,
            disabled => false,
        }),
        {
            active => { BOOL => '1' },
            disabled => { BOOL => '0' },
        },
        'booleans marshalled to BOOL',
    );
}

# If the value isa Set::Object, use Number Set ('NS') if all members look
# like numbers.
sub test_number_set() {
    cmp_deeply(
        dynamodb_marshal({
            scores => Set::Object->new(5, 7, 25, 32.4),
        }),
        {
            scores => {
                NS => set(5, 7, 25, 32.4),
            },
        },
        'Set::Object with numbers marshalled to NS',
    );
}

# If the value isa Set::Object, use String Set ('SS') if one member does not
# look like a number.
sub test_string_set() {
    cmp_deeply(
        dynamodb_marshal({
            tags => Set::Object->new(54, 'clothing', 'female'),
        }),
        {
            tags => {
                SS => set('54', 'clothing', 'female'),
            },
        },
        'Set::Object with non-number marshalled to SS',
    );
}

# If the value isa Set::Object, and a member is a reference, throw an error.
sub test_set_error() {
    like(
        exception {
            dynamodb_marshal({
                tags => Set::Object->new('large', { foo => 'bar' }),
            });
        },
        qr/Sets can only contain strings and numbers/,
        'Error thrown trying to marshall a set with a reference',
    );
}

# An un-convertable value value should throw an error.
sub test_other() {
    like(
        exception {
            dynamodb_marshal({
                filehandle => IO::Handle->new(),
            });
        },
        qr/unable to marshal value: IO::Handle/,
        'Error thrown trying to marshall an unknown value',
    );
}

# Test nested data structure
sub test_complex() {
    cmp_deeply(
        dynamodb_marshal({
            id => 25,
            first_name => 'John',
            last_name => 'Doe',
            relationships => {
                friends => [
                    {
                        id => 26,
                    },
                ],
                managers => undef,
            },
        }),
        {
            id => { N => 25 },
            first_name => { S => 'John' },
            last_name => { S => 'Doe' },
            relationships => {
                M => {
                    friends => {
                        L => [
                            { M => { id => { N => 26 } } },
                        ],
                    },
                    managers => { NULL => 1 },
                }
            },
        },
        'nested data structure handled',
    );
}

test_undef();
test_number();
test_scalar();
test_list();
test_map();
test_boolean();
test_number_set();
test_string_set();
test_set_error();
test_other();
test_complex();

done_testing;
