# tests for the correct expansion of FORMFIELD

package Fn_FORMFIELD;
use strict;
use warnings;

use FoswikiFnTestCase();
our @ISA = qw( FoswikiFnTestCase );

use Error qw( :try );

sub new {
    my $self = shift()->SUPER::new( 'FORMFIELD', @_ );
    return $self;
}

sub set_up {
    my $this = shift;
    $this->SUPER::set_up();

    $this->_createTopic( $this->{test_web}, $this->{test_topicObject} );
}

sub _createTopic {
    my ( $this, $web, $topicObject ) = @_;

    my ($formTopicObject) = Foswiki::Func::readTopic( $web, 'TestForm' );
    $formTopicObject->text(<<FORM);
| *Name*    | *Type* | *Size* |
| Marjorie  | text   | 30     |
| Priscilla | text   | 30     |
| Daphne | text   | 30     |
| Summary | textarea | 100 |
FORM
    $formTopicObject->save();
    $formTopicObject->finish();

    $topicObject->put( 'FORM', { name => 'TestForm' } );
    $topicObject->putKeyed( 'FIELD',
        { name => "Marjorie", title => "Number", value => "99" } );
    $topicObject->putKeyed( 'FIELD',
        { name => "Priscilla", title => "String", value => "" } );
    $topicObject->putKeyed( 'FIELD',
        { name => "Daphne", title => "String", value => "<nop>ElleBelle" } );
    $topicObject->putKeyed( 'FIELD',
        { name => "Summary", title => "Area", value => <<DONE} );

---++!! Highlights of this release
   * Major new Foswiki release
   * Hundreds enhancements relative to 1.1.9
DONE
    $topicObject->save();
}

sub test_FORMFIELD_simple {
    my $this = shift;

    my ($topicObject) = $this->{test_topicObject};
    my $result = $topicObject->expandMacros("%FORMFIELD%");
    $this->assert_str_equals( '', $result );
}

sub test_FORMFIELD_byname {
    my $this = shift;

    my ($topicObject) = $this->{test_topicObject};
    my $result = $topicObject->expandMacros('%FORMFIELD{"Marjorie"}%');
    $this->assert_str_equals( '99', $result );
}

sub test_FORMFIELD_Item13520 {
    my $this = shift;

    my ($topicObject) = $this->{test_topicObject};
    my $result = $topicObject->expandMacros('%FORMFIELD{"Summary"}%');
    $this->assert_str_equals( <<DONE, $result );

---++!! Highlights of this release
   * Major new Foswiki release
   * Hundreds enhancements relative to 1.1.9
DONE
}

# default="..." Text shown when no value is defined for the field
sub test_FORMFIELD_default {
    my $this = shift;

    my ($topicObject) = $this->{test_topicObject};
    my $result = $topicObject->expandMacros('%FORMFIELD{"Priscilla"}%');
    $this->assert_str_equals( '', $result );
    $result = $topicObject->expandMacros(
        '%FORMFIELD{"Priscilla" default="Clementina" alttext="Cressida"}%');
    $this->assert_str_equals( 'Clementina', $result );
    $result = $topicObject->expandMacros(
        '%FORMFIELD{"Priscilla" default="Clementina"}%');
    $this->assert_str_equals( 'Clementina', $result );

    # with format
    $result = $topicObject->expandMacros(
'%FORMFIELD{"Priscilla" format="Beauty queen: $value" default="Clementina"}%'
    );
    $this->assert_str_equals( 'Clementina', $result );
}

# alttext="..." Text shown when field is not found in the form
sub test_FORMFIELD_alttext {
    my $this = shift;

    my ($topicObject) = $this->{test_topicObject};
    my $result = $topicObject->expandMacros('%FORMFIELD{"Ffiona"}%');
    $this->assert_str_equals( '', $result );
    $result =
      $topicObject->expandMacros('%FORMFIELD{"Ffiona" alttext="Candida"}%');
    $this->assert_str_equals( 'Candida', $result );
    $result = $topicObject->expandMacros(
        '%FORMFIELD{"Ffiona" alttext="Candida" default="Cressida"}%');
    $this->assert_str_equals( 'Candida', $result );
    $result = $topicObject->expandMacros(
'%FORMFIELD{"Ffiona" format="Beauty queen: $value" alttext="Candida" default="Clementina"}%'
    );
    $this->assert_str_equals( 'Candida', $result );
}

# format="..." Format string. =$value= expands to the field value, and =$name= expands to the field name, =$title= to the field title, =$form= to the name of the form the field is in. The [[FormatTokens][standard format tokens]] are also expanded.
sub test_FORMFIELD_format {
    my $this = shift;

    my ($topicObject) = $this->{test_topicObject};
    my $result = $topicObject->expandMacros(
        '%FORMFIELD{"Marjorie" format="$name/$dollar$value/$title/$form"}%');
    $this->assert_str_equals( 'Marjorie/$99/Number/TestForm', $result );
    $result = $topicObject->expandMacros('%FORMFIELD{"Marjorie" format=""}%');
    $this->assert_str_equals( '', $result );

    # with default
    $result = $topicObject->expandMacros(
'%FORMFIELD{"Priscilla" format="Beauty queen: $value" default="Clementina"}%'
    );
    $this->assert_str_equals( 'Clementina', $result );

    # with 'default' default (empty string)
    $result = $topicObject->expandMacros(
        '%FORMFIELD{"Priscilla" format="Beauty queen: $value"}%');
    $this->assert_str_equals( '', $result );

    # with alttext
    $result = $topicObject->expandMacros(
'%FORMFIELD{"Ffiona" format="Beauty queen: $value" alttext="Candida" default="Clementina"}%'
    );
    $this->assert_str_equals( 'Candida', $result );

    # with default alttext (empty string)
    $result = $topicObject->expandMacros(
        '%FORMFIELD{"Ffiona" format="Beauty queen: $value"}%');
    $this->assert_str_equals( '', $result );
}

