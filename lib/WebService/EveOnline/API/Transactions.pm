package WebService::EveOnline::API::Transactions;

=head2 $character->transactions

Recent transaction list (last 1000). Set offset before_trans_id to recall older transactions.

=cut

sub transactions {
	my ($self, $params) = @_;
	my $raw_transactions = $self->call_api('transactions', { characterID => $self->character_id, beforeTransID => $self->before_trans_id });
    
    my @transactions;
    foreach my $trans (@{$raw_transactions->{transactions}}) {
        push(@transactions, bless({
            _trans_for => $trans->{transactionFor},
            _trans_type_name => $trans->{typeName},
            _trans_type => $trans->{transactionType},
            _trans_quantity => $trans->{quantity},
            _trans_station_id => $trans->{stationID},
            _trans_client_id => $trans->{clientID},
            _trans_client_name => $trans->{clientName},
            _trans_type_id => $trans->{typeID},
            _trans_id => $trans->{transactionID},
            _trans_price => $trans->{price},
            _trans_time => &WebService::EveOnline::Cache::_evedate_to_epoch($trans->{transactionDateTime}),
            _trans_station_name => $trans->{stationName},
        }, ref($self)));
    }
    return @transactions;
}

=head2 $transaction->transaction_hashref

A hashref containing the details for a transaction. It contains the following keys:

    transaction_for
    transaction_type_name
    transaction_type
    transaction_quantity
    transaction_station_id
    transaction_client_id
    transaction_client_name
    transaction_type_id
    transaction_id
    transaction_price
    transaction_time
    transaction_station_name

=cut

sub transaction_hashref {
    my ($self) = @_;
    return {
        transaction_for => $self->{_trans_for},
        transaction_type_name => $self->{_trans_type_name},
        transaction_type => $self->{_trans_type},
        transaction_quantity => $self->{_trans_quantity},
        transaction_station_id => $self->{_trans_station_id},
        transaction_client_id => $self->{_trans_client_id},
        transaction_client_name => $self->{_trans_client_name},
        transaction_type_id => $self->{_trans_type_id},
        transaction_id => $self->{_trans_id},
        transaction_price => $self->{_trans_price},
        transaction_time => $self->{_trans_time},
        transaction_station_name => $self->{_trans_station_name},
    };
}

=head2 $transaction->transaction_for

Who the transaction is for (personal, or presumably corporate)

=cut

sub transaction_for {
    my ($self) = @_;
    return $self->{_trans_for};
}

=head2 $transaction->transaction_type_name

The name of the transaction, e.g. the name of the item you're selling/buying.

=cut

sub transaction_type_name {
    my ($self) = @_;
    return $self->{_trans_type_name};
}

=head2 $transaction->transaction_type

The transaction type (e.g. buy/sell)

=cut

sub transaction_type {
    my ($self) = @_;
    return $self->{_trans_type};
}

=head2 $transaction->transaction_quantity

The quantity involved in the transaction

=cut

sub transaction_quantity {
    my ($self) = @_;
    return $self->{_trans_quantity};
}

=head2 $transaction->transaction_station_id

The station ID of where the transaction took place (see also transaction_station_name)

=cut

sub transaction_station_id {
    my ($self) = @_;
    return $self->{_trans_station_id};
}

=head2 $transaction->transaction_client_id

The ID of the client (who is buying/selling the item)

=cut

sub transaction_client_id {
    my ($self) = @_;
    return $self->{_trans_client_id};
}

=head2 $transaction->transaction_client_name

The name of the client (who is buying/selling the item)

=cut

sub transaction_client_name {
    my ($self) = @_;
    return $self->{_trans_client_name};
}

=head2 $transaction->transaction_type_id

The type ID of the transaction. 

=cut

sub transaction_type_id {
    my ($self) = @_;
    return $self->{_trans_type_id};
}

=head2 $transaction->transaction_id

The ID of the transaction. Use the lowest transaction ID to walk back in time by setting before_trans_id.

=cut

sub transaction_id {
    my ($self) = @_;
    return $self->{_trans_id};
}

=head2 $transaction->transaction_price

The price of the transaction

=cut

sub transaction_price {
    my ($self) = @_;
    return $self->{_trans_price};
}

=head2 $transaction->transaction_time

The time of the transaction in epoch seconds.

=cut

sub transaction_time {
    my ($self) = @_;
    return $self->{_trans_time};
}

=head2 $transaction->transaction_station_id

The station id where the transaction took place (see also transaction_station_name).

=cut

sub transaction_station_id {
    my ($self) = @_;
    return $self->{_trans_station_id};
}

=head2 $character->before_trans_id

Set to return transactions older than a particular trans id for character/corp transactions.

=cut

sub before_trans_id {
	my ($self, $before_trans_id) = @_;
	$self->{_before_trans_id} = $before_trans_id if $before_trans_id;
	return $self->{_before_trans_id} || undef;
}

=head2 $character->account_key

Sets the account key for retrieving transactions from a particular account. defaults to 1000.

=cut

sub account_key {
	my ($self, $account_key) = @_;
	$self->{_account_key} = $account_key if $account_key;
	return $self->{_account_key} || 1000;
}

1;

