use strict;
use Test::More;

BEGIN { use_ok('Net::Amazon::DynamoDB::Marshaler'); }

# If the value is undef, use Null ('NULL')
sub test_undef() {
    is_deeply(
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
    is_deeply(
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
    is_deeply(
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
    is_deeply(
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
}

# If the value isa boolean, use Boolean ('BOOL').
sub test_boolean() {
}

# If the value isa Set::Object, use Number Set ('NS') if all members look
# like numbers.
sub test_number_set() {
}

# If the value isa Set::Object, use String Set ('SS') if one member does not
# look like a number.
sub test_string_set() {
}

# If the value isa Set::Object, and a member is not defined or is a
# reference, throw an error.
sub test_set_error() {
}

# An un-convertable value value should throw an error.
sub test_other() {
}

# Test nested data structure
sub test_complex() {
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
