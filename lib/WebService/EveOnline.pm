package WebService::EveOnline;

use strict;
use warnings;

use WebService::EveOnline::Cache;

use LWP::UserAgent;
use HTTP::Request;
use XML::Simple;

use Data::Dumper;

our $VERSION = '0.01';
our $AGENT = 'WebService::EveOnline';
our $DEBUG_MODE = undef;
our $EVE_API = "http://api.eve-online.com/";

our $API_MAP = {
	character    => { endpoint => 'account/Characters',   params => undef,             },
	skills       => { endpoint => 'char/CharacterSheet',  params => [ 'characterID' ], },
	balance      => { endpoint => 'char/CharacterSheet',  params => [ 'characterID' ], },
	race         => { endpoint => 'char/CharacterSheet',  params => [ 'characterID' ], },
	bloodline    => { endpoint => 'char/CharacterSheet',  params => [ 'characterID' ], },
	attributes   => { endpoint => 'char/CharacterSheet',  params => [ 'characterID' ], },
	enhancers    => { endpoint => 'char/CharacterSheet',  params => [ 'characterID' ], },
	gender       => { endpoint => 'char/CharacterSheet',  params => [ 'characterID' ], },
	training     => { endpoint => 'char/SkillInTraining', params => [ 'characterID' ], },
	all_skills   => { endpoint => 'eve/SkillTree',        params => undef,             },
	all_reftypes => { endpoint => 'eve/RefTypes',         params => undef,             },
};

=head1 NAME

WebService::EveOnline -- a wrapper intended to (eventually) provide a 
consistent interface to the MMORPG game, "Eve Online"

(N.B. Export EVE_USER_ID and EVE_API_KEY to your environment before installing 
to run all tests.) 

Running under MS Windows will not work without tweaking. Support for non-unix architectures
is intended to follow at a later date. Please consider this module's status as
EXPERIMENTAL.

=head1 VERSION

0.01 -- This is an incomplete implementation of the Eve Online API, but is a starting point.

=head1 SYNOPSIS

	use WebService::EveOnline;
	
	my $eve = WebService::EveOnline->new({
		user_id => <user_id>,
		api_key => '<api_key>'
	});
	
	my $character = $eve->character->name('<character_name>');
	
	print $character->training->{name} . " will finish training at " .
	 $character->training->{training_end} . "\n";

=head1 DESCRIPTION

WebService::EveOnline (essentially) presents a nice programatic sugar over the
top of the pretty cronky API that CCP games provide. The idea is that an 
interested party (e.g. me) can keep track of what's going on with my characters
in a similar manner to what EveMON does.

