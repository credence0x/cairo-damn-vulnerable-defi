use starknet::ContractAddress;

#[starknet::interface]
trait IERC721SafeMint<TContractState> {
    fn safe_mint(ref self: TContractState, to: ContractAddress) -> u256;
}


#[starknet::contract]
mod damn_valuable_nft {
    use damnvulnerabledefi::contracts::dependencies::external::token::erc721::IERC721::{
        IERC721, IERC721Receiver, IERC721ReceiverDispatcher, IERC721ReceiverDispatcherTrait,
        IERC721Burnable, IERC721BurnableDispatcher, IERC721BurnableDispatcherTrait
    };
    use damnvulnerabledefi::contracts::dependencies::external::access::ownable::{
        IOwnable, ownable, 
        ownable::OwnableImpl, ownable::InternalOwnableImpl
    };
    use damnvulnerabledefi::contracts::dependencies::external::access::access_control::{
        IAccessControl, access_control, 
        access_control::AccessControlImpl, access_control::InternalAccessControlImpl
    };
    use damnvulnerabledefi::contracts::dependencies::external::token::erc721::ERC721::ERC721;
    use damnvulnerabledefi::contracts::dependencies::external::token::erc721::ERC721::ERC721::{
        ERC721Impl, ERC721BurnableImpl, InternalERC721Impl
    };
    use starknet::ContractAddress;
    use array::{ArrayTrait, SpanTrait};



    const MINTER_ROLE: felt252 = 'MINTER_ROLE';

    #[storage]
    struct Storage {
        token_id_counter: u256
    }

    #[constructor]
    fn constructor(ref self: ContractState){
        let mut erc721_state = ERC721::unsafe_new_contract_state();
        InternalERC721Impl::initializer(ref erc721_state, 'DamnValuableNFT', 'DVNFT');

        let caller = starknet::get_caller_address();

        let mut ownable_state = ownable::unsafe_new_contract_state();
        InternalOwnableImpl::initializer(ref ownable_state, caller);

        let mut access_control_state = access_control::unsafe_new_contract_state();
        InternalAccessControlImpl::_grant_role(
            ref access_control_state,
            MINTER_ROLE, 
            caller
        );

    }



    #[external(v0)]
    impl DamnValuableNFTImpl of IERC721<ContractState> {
        fn name(self: @ContractState) -> felt252 {
            let state = ERC721::unsafe_new_contract_state();
            ERC721Impl::name(@state)
        }


        fn symbol(self: @ContractState) -> felt252 {
            let state = ERC721::unsafe_new_contract_state();
            ERC721Impl::symbol(@state)
        }

        fn token_uri(self: @ContractState, token_id: u256) -> felt252 {
            let state = ERC721::unsafe_new_contract_state();
            ERC721Impl::token_uri(@state, token_id)
        }

        fn balance_of(self: @ContractState, account: ContractAddress) -> u256 {
            let state = ERC721::unsafe_new_contract_state();
            ERC721Impl::balance_of(@state, account)
        }

        fn owner_of(self: @ContractState, token_id: u256) -> ContractAddress {
            let state = ERC721::unsafe_new_contract_state();
            ERC721Impl::owner_of(@state, token_id)
        }


        fn get_approved(self: @ContractState, token_id: u256) -> ContractAddress {
            let state = ERC721::unsafe_new_contract_state();
            ERC721Impl::get_approved(@state, token_id)
        }

        fn is_approved_for_all(
            self: @ContractState, owner: ContractAddress, operator: ContractAddress
        ) -> bool {
            let state = ERC721::unsafe_new_contract_state();
            ERC721Impl::is_approved_for_all(@state, owner, operator)
        }

        fn approve(ref self: ContractState, to: ContractAddress, token_id: u256) {
            let mut state = ERC721::unsafe_new_contract_state();
            ERC721Impl::approve(ref state, to, token_id)
        }

        fn set_approval_for_all(
            ref self: ContractState, operator: ContractAddress, approved: bool
        ) {
            let mut state = ERC721::unsafe_new_contract_state();
            ERC721Impl::set_approval_for_all(ref state, operator, approved)
        }

        fn transfer_from(
            ref self: ContractState, from: ContractAddress, to: ContractAddress, token_id: u256
        ) {
            let mut state = ERC721::unsafe_new_contract_state();
            ERC721Impl::transfer_from(ref state, from, to, token_id)
        }

        fn safe_transfer_from(
            ref self: ContractState,
            from: ContractAddress,
            to: ContractAddress,
            token_id: u256,
            data: Span<felt252>
        ) {
            let mut state = ERC721::unsafe_new_contract_state();
            ERC721Impl::safe_transfer_from(ref state, from, to, token_id, data)
        }
    }


    #[external(v0)]
    impl DamnValuableNFTBurnableImpl of IERC721Burnable<ContractState> {
        fn burn(ref self: ContractState, token_id: u256) {
            let mut state = ERC721::unsafe_new_contract_state();
            ERC721BurnableImpl::burn(ref state, token_id)
        }
    }

    #[external(v0)]
    impl DamnValuableNFTSafeMint of super::IERC721SafeMint<ContractState> {

        fn safe_mint(ref self: ContractState, to: ContractAddress) -> u256 {

            assert(DamnValuableNFTAccessControlImpl::has_role(
                    @self, 
                    MINTER_ROLE, 
                    starknet::get_caller_address()
                ),'NOT_MINTER'
            );

            let token_id = self.token_id_counter.read();

            let mut erc721_state = ERC721::unsafe_new_contract_state();
            InternalERC721Impl::_safe_mint(
                ref erc721_state, 
                to, 
                token_id, 
                ArrayTrait::new().span()
            );

            self.token_id_counter.write(token_id + 1);

            token_id
        }
    }


    #[external(v0)]
    impl DamnValuableNFTOwnableImpl of IOwnable<ContractState> {
        fn owner(self: @ContractState) -> ContractAddress {
            let state = ownable::unsafe_new_contract_state();
            OwnableImpl::owner(@state)
        }

        fn transfer_ownership(ref self: ContractState, new_owner: ContractAddress) {
            let mut state = ownable::unsafe_new_contract_state();
            OwnableImpl::transfer_ownership(ref state, new_owner)
        }

        fn renounce_ownership(ref self: ContractState) {
            let mut state = ownable::unsafe_new_contract_state();
            OwnableImpl::renounce_ownership(ref state)
        }
    }


    #[external(v0)]
    impl DamnValuableNFTAccessControlImpl of IAccessControl<ContractState> {
        fn has_role(self: @ContractState, role: felt252, account: ContractAddress) -> bool {
            let state = access_control::unsafe_new_contract_state();
            AccessControlImpl::has_role(@state, role, account)
        }

        fn get_role_admin(self: @ContractState, role: felt252) -> felt252 {
            let state = access_control::unsafe_new_contract_state();
            AccessControlImpl::get_role_admin(@state, role)
        }

        fn grant_role(ref self: ContractState, role: felt252, account: ContractAddress) {
            let mut state = access_control::unsafe_new_contract_state();
            AccessControlImpl::grant_role(ref state, role, account)
        }

        fn revoke_role(ref self: ContractState, role: felt252, account: ContractAddress) {
            let mut state = access_control::unsafe_new_contract_state();
            AccessControlImpl::revoke_role(ref state, role, account)
        }

        fn renounce_role(ref self: ContractState, role: felt252, account: ContractAddress) {
            let mut state = access_control::unsafe_new_contract_state();
            AccessControlImpl::renounce_role(ref state, role, account)
        }
    }
}
