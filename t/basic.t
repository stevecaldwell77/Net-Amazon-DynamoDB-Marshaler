use strict;
use Test::More;

BEGIN { use_ok('Net::Amazon::DynamoDB::Marshaler'); }

# If the value is undef, use Null ('NULL')
sub test_undef() {
    is_deeply(
        dynamodb_marshal({ user_id => undef }),
        { user_id => { BOOL => 1 } },
        'boolean marshalled to BOOL',
    );
}

# If the value looks like a number, use Number ('N').
sub test_number() {
}

# For any other non-reference, use String ('S').
sub test_scalar() {
}

# If the value is an arrayref, use List ('L').
sub test_list() {
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

done_testing;
