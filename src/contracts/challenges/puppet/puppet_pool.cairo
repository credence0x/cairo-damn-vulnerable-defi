use starknet::ContractAddress;

#[starknet::interface]
trait IPuppetPool<TContractState> {
    fn borrow(ref self: TContractState, amount: u256, recipient: ContractAddress);
    fn calculate_deposit_required(ref self: TContractState, amount: u256) -> u256;
}


#[starknet::contract]
mod puppet_pool {
    use damnvulnerabledefi::contracts::dependencies::external::security::reentrancy_guard::{
        IReentrancyGuard, reentrancy_guard
    };
    use damnvulnerabledefi::contracts::dependencies::external::security::reentrancy_guard::reentrancy_guard::{
        ReentrancyGuard
    };
    use starknet::ContractAddress;
    use damnvulnerabledefi::contracts::dependencies::external::token::ERC20::{
        IERC20Dispatcher, IERC20DispatcherTrait
    };
    use damnvulnerabledefi::contracts::dependencies::external::uniswap_v1::uniswap_interfaces::{
        IUniswapExchangeStorage, IUniswapExchangeStorageDispatcher,
        IUniswapExchangeStorageDispatcherTrait,
    };


    #[storage]
    struct Storage {
        uniswap_pair: ContractAddress,
        token: IERC20Dispatcher,
        ether_token: IERC20Dispatcher,
        deposits: LegacyMap::<ContractAddress, u256>
    }


    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Borrowed: Borrowed
    }

    #[derive(Drop, starknet::Event)]
    struct Borrowed {
        account: ContractAddress,
        recipient: ContractAddress,
        deposit_required: u256,
        borrow_amount: u256
    }


    #[constructor]
    fn constructor(
        ref self: ContractState,
        uniswap_pair_address: ContractAddress,
        token_address: ContractAddress,
        ether_token_address: ContractAddress,
    ) {
        self.uniswap_pair.write(uniswap_pair_address);

        self.token.write(IERC20Dispatcher { contract_address: token_address });

        self.ether_token.write(IERC20Dispatcher { contract_address: ether_token_address });
    }


    impl PuppelPoolReentrancyGuard of IReentrancyGuard<ContractState> {
        fn start(ref self: ContractState) {
            let mut state = reentrancy_guard::unsafe_new_contract_state();
            ReentrancyGuard::start(ref state);
        }

        fn end(ref self: ContractState) {
            let mut state = reentrancy_guard::unsafe_new_contract_state();
            ReentrancyGuard::end(ref state);
        }
    }


    #[generate_trait]
    impl PuppetPoolConstant of PuppetPoolConstantTraits {
        fn DEPOSIT_FACTOR() -> u256 {
            2
        }

        fn ONE_WAD() -> u256 {
            1_000_000_000_000_000_000 // 1e18
        }
    }


    #[generate_trait]
    impl PuppetPoolPrivate of PuppetPoolPrivateTraits {
        fn compute_oracle_price(ref self: ContractState, ) -> u256 {
            let uniswap_pair = IUniswapExchangeStorageDispatcher {
                contract_address: self.uniswap_pair.read()
            };

            let token = self.token.read();

            ((uniswap_pair.ether_token_balance() * PuppetPoolConstant::ONE_WAD())
                / token.balance_of(uniswap_pair.contract_address))
        }

        #[inline(always)]
        fn send_ether(ref self: ContractState, to: ContractAddress, value: u256) {
            assert(self.ether_token.read().transfer(to, value), 'ETH_TRANSFER_FAILED');
        }


        #[inline(always)]
        fn receive_ether(ref self: ContractState, from: ContractAddress, value: u256) {
            let ether_token = self.ether_token.read();
            assert(
                ether_token.allowance(from, starknet::get_contract_address()) >= value,
                'INSUFFICIENT_ETHER_ALLOWANCE'
            );
            assert(
                ether_token.transfer_from(from, starknet::get_contract_address(), value),
                'ETH_TRANSFER_FROM_FAILED'
            );
        }
    }


    #[external(v0)]
    impl PuppetPool of super::IPuppetPool<ContractState> {
        fn borrow(
            ref self: ContractState,
            amount: u256, // token amount being borrowed
            recipient: ContractAddress
        ) {
            PuppelPoolReentrancyGuard::start(ref self);

            let deposit_required = PuppetPool::calculate_deposit_required(ref self, amount);

            let caller = starknet::get_caller_address();
            PuppetPoolPrivate::receive_ether(ref self, caller, deposit_required);

            self.deposits.write(caller, self.deposits.read(caller) + deposit_required);

            // Fails if the pool doesn't have enough tokens in liquidity
            assert(self.token.read().transfer(recipient, amount), 'TOKEN_TRANSFER_FAILED');

            self
                .emit(
                    Event::Borrowed(
                        Borrowed {
                            account: caller,
                            recipient: recipient,
                            deposit_required: deposit_required,
                            borrow_amount: amount
                        }
                    )
                );

            PuppelPoolReentrancyGuard::end(ref self);
        }


        fn calculate_deposit_required(ref self: ContractState, amount: u256) -> u256 {
            let oracle_price = PuppetPoolPrivate::compute_oracle_price(ref self);

            amount
                * oracle_price
                * PuppetPoolConstant::DEPOSIT_FACTOR()
                / PuppetPoolConstant::ONE_WAD()
        }
    }
}
