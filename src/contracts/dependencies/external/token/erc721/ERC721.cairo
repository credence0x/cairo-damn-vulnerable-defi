#[starknet::contract]
mod ERC721 {
    use array::SpanTrait;
    use option::OptionTrait;
    use starknet::ContractAddress;
    use starknet::get_caller_address;
    use zeroable::Zeroable;
    use damnvulnerabledefi::contracts::dependencies::external::token::erc721::IERC721::{
        IERC721, IERC721Receiver, IERC721ReceiverDispatcher, IERC721ReceiverDispatcherTrait,
        IERC721Burnable, IERC721BurnableDispatcher, IERC721BurnableDispatcherTrait
    };
    use damnvulnerabledefi::contracts::dependencies::external::utils::IERC165::{
        IERC165_ID, IERC165, IERC165Dispatcher, IERC165DispatcherTrait
    };


    const IERC721_ID: felt252 = 0x33eb2f84c309543403fd69f0d0f363781ef06ef6faeb0131ff16ea3175bd943;
    const IERC721_METADATA_ID: felt252 =
        0x6069a70848f907fa57668ba1875164eb4dcee693952468581406d131081bbd;
    const IERC721_RECEIVER_ID: felt252 =
        0x3a0dff5f70d80458ad14ae37bb182a728e3c8cdda0402a5daa86620bdf910bc;

    #[storage]
    struct Storage {
        name: felt252,
        symbol: felt252,
        owners: LegacyMap<u256, ContractAddress>,
        balances: LegacyMap<ContractAddress, u256>,
        token_approvals: LegacyMap<u256, ContractAddress>,
        operator_approvals: LegacyMap<(ContractAddress, ContractAddress), bool>,
        token_uri: LegacyMap<u256, felt252>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Transfer: Transfer,
        Approval: Approval,
        ApprovalForAll: ApprovalForAll
    }

    #[derive(Drop, starknet::Event)]
    struct Transfer {
        from: ContractAddress,
        to: ContractAddress,
        token_id: u256
    }

    #[derive(Drop, starknet::Event)]
    struct Approval {
        owner: ContractAddress,
        approved: ContractAddress,
        token_id: u256
    }

    #[derive(Drop, starknet::Event)]
    struct ApprovalForAll {
        owner: ContractAddress,
        operator: ContractAddress,
        approved: bool
    }


    #[constructor]
    fn constructor(ref self: ContractState, name: felt252, symbol: felt252) {
        InternalERC721Impl::initializer(ref self, name, symbol);
    }

    #[external(v0)]
    impl ERC165 of IERC165<ContractState> {
        fn supports_interface(self: @ContractState, interface_id: felt252) -> bool {
            (interface_id == IERC721_ID)
                || (interface_id == IERC721_METADATA_ID)
                || (interface_id == IERC165_ID)
        }
    }


    #[external(v0)]
    impl ERC721Impl of IERC721<ContractState> {
        fn name(self: @ContractState) -> felt252 {
            self.name.read()
        }

        fn symbol(self: @ContractState) -> felt252 {
            self.symbol.read()
        }

        fn token_uri(self: @ContractState, token_id: u256) -> felt252 {
            assert(InternalERC721Impl::exists(self, token_id), 'ERC721: invalid token ID');

            self.token_uri.read(token_id)
        }

        fn balance_of(self: @ContractState, account: ContractAddress) -> u256 {
            assert(account.is_non_zero(), 'ERC721: invalid account');

            self.balances.read(account)
        }

        fn owner_of(self: @ContractState, token_id: u256) -> ContractAddress {
            InternalERC721Impl::_owner_of(self, token_id)
        }

        fn get_approved(self: @ContractState, token_id: u256) -> ContractAddress {
            assert(InternalERC721Impl::exists(self, token_id), 'ERC721: invalid token ID');
            self.token_approvals.read(token_id)
        }

        fn is_approved_for_all(
            self: @ContractState, owner: ContractAddress, operator: ContractAddress
        ) -> bool {
            self.operator_approvals.read((owner, operator))
        }

        fn approve(ref self: ContractState, to: ContractAddress, token_id: u256) {
            let owner = InternalERC721Impl::_owner_of(@self, token_id);

            let caller = get_caller_address();
            assert(
                owner == caller || self.is_approved_for_all(owner, caller),
                'ERC721: unauthorized caller'
            );
            InternalERC721Impl::_approve(ref self, to, token_id);
        }

        fn set_approval_for_all(
            ref self: ContractState, operator: ContractAddress, approved: bool
        ) {
            InternalERC721Impl::_set_approval_for_all(
                ref self, get_caller_address(), operator, approved
            )
        }

        fn transfer_from(
            ref self: ContractState, from: ContractAddress, to: ContractAddress, token_id: u256
        ) {
            assert(
                InternalERC721Impl::_is_approved_or_owner(@self, get_caller_address(), token_id),
                'ERC721: unauthorized caller'
            );
            InternalERC721Impl::_transfer(ref self, from, to, token_id);
        }

        fn safe_transfer_from(
            ref self: ContractState,
            from: ContractAddress,
            to: ContractAddress,
            token_id: u256,
            data: Span<felt252>
        ) {
            assert(
                InternalERC721Impl::_is_approved_or_owner(@self, get_caller_address(), token_id),
                'ERC721: unauthorized caller'
            );
            InternalERC721Impl::_safe_transfer(ref self, from, to, token_id, data);
        }
    }


