package SGE::Mon;
use Dancer2;

our $VERSION = '0.1';

get '/' => sub {
    template 'index';
};

true;
