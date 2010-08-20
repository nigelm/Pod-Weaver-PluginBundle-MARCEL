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
has dist_name => ( is => 'rw', type => 'Str' );
has homepage_url  => ( is => 'rw', type => 'Str' );
has repo_type => ( is => 'rw', type => 'Str', default => 'git' );
has repo_url  => ( is => 'rw', type => 'Str' );
has repo_web  => ( is => 'rw', type => 'Str', clearer => '_clear_repo_web', predicate => 'has_repo_web', );
has is_github => ( is => 'rw', type => 'Bool', default => 0 );

sub weave_section {
    my ( $self, $document, $input ) = @_;

    $self->_extract_dzil_metadata($input);
    $document->children->push(
        Pod::Elemental::Element::Nested->new(
            {
                command  => 'head1',
                content  => 'AVAILABILITY',
                children => [ $self->_cpan_pod, $self->_development_pod, ],
            }
        ),
    );
}

# _extract_dzil_metadata uses the input hash passed across to
# pull the Dist::Zilla metadata out and use it to populate the
# attributes.  I would prefer this to be done as a BUILDARGS
# mechanism (and hence also mark all the attributes r/o, but
# this does not appear to be possible with the current framework)
sub _extract_dzil_metadata {
    my ( $self, $input ) = @_;

    # if there is no zilla section we are sunk - bail out quietly
    my $zilla = $input->{zilla} or return;

    # set the distribution name
    $self->dist_name( $zilla->name );

    # die if there is no distmeta section - this means dzil not set right
    my $meta = eval { $zilla->distmeta }
      or die "No distmeta data present";

    # pull repo out of distmeta resources.
    my $repo = $meta->{resources}{repository};
    if ($repo) {
        $self->repo_type( $repo->{type} ) if ( $repo->{type} );
        $self->_set_repo( $repo->{url} );
    }
}

sub _set_repo {
    my ( $self, $repourl ) = @_;

    $self->is_github( ( $repourl =~ m|/github.com/| ) ? 1 : 0 );
    $self->_clear_repo_web;
    if ( $self->is_github ) {

        # strip the access method off - we can then add it as needed
        my $nomethod = $repourl;
        $nomethod =~ s!^(http|git|git\@github\.com):/*!!i;
        $self->repo_url( 'git://' . $nomethod );
        $self->repo_web( 'http://' . $nomethod );
    }else{
        $self->repo_url( $repourl );
    }
}

sub _cpan_pod {
    my $self = shift;
    
    
}
1;

=pod

=for test_synopsis
1;
__END__

=head1 SYNOPSIS

In C<weaver.ini>:

    [Availability]

=head1 OVERVIEW

This section plugin will produce a hunk of Pod that lists known bugs and
refers to the bugtracker URL. The plugin is automatically used by the
C<@MARCEL> weaver bundle.

=function weave_section

adds the C<AVAILABILITY> section.
