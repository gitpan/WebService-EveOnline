package WebService::EveOnline::API::Character;

=head2 $eve->characters

Returns an array of character objects for each characters available via
your API key.

=cut

sub characters {
	my ($self, $params) = @_;
	my $character_data = $self->call_api('character', {});
	my $characters = [];
	foreach my $character (sort keys %{$character_data}) {
		next if $character =~ /^_/; # skip meta keys
		push(@{$characters}, bless({ 
                 _character_name => $character, 
                 _corporation_name => $character_data->{$character}->{corporationName},
                 _corporation_id => $character_data->{$character}->{corporationID},
                 _character_id => $character_data->{$character}->{characterID},
                 _api_key => $self->api_key,
                 _user_id => $self->user_id,
                 _evecache => $self->{_evecache},
            }, ref($self))
		);
	}
	return @{$characters};
}

=head2 $character->character_hashref

Returns a character hashref on a character object containing the following keys:

   character_id
   character_name
   character_race
   character_gender
   character_bloodline
   corporation_name
   corporation_id

=cut

sub character_hashref {
    my ($self) = @_;
    return {
        character_name => $self->{_character_name},
        corporation_name => $self->{_corporation_name},
        character_id => $self->{_character_id},
        corporation_id => $self->{_corporation_id},
        character_race => $self->character_race,
        character_gender => $self->character_gender,
        character_bloodline => $self->character_bloodline,
    };
}

=head2 $eve->character($id || $name)

Returns a character object given a particular id or name.

=cut

sub character {
	my ($self, $id) = @_;
    foreach my $character ($self->characters) {
        return $character if $character->character_name eq $id || $character->character_id == $id; 
    }
	return undef;
}

=head2 $character->character_name

Returns the name of the current character based on the character object.

=cut

sub character_name {
	my ($self) = @_;
    return $self->{_character_name};
}

=head2 $character->character_id

Returns a character object based on the character id you provide, assuming
your API key allows it.

=cut

sub character_id {
	my ($self) = @_;
	return $self->{_character_id};		
}

=head2 $character->character_race

The race of the selected character.

=cut

sub character_race {
	my ($self, $params) = @_;
	my $race = $self->call_api('race', { characterID => $self->character_id });
	return $race->{race};	
}

=head2 $character->character_bloodline

The bloodline of the selected character.

=cut

sub character_bloodline {
	my ($self, $params) = @_;
	my $bloodline = $self->call_api('bloodline', { characterID => $self->character_id });
	return $bloodline->{bloodLine};	
}

=head2 $character->character_gender

The gender of the selected character.

=cut

sub character_gender {
	my ($self, $params) = @_;
	my $gender = $self->call_api('gender', { characterID => $self->character_id });
	return $gender->{gender};	
}

=head2 $character->attributes

Sets the base attributes held by the selected character.

=cut

sub attributes {
	my ($self, $params) = @_;
	my $attributes = $self->call_api('attributes', { characterID => $self->character_id });

    $self->{_attributes} = {
        _memory => $attributes->{memory},
        _intelligence => $attributes->{intelligence},
        _charisma => $attributes->{charisma},
        _perception => $attributes->{perception},
        _willpower => $attributes->{willpower},
    };

	return bless($self, ref($self));	
}

=head2 $character->attributes->memory, $attributes->memory

Returns the base memory attribute of the current character

=cut

sub memory {
    my ($self) = @_;
    return $self->{_attributes}->{_memory};
}

=head2 $character->attributes->intelligence, $attributes->intelligence

Returns the base intelligence attribute of the current character

=cut

sub intelligence {
    my ($self) = @_;
    return $self->{_attributes}->{_intelligence};
}

=head2 $character->attributes->charisma, $attributes->charisma

Returns the base charisma attribute of the current character

=cut

sub charisma {
    my ($self) = @_;
    return $self->{_attributes}->{_charisma};
}

=head2 $character->attributes->perception, $attributes->perception

Returns the base perception attribute of the current character

=cut

sub perception {
    my ($self) = @_;
    return $self->{_attributes}->{_perception};
}

=head2 $character->attributes->willpower, $attributes->willpower

Returns the base willpower attribute of the current character

=cut

sub willpower {
    my ($self) = @_;
    return $self->{_attributes}->{_willpower};
}

=head2 $character->attributes->attr_hashref, $attributes->attr_hashref

Returns a hashref containing the base attributes of the
current character with the following keys:
    
    memory
    intelligence
    charisma
    perception
    willpower

=cut

sub attr_hashref {
    my ($self) = @_;
    return {
        memory => $self->{_attributes}->{_memory},  
        intelligence => $self->{_attributes}->{_intelligence},  
        charisma => $self->{_attributes}->{_charisma},  
        perception => $self->{_attributes}->{_perception},  
        willpower => $self->{_attributes}->{_willpower},  
    };
}

=head2 $character->attribute_enhancers

Returns a hash of hashes of the attribute enhancers held by the selected character.
The interface to this is highly likely to change to be more consistent with the rest of the
interface, so use with caution.

=cut

sub attribute_enhancers {
	my ($self, $params) = @_;
	my $enhancers = $self->call_api('enhancers', { characterID => $self->character_id });
	return $enhancers;	
}

=head2 $character->account_balance

The account balance of the selected character.

=cut

sub account_balance {
	my ($self, $params) = @_;
	my $balance = $self->call_api('balance', { characterID => $self->character_id });
	return $balance->{balance};
}

1;
