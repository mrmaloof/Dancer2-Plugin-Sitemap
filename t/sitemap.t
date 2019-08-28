use strict;
use warnings;
use Test2::V0;
use Plack::Test;
use HTTP::Request::Common;

use lib 't/lib';
use SitemapTest;

my $app = SitemapTest->to_app;
is( ref $app, 'CODE', 'Got app' );

my $test = Plack::Test->create($app);

my $content = do { local $/; <main::DATA> };
my $res = $test->request( GET '/sitemap.xml' );
is $res->code, 200, 'code';
is $res->content_type, 'application/xml', 'content_type';
is $res->content, $content, 'content';

done_testing;

__DATA__
<?xml version="1.0" encoding="UTF-8"?>

<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url>
    <loc>http://localhost/</loc>
  </url>
  <url>
    <loc>http://localhost/foo</loc>
  </url>
  <url>
    <loc>http://localhost/prefix-foo/</loc>
  </url>
  <url>
    <loc>http://localhost/pricing/basic</loc>
  </url>
  <url>
    <loc>http://localhost/pricing/premium</loc>
  </url>
</urlset>