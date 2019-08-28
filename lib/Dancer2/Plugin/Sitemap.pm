package Dancer2::Plugin::Sitemap;

# ABSTRACT: Dancer2-Plugin-Sitemap
use strict;
use warnings;
use File::Find;
use HTTP::Tiny;
use WWW::RobotRules;
use XML::Writer;
use Dancer2::Plugin;

our $VERSION = '0.0.1';

=head1 NAME

Dancer2::Plugin::Sitemap

=head1 SYNOPSIS

	package MyDancer2App;
	use Dancer2;
	use Dancer2::Plugin::Sitemap;

=head1 DESCRIPTION

This plugin adds the route /sitemap.xml. The sitemap.xml informs search engines about the URLs available for crawling.

The sitemap will contain URLs for the get routes of the application. Routes containg '*', ':' are ignored. Routes
ending in '.json' are ignored.

A request will be made to /robots.txt in the same uri_base as the sitemap. If found, the rules contained will be
consulted for excluding URLs from the sitemap.
 
=cut

sub BUILD {
    my $plugin = shift;

    $plugin->app->add_route(
        method => 'get',
        regexp => '/sitemap.xml',
        code   => sub {
            my $app = shift;

            $app->response->content_type('xml');

            my $xml = XML::Writer->new( OUTPUT => 'self', DATA_MODE => 1, DATA_INDENT => 2 );
            $xml->xmlDecl('UTF-8');
            $xml->startTag( 'urlset', 'xmlns' => 'http://www.sitemaps.org/schemas/sitemap/0.9' );
            for my $url ( @{ _get_urls($app) } ) {
                $xml->startTag('url');
                $xml->dataElement( 'loc', $url );
                $xml->endTag('url');
            }
            $xml->endTag('urlset');

            $xml->to_string;
        }
    );
}

=head2 _get_urls

=cut

sub _get_urls {
    my $app = shift;

    my $uri_base   = $app->request->uri_base;
    my $rules      = WWW::RobotRules->new;
    my $robots_url = qq{$uri_base/robots.txt};
    my $res        = HTTP::Tiny->new->get($robots_url);
    $rules->parse( $robots_url, $res->{content} ) if $res->{success};

    my $paths = {};
    map { $paths->{$_} = 1 } @{ $app->config->{plugins}->{Sitemap}->{additional_routes} };

    if ( $app->config->{plugins}->{Sitemap}->{add_from_views} ) {
        my $views_dir  = $app->config->{views};
        my $layout_dir = $views_dir . '/' . $app->engine('template')->{layout_dir};
        my $ext        = $app->engine('template')->{default_tmpl_ext};
        find(
            sub {
                return unless /\.$ext$/;
                return if $File::Find::name =~ /^$layout_dir/;
				(my $path = $File::Find::name) =~ s/$views_dir(.*)\.$ext/$1/;
                $paths->{$path}=1;
            },
            $views_dir
        );
    }
    for my $route ( @{ $app->routes->{get} } ) {
        my $path = $route->{spec_route};
        next if $path eq '/sitemap.xml';
        next if $path =~ /[\*:]/;
        next if $path =~ /\.json$/;
        next unless $rules->allowed( $uri_base . $path );

        $paths->{$path} = 1;
    }

    [ map { $uri_base . $_ } sort keys %$paths ];
}

1;

=head1 CONFIGURATION

    plugins:
        Sitemap:
            additional_routes:
                - /route1
                - /route2
            add_from_views: 1

=over

=item additional_routes

Use to add routes to the sitemap.xml the plugin will not find on its own.

=item add_from_views

If this option is set the views directory will be scanned and routes will be included for each view. This is useful if
you have auto_page set for your app and you would like these pages included in your sitemap.

=back

=head1 SEE ALSO

L<Dancer2>

L<Dancer::Plugin::SiteMap>

L<https://www.sitemaps.org/index.html>

=head1 ACKNOWLEDGMENTS

=over

=item James Ronan, C<< <james at ronanweb.co.uk> >>

=back
