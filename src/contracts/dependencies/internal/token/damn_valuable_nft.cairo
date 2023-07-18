#[starknet::contract]
mod damn_valuable_nft {
    use damnvulnerabledefi::contracts::dependencies::external::token::erc721::IERC721::{
        IERC721, IERC721Receiver, IERC721ReceiverDispatcher, IERC721ReceiverDispatcherTrait,
        IERC721Burnable, IERC721BurnableDispatcher, IERC721BurnableDispatcherTrait
    };
    use damnvulnerabledefi::contracts::dependencies::external::token::erc721::ERC721::ERC721;
    use damnvulnerabledefi::contracts::dependencies::external::token::erc721::ERC721::ERC721::{
        ERC721Impl, ERC721Burnable
    };
    use starknet::ContractAddress;

    #[storage]
    struct Storage {}

    #[external(v0)]
    impl DamnValuableNFT of IERC721<ContractState> {
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
    impl DamnValuableNFTBurnable of IERC721Burnable<ContractState> {
        fn burn(ref self: ContractState, token_id: u256) {
            let mut state = ERC721::unsafe_new_contract_state();
            ERC721Burnable::burn(ref state, token_id)
        }
    }
}