There is currently no item data provided with this interface (although the API 
exposes no item data anyway, it'd be nice to have at some point).

Also, no map or wallet information is supported although this will be added as
a priority over the coming weeks.

=cut

=head2 Initialising

WebService::EveOnline is instantiated with a 'standard' (so much as these 
things are) call to "new". Usually, at this point you would pass down a
hashref that contained the keys "user_id" and "api_key" as demonstrated in the
synopsis.

You MUST specify your user_id and api_key parameters in order to get the API to
work, even if you're only interested in returning data where they are not 
normally required by the API.

You may also specify the following parameters:

cache_type: Defaults to 'SQLite'. For now, please keep the default.
cache_dbname: Database to use to store cached skill data.
cache_user: Username of the database to use. Do not use yet.
cache_pass: Password of the database to use. Do not use yet.
cache_init: Set this to 'no' to disable caching. Not recommended.
cache_maxage: Maximum time (in seconds) to wait before a cache rebuild.

Currently, only SQLite databases are supported. Using another database should
be fairly straightforward to add in, but isn't available yet.

You can specify ":memory" as the cache_dbname to build the cache in memory if
required.

=head1 API

API reference as follows:

=cut

=head2 new
   
Set up the initial object by calling the new method on it. It is important to
pass a valid user id and api key (available from http://api.eve-online.com/)
or this module will not do anything useful. That is does anything useful at
all is debatable, but it does let me print out my favourite character's account
balance, so that's pretty much all I want/need it to do at the moment... :-)

    my $eve = WebService::EveOnline->new({
		user_id => <user_id>,
		api_key => '<api_key>'
	});

=cut

sub new {
	my ($class, $params) = @_;

	$params ||= {};
	$params->{cache_type} ||= "SQLite";
	$params->{cache_user} ||= "";
	$params->{cache_pass} ||= "";
	$params->{cache_dbname} ||= "/tmp/webservice_eveonline.db";
	$params->{cache_init} ||= "yes";
	$params->{cache_maxage} ||= 86400; # a day, for now.
	
	die("Cannot instantiate without a user_id/api_key!\nPlease visit $EVE_API if you still need to get one.") unless $params->{user_id} && $params->{api_key};
	
	my $evecache = WebService::EveOnline::Cache->new( { cache_type => $params->{cache_type}, cache_dbname => $params->{cache_dbname} } ) if $params->{cache_init} eq "yes";
	if ($evecache && $evecache->cache_age >= $params->{cache_maxage}) {
		$evecache->repopulate('all_skills', _call_api('all_skills'));
	} else {
		$evecache ||= WebService::EveOnline::Cache->new( { cache_type => "no_cache" } );
	}
	
	return bless({ _user_id => $params->{user_id}, _api_key => $params->{api_key}, _evecache => $evecache }, $class);
}

=head2 $eve->user_id

Returns the current user_id.

=cut

sub user_id {
	my ($self, $user_id) = @_;
	$self->{_user_id} = $user_id if $user_id;
	return $self->{_user_id};
}

=head2 $eve->api_key

Returns the current api_key.

=cut

sub api_key {
	my ($self, $api_key) = @_;
	$self->{_api_key} = $api_key if $api_key;
	return $self->{_api_key};
}

=head2 $eve->character_id(<character_id>)

Returns a character object based on the character id you provide, assuming
your API key allows it.

=cut

sub character_id {
	my ($self, $character_id) = @_;
	if ($character_id) {
		foreach my $character (@{$self}) {
			return bless($character, ref($self)) if $character->{_character_id} eq $character_id;
		}
	} else {
		return $self->{_character_id};		
	}
	return bless({}, ref($self));
}


=head2 $eve->characters, $eve->character

Returns an array of character objects for the characters available via
your API key.

The 'character' call is provided for grammatical sense where appropriate.

=cut

sub characters {
	my ($self, $params) = @_;
	my $character_data = _call_api($self, 'character', {});
	my $characters = [];
	foreach my $character (sort keys %{$character_data}) {
		next if $character =~ /^_/; # skip meta keys
		push(@{$characters}, { _name => $character, 
			  _corporation_name => $character_data->{$character}->{corporationName},
							 _corporation_id => $character_data->{$character}->{corporationID},
							 _character_id => $character_data->{$character}->{characterID},
							 _api_key => $self->api_key,
							 _user_id => $self->user_id,
							 _evecache => $self->{_evecache},
							 }
		);
	}
	return bless($characters, ref($self));
}

sub character {
	my ($self, $params) = @_;
	return bless($self->characters(), ref($self));
}

=head2 $character->name

Returns the name of the current character based on the character object.

=cut

sub name {
	my ($self, $name) = @_;
	if ($name) {
		foreach my $character (@{$self}) {
			return bless($character, ref($self)) if $character->{_name} eq $name;
		}
	} else {
		return $self->{_name};
	}
	return bless({}, ref($self));
}

=head2 $character->skills

Returns an array of the skills held by the selected character.

=cut

sub skills {
	my ($self, $params) = @_;
	my $skills = _call_api($self, 'skills', { characterID => $self->character_id });

	foreach my $skill (@{$skills->{rowset}->{row}}) {
		my $gs = $self->{_evecache}->get_skill($skill->{typeID});
		$skill->{name} = $gs->{typeName};
		$skill->{description} = $gs->{description};
	}

	return $skills;
}

=head2 $character->attributes

Returns an array of attributes held by the selected character.

=cut

sub attributes {
	my ($self, $params) = @_;
	my $attributes = _call_api($self, 'attributes', { characterID => $self->character_id });
	return $attributes;	
}

=head2 $character->attribute_enhancers

Returns an array of the attribute enhancers held by the selected character.

=cut

sub attribute_enhancers {
	my ($self, $params) = @_;
	my $enhancers = _call_api($self, 'enhancers', { characterID => $self->character_id });
	return $enhancers;	
}

=head2 $character->account_balance

The account balance of the selected character.

=cut

sub account_balance {
	my ($self, $params) = @_;
	my $balance = _call_api($self, 'balance', { characterID => $self->character_id });
	return $balance->{balance};
}

=head2 $character->race

The race of the selected character.

=cut

sub race {
	my ($self, $params) = @_;
	my $race = _call_api($self, 'race', { characterID => $self->character_id });
	return $race->{race};	
}

=head2 $character->bloodline

The bloodline of the selected character.

=cut

sub bloodline {
	my ($self, $params) = @_;
	my $bloodline = _call_api($self, 'bloodline', { characterID => $self->character_id });
	return $bloodline->{bloodLine};	
}

=head2 $character->gender

The gender of the selected character.

=cut

sub gender {
	my ($self, $params) = @_;
	my $gender = _call_api($self, 'gender', { characterID => $self->character_id });
	return $gender->{gender};	
}

=head2 $character->training

Returns the skill currently in training for the selected character.

=cut

sub training {
	my ($self, $params) = @_;
	my $raw_training = _call_api($self, 'training', { characterID => $self->character_id });
	my $training = {};
	foreach my $tdetail (keys %{$raw_training}) {
		next if $tdetail =~ /^_/;
		next if ref($raw_training->{$tdetail}) eq "HASH";
		$training->{$tdetail} = $raw_training->{$tdetail};
	}

	my $gs = $self->{_evecache}->get_skill($training->{trainingTypeID});
	$training->{name} = $gs->{typeName};
	$training->{description} = $gs->{description};

	return $training;
}


=head2 $character->all_eve_skills

Returns all currently available skills in EVE.

=cut

sub all_eve_skills {
	my ($self, $params) = @_;
	return _call_api($self, 'all_skills', {});
}

sub _call_api {
	my ($self, $command, $params) = @_;
		
	my $auth = { user_id => "", api_key => "" };

	if (ref($self)) {
		$auth = { user_id => $self->user_id, api_key => $self->api_key };
	} else {
		$command = $self;
	}	
	
	if ( defined($API_MAP->{$command}) ) {
		
		my $gen_params = _gen_params($API_MAP->{$command}->{params}, $params);
		
		my $cached_response = $self->{_evecache}->retrieve( { command => "$command", params => $gen_params } ) if ref($self);
		return $cached_response if $cached_response;

		my $ua = LWP::UserAgent->new;
		$ua->agent("$AGENT/$VERSION");

		my $req = HTTP::Request->new( POST => $EVE_API . $API_MAP->{$command}->{endpoint} . '.xml.aspx' );
		$req->content_type("application/x-www-form-urlencoded");

		my $content = 'userid=' . $auth->{user_id} . '&apikey=' . $auth->{api_key} . $gen_params;
		$req->content($content) ;
	
		my $res = $ua->request($req);
		if ($res->is_success) {
			my $xs = XML::Simple->new();
			my $xml = $res->content;
			my $pre = $xs->XMLin($xml);
			my $data = {};
			
			if ($command eq "character") {
				$data = $pre->{result}->{rowset}->{row};
			} elsif ($command eq "skills") {
				$data = $pre->{result};
			} elsif ($command eq "attributes") {
				$data = $pre->{result}->{attributes};
			} elsif ($command eq "enhancers") {
				$data = $pre->{result}->{attributeEnhancers};
			} elsif ($command eq "gender") {
				$data = $pre->{result};
			} elsif ($command eq "race") {
				$data = $pre->{result};
			} elsif ($command eq "bloodline") {
				$data = $pre->{result};
			} elsif ($command eq "balance") {
				$data = $pre->{result};
			} elsif ($command eq "training") {
				$data = $pre->{result};				
			} else {
				$data = $pre;
				return $data;
			}

			$data->{_status} = "ok";
			$data->{_xml} = $xml;
			$data->{_parsed_as} = $pre;

			my $stripped_data = undef;
			
			unless ($DEBUG_MODE) {
				$stripped_data = {};
				foreach my $strip_debug (keys %{$data}) {
					next if $strip_debug =~ /^_/; # skip meta keys
					$stripped_data->{$strip_debug} = $data->{$strip_debug};
				}
			}

			if (ref($self)) {
				return $self->{_evecache}->store( { command => $command, obj => $self, data => $stripped_data || $data, params => $gen_params, cache_until => $pre->{cachedUntil}  } );
			} else {
				return $stripped_data || $data;
			}
		} else {
			return { _status => "error", message => $res->status_line, _raw => undef };		
		}
	} else {
		return { _status => "error", message => "Bad command", _raw => undef };		
	}
	
}

sub _gen_params {
	my ($keys, $passed) = @_;
	return "" unless defined $keys;
	
	my @kvp = ();
	foreach my $param (@{$keys}) {
		push(@kvp, "$param=" . $passed->{$param});
	}
	return '&' . (join('&', @kvp));
}

=head1 BUGS

If you don't happen to have my specific user_id and api_key, you milage may 
*seriously* vary. I've not been playing Eve Online all that long, and there 
are probably dozens of edge cases I need to look at and resolve.

Contributions/patches/suggestions are all gratefully received.

Please report any bugs or feature requests to C<bug-webservice-eveonline at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-EveOnline>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 MOTIVATION

Frankly, whilst the Eve Online API is better than nothing, it's pretty horrible
to work with. I wanted to concentrate on my code rather than parsing results, so
I decided to hide the gory details away in a nice module I didn't have to look at
much. Having said that, by no means is this code considered anything other than a
quick and dirty hack that does precisely the job I want it to do (and no more).

=head1 AUTHOR

Chris Carline, C<< <chris at carline.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2007 Chris Carline, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
