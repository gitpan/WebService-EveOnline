package WebService::EveOnline::API::Skills;

=head2 $character->skills

Returns an array of the skills held by the selected character.

=cut

sub skills {
	my ($self, $params) = @_;
	my $skills = $self->call_api('skills', { characterID => $self->character_id })->{skills};

    my @skillobjs;

	foreach my $skill (@{$skills}) {
		my $gs = $self->{_evecache}->get_skill($skill->{typeID});
		$skill->{name} = $gs->{typeName};
		$skill->{description} = $gs->{description};
        push(@skillobjs, bless({ 
            _skill_name => $gs->{typeName},
            _skill_description => $gs->{description},
            _skill_id => $skill->{typeID},
            _skill_level => $skill->{level},
            _skill_points => $skill->{skillpoints},
        }, ref($self)));
	}
	return @skillobjs;
}

=head2 $character->skill_in_training

Returns the skill currently in training for the selected character.

=cut

sub skill_in_training {
	my ($self, $params) = @_;
	my $raw_training = $self->call_api('training', { characterID => $self->character_id });
	my $training = {};
    
    my $trainref = { _skill_id => undef, _skill_name => undef, _skill_description => undef, _skill_in_training => undef,
                     _skill_in_training_level => undef, _skill_in_training_start_time => undef, _skill_in_training_finish_time => undef,
                     _skill_in_training_start_sp => undef, _skill_in_training_finish_sp => undef,
    };

	foreach my $tdetail (keys %{$raw_training}) {
		next if $tdetail =~ /^_/;
		next if ref($raw_training->{$tdetail}) eq "HASH";
		$training->{$tdetail} = $raw_training->{$tdetail};
	}

    return bless($trainref, ref($self)) unless $training->{skillInTraining} == 1;

	my $gs = $self->{_evecache}->get_skill($training->{trainingTypeID});
	
    $trainref->{_skill_id} = $training->{trainingTypeID};
    $trainref->{_skill_name} = $gs->{typeName};
	$trainref->{_skill_description} = $gs->{description};
    $trainref->{_skill_level} = $training->{trainingToLevel};
    $trainref->{_skill_in_training} = $training->{skillInTraining};
    $trainref->{_skill_in_training_start_time} = &WebService::EveOnline::Cache::_evedate_to_epoch($training->{trainingStartTime}) if $training->{trainingStartTime};
    $trainref->{_skill_in_training_finish_time} = &WebService::EveOnline::Cache::_evedate_to_epoch($training->{trainingEndTime}) if $training->{trainingEndTime};
    $trainref->{_skill_in_training_start_sp} = $training->{trainingStartSP};
    $trainref->{_skill_in_training_finish_sp} = $training->{trainingDestinationSP};

	return bless($trainref, ref($self));
}

=head2 $char->skill_in_training->start_time, $skill_in_training->start_time

Start time (epoch seconds) of skill currently training

=cut

sub start_time {
    my ($self) = @_;
    return $self->{_skill_in_training_start_time} || 0;
}

=head2 $char->skill_in_training->start_sp, $skill_in_training->start_sp

Start SP of skill currently training

=cut

sub start_sp {
    my ($self) = @_;
    return $self->{_skill_in_training_start_sp} || 0;
}


=head2 $char->skill_in_training->finish_time, $skill_in_training->finish_time

Finish time (epoch seconds) of skill currently training

=cut

sub finish_time {
    my ($self) = @_;
    return $self->{_skill_in_training_finish_time} || 0;
}

=head2 $char->skill_in_training->finish_sp, $skill_in_training->finish_sp

Finish SP of skill currently training

=cut

sub finish_sp {
    my ($self) = @_;
    return $self->{_skill_in_training_finish_sp} || 0;
}

=head2 $skill->skill_description

Returns a skill description from a skill object.

=cut

sub skill_description {
    my ($self) = @_;
    return $self->{_skill_description} ? $self->{_skill_description} : undef;
}

=head2 $skill->skill_id

Returns a skill id from a skill object.

=cut

sub skill_id {
    my ($self) = @_;
    return $self->{_skill_id} ? $self->{_skill_id} : undef;
}

=head2 $skill->skill_level

Returns a skill level from a skill object.

=cut

sub skill_level {
    my ($self) = @_;
    return $self->{_skill_level} ? $self->{_skill_level} : undef;
}

=head2 $skill->skill_points

Returns the number of skill points from a skill object.

=cut

sub skill_points {
    my ($self) = @_;
    return $self->{_skill_points} ? $self->{_skill_points} : undef;
}

=head2 $skill->skill_name

Returns a skill name from a skill object.

=cut

sub skill_name {
    my ($self) = @_;
    return $self->{_skill_name} ? $self->{_skill_name} : undef;
}

=head2 $skill->skill_hashref

Returns a hashref from a skill object containing the following keys:

    skill_description
    skill_id
    skill_level
    skill_points
    skill_name

=cut

sub skill_hashref {
    my ($self) = @_;
    
    return { 
        skill_description => $self->{_skill_description} || undef,
        skill_id =>  $self->{_skill_id} || undef,
        skill_level => $self->{_skill_level} || undef,
        skill_points => $self->{_skill_points} || undef,
        skill_name => $self->{_skill_name} || undef,
    };
}

=head2 $character->all_eve_skills

Returns a big datastructure containing all currently available skills in EVE.
Used to build the skill cache.

=cut

sub all_eve_skills {
	my ($self, $params) = @_;
	return $self->call_api('all_skills', {});
}

1;

