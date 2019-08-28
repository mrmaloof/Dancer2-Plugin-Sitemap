package SitemapTest;
use Dancer2;
use Dancer2::Plugin::Sitemap;

set plugins => {
    Sitemap => {
        additional_routes => [ '/pricing/basic', '/pricing/premium' ],
        add_from_views    => 1,
        exclude_patterns  => ['/components']
    }
};

get '/'          => sub { };
get '/foo'       => sub { };
post '/submit'   => sub { };
get '/test.json' => sub { };
prefix '/prefix-foo' => sub {
    get '/' => sub { };
};
get '/pricing/:product' => sub { };

1;
