use strict;
use warnings;
use Test2::V0;
use Plack::Test;
use HTTP::Request::Common;

{

    package MyApp;
    use Dancer2;
    use Dancer2::Plugin::Sitemap;

    get '/'          => sub { };
    get '/foo'       => sub { };
    post '/submit'   => sub { };
    get '/test.json' => sub { };
    prefix '/prefix-foo' => sub {
        get '/' => sub { };
    };

    1;
}

my $app = MyApp->to_app;
is( ref $app, 'CODE', 'Got app' );

my $test = Plack::Test->create($app);

my $res = $test->request( GET '/sitemap.xml' );
is $res->code,         200,               'code';
is $res->content_type, 'application/xml', 'content_type';
is $res->content,      q{<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"><url><loc>http://localhost/</loc></url><url><loc>http://localhost/foo</loc></url><url><loc>http://localhost/prefix-foo/</loc></url></urlset>},
    'content';

done_testing;