    #[generate_trait]
    impl InternalERC721Impl of InternalERC721Traits {
        fn initializer(ref self: ContractState, name_: felt252, symbol_: felt252) {
            self.name.write(name_);
            self.symbol.write(symbol_);
        }

        fn _owner_of(self: @ContractState, token_id: u256) -> ContractAddress {
            let owner = self.owners.read(token_id);
            match owner.is_zero() {
                bool::False(()) => owner,
                bool::True(()) => panic_with_felt252('ERC721: invalid token ID')
            }
        }

        fn exists(self: @ContractState, token_id: u256) -> bool {
            self.owners.read(token_id).is_non_zero()
        }

        fn _is_approved_or_owner(
            self: @ContractState, spender: ContractAddress, token_id: u256
        ) -> bool {
            let owner = InternalERC721Impl::_owner_of(self, token_id);
            owner == spender
                || self.is_approved_for_all(owner, spender)
                || spender == self.get_approved(token_id)
        }

        fn _approve(ref self: ContractState, to: ContractAddress, token_id: u256) {
            let owner = InternalERC721Impl::_owner_of(@self, token_id);
            assert(owner != to, 'ERC721: approval to owner');
            self.token_approvals.write(token_id, to);
            self.emit(Event::Approval(Approval { owner: owner, approved: to, token_id: token_id }))
        }

        fn _set_approval_for_all(
            ref self: ContractState,
            owner: ContractAddress,
            operator: ContractAddress,
            approved: bool
        ) {
            assert(owner != operator, 'ERC721: self approval');
            self.operator_approvals.write((owner, operator), approved);
            self
                .emit(
                    Event::ApprovalForAll(
                        ApprovalForAll { owner: owner, operator: operator, approved: approved }
                    )
                )
        }

        fn _mint(ref self: ContractState, to: ContractAddress, token_id: u256) {
            assert(to.is_non_zero(), 'ERC721: invalid receiver');
            assert(!InternalERC721Impl::exists(@self, token_id), 'ERC721: token already minted');

            // Update balances
            self.balances.write(to, self.balances.read(to) + 1);

            // Update token_id owner
            self.owners.write(token_id, to);

            // Emit event
            self
                .emit(
                    Event::Transfer(Transfer { from: Zeroable::zero(), to: to, token_id: token_id })
                )
        }

        fn _transfer(
            ref self: ContractState, from: ContractAddress, to: ContractAddress, token_id: u256
        ) {
            assert(to.is_non_zero(), 'ERC721: invalid receiver');
            let owner = InternalERC721Impl::_owner_of(@self, token_id);
            assert(from == owner, 'ERC721: wrong sender');

            // Implicit clear approvals, no need to emit an event
            self.token_approvals.write(token_id, Zeroable::zero());

            // Update balances
            self.balances.write(from, self.balances.read(from) - 1);
            self.balances.write(to, self.balances.read(to) + 1);

            // Update token_id owner
            self.owners.write(token_id, to);

            // Emit event
            self.emit(Event::Transfer(Transfer { from: from, to: to, token_id: token_id }))
        }

        fn _burn(ref self: ContractState, token_id: u256) {
            let owner = InternalERC721Impl::_owner_of(@self, token_id);

            // Implicit clear approvals, no need to emit an event
            self.token_approvals.write(token_id, Zeroable::zero());

            // Update balances
            self.balances.write(owner, self.balances.read(owner) - 1);

            // Delete owner
            self.owners.write(token_id, Zeroable::zero());

            // Emit event
            self
                .emit(
                    Event::Transfer(
                        Transfer { from: owner, to: Zeroable::zero(), token_id: token_id }
                    )
                )
        }

        fn _safe_mint(
            ref self: ContractState, to: ContractAddress, token_id: u256, data: Span<felt252>
        ) {
            InternalERC721Impl::_mint(ref self, to, token_id);
            assert(
                InternalERC721Impl::_check_on_erc721_received(Zeroable::zero(), to, token_id, data),
                'ERC721: safe mint failed'
            );
        }

        fn _safe_transfer(
            ref self: ContractState,
            from: ContractAddress,
            to: ContractAddress,
            token_id: u256,
            data: Span<felt252>
        ) {
            InternalERC721Impl::_transfer(ref self, from, to, token_id);
            assert(
                InternalERC721Impl::_check_on_erc721_received(from, to, token_id, data),
                'ERC721: safe transfer failed'
            );
        }

        fn _set_token_uri(ref self: ContractState, token_id: u256, token_uri: felt252) {
            assert(InternalERC721Impl::exists(@self, token_id), 'ERC721: invalid token ID');
            self.token_uri.write(token_id, token_uri)
        }

        fn _check_on_erc721_received(
            from: ContractAddress, to: ContractAddress, token_id: u256, data: Span<felt252>
        ) -> bool {
            IERC721ReceiverDispatcher {
                contract_address: to
            }.on_erc721_received(get_caller_address(), from, token_id, data) == IERC721_RECEIVER_ID
        }
    }


    impl ERC721BurnableImpl of IERC721Burnable<ContractState> {
        fn burn(ref self: ContractState, token_id: u256) {
            assert(
                InternalERC721Impl::_is_approved_or_owner(@self, get_caller_address(), token_id),
                'ERC721: insufficient approval'
            );
            InternalERC721Impl::_burn(ref self, token_id);
        }
    } 
}
