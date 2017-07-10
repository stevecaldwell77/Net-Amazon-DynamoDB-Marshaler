requires 'perl', '5.008005';

requires 'boolean';
requires 'Exporter';
requires 'Scalar::Util';

on test => sub {
    requires 'Test::More', '0.96';
};
