package WebService::EveOnline::Base;

use LWP::UserAgent;
use HTTP::Request;
use XML::Simple;

use WebService::EveOnline::Cache;

use base qw/ WebService::EveOnline::API::Character 
             WebService::EveOnline::API::Skills 
             WebService::EveOnline::API::Transactions
             WebService::EveOnline::API::Journal
             WebService::EveOnline::API::Map /;

# U.G.L.Y. You ain't got no alibi (this is where we set up the API mappings, sort out the internal symbol conversion and set max cache times)
our $API_MAP = {
	skills       => { endpoint => 'char/CharacterSheet',     params => [ [ 'character_id',    'characterID'   ] ], max_cache => 900     },
	balance      => { endpoint => 'char/CharacterSheet',     params => [ [ 'character_id',    'characterID'   ] ], max_cache => 60      },
	race         => { endpoint => 'char/CharacterSheet',     params => [ [ 'character_id',    'characterID'   ] ], max_cache => 604800  },
	bloodline    => { endpoint => 'char/CharacterSheet',     params => [ [ 'character_id',    'characterID'   ] ], max_cache => 604800  },
	attributes   => { endpoint => 'char/CharacterSheet',     params => [ [ 'character_id',    'characterID'   ] ],                      },
	enhancers    => { endpoint => 'char/CharacterSheet',     params => [ [ 'character_id',    'characterID'   ] ],                      },
	gender       => { endpoint => 'char/CharacterSheet',     params => [ [ 'character_id',    'characterID'   ] ], max_cache => 604800  },
	training     => { endpoint => 'char/SkillInTraining',    params => [ [ 'character_id',    'characterID'   ] ],                      },
	transactions => { endpoint => 'char/WalletTransactions', params => [ 
                                                                         [ 'character_id',    'characterID'   ], 
                                                                         [ 'before_trans_id', 'beforeTransID' ], 
                                                                         [ 'account_key',     'accountKey'    ],  
                                                                                                                ],                      },
    character    => { endpoint => 'account/Characters',      params => undef,                                                           },
	all_skills   => { endpoint => 'eve/SkillTree',           params => undef,                                                           },
	all_reftypes => { endpoint => 'eve/RefTypes',            params => undef,                                                           },
};

=head2 new

Called by WebService::EveOnline->new -- sets things up at the backend without cluttering things up.
Doesn't die if not passed an api_key/user_id combination, unlike the latter.

=cut

sub new {
	my ($class, $params) = @_;

	$params ||= {};
	$params->{cache_type}   ||= "SQLite";
	$params->{cache_user}   ||= "";
	$params->{cache_pass}   ||= "";
	$params->{cache_dbname} ||= "/tmp/webservice_eveonline.db";
	$params->{cache_init}   ||= "yes";
	$params->{cache_maxage} ||= (86400 * 7); # time (s) between cache rebuilds. A week, for now.
	
	my $evecache = WebService::EveOnline::Cache->new( { eve_user_id => $params->{user_id}, cache_type => $params->{cache_type}, cache_dbname => $params->{cache_dbname} } ) if $params->{cache_init} eq "yes";
	if ($evecache && $evecache->cache_age >= $params->{cache_maxage}) {
		$evecache->repopulate('all_skills', call_api('all_skills'));
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

=head2 $eve->call_api(<command>, <params>)

Call the Eve API and retrieve the results. Look in the cache first. Cache results according to API map settings.

=cut

sub call_api {
	my ($self, $command, $params) = @_;
		
	my $auth = { user_id => "", api_key => "" };

	if (ref($self)) {
		$auth = { user_id => $self->user_id, api_key => $self->api_key };
	} else {
		$command = $self;
	}	
	
	if ( defined($API_MAP->{$command}) ) {
		
		my $gen_params = _gen_params($self, $API_MAP->{$command}->{params}, $params);
		
		my $cached_response = $self->{_evecache}->retrieve( { command => "$command", params => $gen_params } ) if ref($self);
		return $cached_response if $cached_response;

		my $ua = LWP::UserAgent->new;
		$ua->agent("$WebService::EveOnline::AGENT/$WebService::EveOnline::VERSION");

		my $req = HTTP::Request->new( POST => $WebService::EveOnline::EVE_API . $API_MAP->{$command}->{endpoint} . '.xml.aspx' );
		$req->content_type("application/x-www-form-urlencoded");

		my $content = 'userid=' . $auth->{user_id} . '&apikey=' . $auth->{api_key} . $gen_params;
		$req->content($content) ;
	
		my $res = $ua->request($req);
		if ($res->is_success) {
			my $xs = XML::Simple->new();
			my $xml = $res->content;
			my $pre = $xs->XMLin($xml);
			my $data = {};
            my $in_error_state = undef;

            # print out any error content if it's set.
            if ($pre->{error}->{content}) {
                $in_error_state = 1;
                $data->{error} = "EVE API Error: " . $pre->{error}->{content} . " (" . $pre->{error}->{code} . ")";
            }

            # at the moment, we deal in hashrefs. one day, these will be objects (like everything else will be ;-P)
			if ($command eq "character") {
				$data = $pre->{result}->{rowset}->{row};
			} elsif ($command eq "skills") {
				$data->{skills} = $pre->{result}->{rowset}->{row} if $pre->{result}->{rowset}->{row};
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
			} elsif ($command eq "transactions") {
				$data->{transactions} = $pre->{result}->{rowset}->{row} if $pre->{result}->{rowset}->{row};
			} else {
				$data = $pre;
				return $data;
			}

			$data->{_status} ||= "ok";
			$data->{_xml} = $xml;
			$data->{_parsed_as} = $pre;

			my $stripped_data = undef;
			
			unless ($WebService::EveOnline::DEBUG_MODE) {
				$stripped_data = {};
				foreach my $strip_debug (keys %{$data}) {
					next if $strip_debug =~ /^_/; # skip meta keys
					$stripped_data->{$strip_debug} = $data->{$strip_debug};
				}
			}

			if (ref($self) && $data && !$in_error_state) {
                # error results are not cached
				return $self->{_evecache}->store( { command => $command, obj => $self, data => $stripped_data || $data, params => $gen_params, cache_until => $pre->{cachedUntil}, max_cache => $API_MAP->{$command}->{max_cache}  } );
            } elsif ($in_error_state) {
                warn $data->{error} . "\n";
                return undef; # better error handling is required...;
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
	my ($self, $keys, $passed) = @_;
	return "" unless defined $keys;
	
	my @kvp = ();
	foreach my $param (@{$keys}) {
        my ($intkey, $evekey) = @{$param};
		push(@kvp, "$evekey=" . ($self->$intkey || $passed->{$intkey})) if ($self->$intkey || $passed->{$intkey});
	}

	return '&' . (join('&', @kvp));
}

1;
