use 5.008;
use strict;
use warnings;

package Pod::Weaver::Section::Availability;

# ABSTRACT: Add an AVAILABILITY pod section
use Moose;
with 'Pod::Weaver::Role::Section';
use namespace::autoclean;
use Moose::Autobox;

# add a set of attributes to hold the repo information
has zilla => ( is => 'rw', isa => 'Dist::Zilla', handles => [ 'name', 'distmeta' ] );
has homepage_url => ( is => 'rw', isa => 'Str',  lazy => 1, builder => '_build_homepage_url' );
has cpan_url     => ( is => 'rw', isa => 'Str',  lazy => 1, builder => '_build_cpan_url' );
has repo_type    => ( is => 'rw', isa => 'Str',  lazy => 1, builder => '_build_repo_type' );
has repo_url     => ( is => 'rw', isa => 'Str',  lazy => 1, builder => '_build_repo_url' );
has repo_web     => ( is => 'rw', isa => 'Str',  lazy => 1, builder => '_build_repo_web' );
has is_github    => ( is => 'rw', isa => 'Bool', lazy => 1, builder => '_build_is_github' );

sub weave_section {
    my ( $self, $document, $input ) = @_;

    $self->zilla( $input->{zilla} );
    $document->children->push(
        Pod::Elemental::Element::Nested->new(
            {
                command  => 'head1',
                content  => 'AVAILABILITY',
                children => [ $self->_homepage_pod, $self->_cpan_pod, $self->_development_pod, ],
            }
        ),
    );
}

sub _build_homepage_url {
    my $self = shift;

    return $self->distmeta->{resources}{homepage} || sprintf( 'http://search.cpan.org/dist/%s/', $self->name );
}

sub _build_cpan_url {
    my $self = shift;

    return sprintf( 'http://search.cpan.org/dist/%s/', $self->name );
}

sub _build_repo_type {
    my $self = shift;

    # if we don't know we default to git...
    return $self->distmeta->{resources}{repository}{type} || 'git';
}

sub _build_repo_url {
    my $self = shift;

    return ( $self->_build_repo_data )[0];
}

sub _build_repo_web {
    my $self = shift;

    return ( $self->_build_repo_data )[1];
}

sub _build_is_github {
    my $self = shift;

    # we do this by looking at the URL for githubbyness
    my $repourl = $self->distmeta->{resources}{repository}{url} or die "No repository URL set in distmeta";
    return ( ( $repourl =~ m|/github.com/| ) ? 1 : 0 );
}

sub _build_repo_data {
    my $self = shift;

    my $repourl = $self->distmeta->{resources}{repository}{url} or die "No repository URL set in distmeta";
    my $repoweb;
    if ( $self->is_github ) {

        # strip the access method off - we can then add it as needed
        my $nomethod = $repourl;
        $nomethod =~ s!^(http|git|git\@github\.com):/*!!i;
        $repourl = 'git://' . $nomethod;
        $repoweb = 'http://' . $nomethod;
    }
    return ( $repourl, $repoweb );
}

sub _homepage_pod {
    my $self = shift;

    # we suppress this if there is no homepage URL,
    # or the CPAN URL is same as the homepage URL
    return if (!$self->homepage_url or ( $self->cpan_url eq $self->homepage_url ));

    # otherwise return some boilerplate
    return Pod::Elemental::Element::Pod5::Ordinary->new(
        { content => sprintf( 'The project homepage is L<%s>.', $self->homepage_url ) } );
}

sub _cpan_pod {
    my $self = shift;

    my $text = sprintf(
        "%s\n%s\n%s L<%s>.",
        'The latest version of this module is available from the Comprehensive Perl',
        'Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN',
        'site near you, or see',
        $self->cpan_url
    );

    return Pod::Elemental::Element::Pod5::Ordinary->new( { content => $text } );
}

sub _development_pod {
    my $self = shift;

    my $text;
    if ( $self->is_github ) {
        $text = sprintf( "The development version lives at L<%s>\n", $self->repo_web );
        $text .= sprintf( "and may be cloned from L<%s>.\n", $self->repo_url );
        $text .= "Instead of sending patches, please fork this project using the standard\n";
        $text .= "git and github infrastructure.\n"

    }
    else {
        $text = sprintf( "The development version lives in a %s repository at L<%s>\n", $self->repo_type, $self->repo_web );
    }

    return Pod::Elemental::Element::Pod5::Ordinary->new( { content => $text } );
}

1;

=begin :prelude

=for test_synopsis
1;
__END__

=end :prelude

=head1 SYNOPSIS

In C<weaver.ini>:

    [Availability]

=head1 OVERVIEW

This section plugin will produce a hunk of Pod that gives
information about the availability and development of the project
or module.

All information used to generate the pod text is taken from the
L<Dist::Zilla::Plugin::MetaConfig> C<distmeta> information, so this
will only work within a L<Dist::Zilla> environment.

At present 3 POD paragraphs may be generated within the section:-

=over 4

=item * Home page information - this is only generated if the home
page is defined within C<distmeta> and if that home page is
different to the CPAN page for the module.  The distmeta key
for this information is C<resources.homepage>

=item * CPAN generic information with a link to the module on CPAN.

=item * Development information, including the location of
development source control repositories. The repository type is
assumed to be git, although this can changed (distmeta key
C<resources.repository.type>).

If the repository is recognised to be a github repository the
boilerplate text is modified to reflect a more git/github mechanism
for co-operative development. 

=back

The plugin is automatically used by the C<@MARCEL> weaver bundle -
see L<Pod::Weaver::PluginBundle::MARCEL>.

=function weave_section

adds the C<AVAILABILITY> section.