# topic="..." Topic where form data is located. May be of the form Web.<nop>TopicName
sub test_FORMFIELD_topic {
    my $this = shift;

    my ($topicObject) =
      Foswiki::Func::readTopic( $this->{test_web}, 'TestForm' );
    $this->{session}->{webName} = $this->{test_web};
    my $result = $topicObject->expandMacros('%FORMFIELD{"Marjorie"}%');
    $this->assert_str_equals( '', $result );
    $result = $topicObject->expandMacros(
        '%FORMFIELD{"Marjorie" topic="' . $this->{test_topic} . '"}%' );
    $this->assert_str_equals( '99', $result );
    $topicObject->finish();
    ($topicObject) = Foswiki::Func::readTopic( $Foswiki::cfg{SystemWebName},
        $Foswiki::cfg{HomeTopicName} );
    $result = $topicObject->expandMacros(
        '%FORMFIELD{"Marjorie" topic="' . $this->{test_topic} . '"}%' );
    $this->assert_str_equals( '', $result );
    $result =
      $topicObject->expandMacros( '%FORMFIELD{"Marjorie" topic="'
          . $this->{test_web} . '.'
          . $this->{test_topic}
          . '"}%' );
    $this->assert_str_equals( '99', $result );
    $topicObject->finish();
}

# web="..."
sub test_FORMFIELD_web {
    my $this = shift;

    # create other web
    $this->{other_web} = "$this->{test_web}other";
    my $webObject = $this->populateNewWeb( $this->{other_web} );
    $webObject->finish();
    my ($topicObject) =
      Foswiki::Func::readTopic( $this->{other_web}, $this->{test_topic} );
    $this->_createTopic( $this->{other_web}, $topicObject );

    ($topicObject) = Foswiki::Func::readTopic( $this->{test_web}, 'TestForm' );
    $this->{session}->{webName} = $this->{test_web};

    my $result = $topicObject->expandMacros('%FORMFIELD{"Marjorie"}%');
    $this->assert_str_equals( '', $result );
    $result =
      $topicObject->expandMacros( '%FORMFIELD{"Marjorie" web="'
          . $this->{other_web}
          . '" topic="'
          . $this->{test_topic}
          . '"}%' );
    $this->assert_str_equals( '99', $result );
    ($topicObject) = Foswiki::Func::readTopic( $Foswiki::cfg{SystemWebName},
        $Foswiki::cfg{HomeTopicName} );
    $result =
      $topicObject->expandMacros( '%FORMFIELD{"Marjorie" web="'
          . $this->{other_web}
          . '" topic="'
          . $this->{test_topic}
          . '"}%' );
    $this->assert_str_equals( '99', $result );

    # remove other web
    $this->removeWebFixture( $this->{session}, $this->{other_web} );
}

# Check if ! and <nop> are properly rendered
sub test_FORMFIELD_render_nops {
    my $this = shift;

    my ($topicObject) = $this->{test_topicObject};
    my $result = $topicObject->expandMacros('%FORMFIELD{"Daphne"}%');
    $this->assert_str_equals( '<nop>ElleBelle', $result );
    $result = $topicObject->expandMacros(
        '%FORMFIELD{"Ffiona" alttext="!NiceAsPie" default="Cressida"}%');
    $this->assert_str_equals( '<nop>NiceAsPie', $result );
    $result = $topicObject->expandMacros(
        '%FORMFIELD{"Priscilla" default="!NiceAsPie"}%');
    $this->assert_str_equals( '<nop>NiceAsPie', $result );
    $result = $topicObject->expandMacros(
        '%FORMFIELD{"Priscilla" default="<nop>NiceAsPie"}%');
    $this->assert_str_equals( '<nop>NiceAsPie', $result );

}

sub test_FORMFIELD_Item9269 {
    my $this = shift;

    my ($topicObject) = $this->{test_topicObject};
    my $result = $topicObject->expandMacros(
        '%FORMFIELD{"Daphne" format="$dollarvalue = $value"}%');
    $this->assert_str_equals( '$value = <nop>ElleBelle', $result );
}

sub test_FORMFIELD_Item10398 {
    my $this = shift;

    #topic does not exist.
    my ($topicObject) = $this->{test_topicObject};
    my $result = $topicObject->expandMacros(
'%FORMFIELD{"Daphne" format="$dollarvalue = $value" topic="SomeNonExistantTopicThatReallyShouldNotBeThere"}%'
    );
    $this->assert_str_equals( '', $result );
}

1;
