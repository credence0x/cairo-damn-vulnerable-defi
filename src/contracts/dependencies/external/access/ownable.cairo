use starknet::ContractAddress;

#[starknet::interface]
trait IOwnable<TContractState> {
    fn owner(self: @TContractState) -> ContractAddress;
    fn transfer_ownership(ref self: TContractState, new_owner: ContractAddress);
    fn renounce_ownership(ref self: TContractState);
}

#[starknet::contract]
mod ownable {
   
    use starknet::ContractAddress;
    use starknet::get_caller_address;
    use zeroable::Zeroable;

    #[storage]
    struct Storage {
        owner: ContractAddress
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        OwnershipTransferred : OwnershipTransferred
    }

    #[derive(Drop, starknet::Event)]
    struct OwnershipTransferred {
        previous_owner: ContractAddress, 
        new_owner: ContractAddress
    }


    #[external(v0)]
    impl OwnableImpl of super::IOwnable<ContractState> {
        fn owner(self: @ContractState) -> ContractAddress {
            self.owner.read()
        }

        fn transfer_ownership(ref self: ContractState, new_owner: ContractAddress) {
            assert(new_owner.is_non_zero(), 'New owner is the zero address');
            InternalOwnableImpl::assert_only_owner(@self);
            InternalOwnableImpl::_transfer_ownership(ref self, new_owner);
        }

        fn renounce_ownership(ref self: ContractState) {
            InternalOwnableImpl::assert_only_owner(@self);
            InternalOwnableImpl::_transfer_ownership(ref self, Zeroable::zero());
        }
    }



    #[generate_trait]
    impl InternalOwnableImpl of InternalOwnableTrait {

        fn initializer(ref self: ContractState, owner: ContractAddress) {
            InternalOwnableImpl::_transfer_ownership(ref self, owner);
        }

        fn assert_only_owner(self: @ContractState) {
            let owner: ContractAddress = self.owner.read();
            let caller: ContractAddress = get_caller_address();
            assert(caller.is_non_zero(), 'Caller is the zero address');
            assert(caller == owner, 'Caller is not the owner');
        }

        fn _transfer_ownership(ref self: ContractState, new_owner: ContractAddress) {
            let previous_owner: ContractAddress = self.owner.read();
            self.owner.write(new_owner);

            self.emit(Event::OwnershipTransferred(OwnershipTransferred {
                previous_owner,
                new_owner
            }));
        }
    }

    
}