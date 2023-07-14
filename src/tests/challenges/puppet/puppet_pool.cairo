#[cfg(test)]
mod test_puppet_pool {
    use array::ArrayTrait;
    use option::OptionTrait;
    use result::ResultTrait;
    use integer::BoundedInt;
    use test::test_utils::{assert_eq, assert_ne, assert_ge};
    use traits::{TryInto, Into};
    use starknet::contract_address::ContractAddress;
    use starknet::syscalls::deploy_syscall;
    use damnvulnerabledefi::tests::utils::constants::DEPLOYER;
    use damnvulnerabledefi::tests::utils::helpers::{call_contracts_as, to_wad};
    use damnvulnerabledefi::contracts::dependencies::external::uniswap_v1::uniswap_exchange::uniswap_exchange;
    use damnvulnerabledefi::contracts::dependencies::external::uniswap_v1::uniswap_factory::uniswap_factory;
    use damnvulnerabledefi::contracts::dependencies::external::uniswap_v1::uniswap_interfaces::{
        IUniswapExchange, IUniswapExchangeDispatcher, IUniswapExchangeDispatcherTrait,
        IUniswapFactory, IUniswapFactoryDispatcher, IUniswapFactoryDispatcherTrait
    };
    use damnvulnerabledefi::contracts::dependencies::external::token::ERC20::{
        ERC20, IERC20Dispatcher, IERC20DispatcherTrait
    };
    use damnvulnerabledefi::contracts::challenges::puppet::puppet_pool::{
        IPuppetPoolDispatcher, IPuppetPoolDispatcherTrait
    };
    use damnvulnerabledefi::contracts::challenges::puppet::puppet_pool::{puppet_pool, };


    ////////////////////////////
    // Player contract
    ////////////////////////////

    #[starknet::interface]
    trait IPlayer<TContractState> {
        fn play(ref self: TContractState);
    }

    #[starknet::contract]
    mod player {
        use damnvulnerabledefi::contracts::dependencies::external::uniswap_v1::uniswap_interfaces::{
            IUniswapExchange, IUniswapExchangeDispatcher, IUniswapExchangeDispatcherTrait,
            IUniswapFactory, IUniswapFactoryDispatcher, IUniswapFactoryDispatcherTrait
        };
        use damnvulnerabledefi::contracts::challenges::puppet::puppet_pool::{
            IPuppetPoolDispatcher, IPuppetPoolDispatcherTrait
        };
        use damnvulnerabledefi::contracts::dependencies::external::token::ERC20::{
            ERC20, IERC20Dispatcher, IERC20DispatcherTrait
        };


        #[storage]
        struct Storage {
            uniswap_factory: IUniswapFactoryDispatcher,
            ether_token: IERC20Dispatcher,
            damn_valuable_token: IERC20Dispatcher,
            puppet_pool: IPuppetPoolDispatcher
        }

        #[constructor]
        fn constructor(
            ref self: ContractState,
            uniswap_factory: super::IUniswapFactoryDispatcher,
            ether_token: IERC20Dispatcher,
            damn_valuable_token: IERC20Dispatcher,
            puppet_pool: super::IPuppetPoolDispatcher,
        ) {
            self.uniswap_factory.write(uniswap_factory);
            self.ether_token.write(ether_token);
            self.damn_valuable_token.write(damn_valuable_token);
            self.puppet_pool.write(puppet_pool);
        }


        #[external(v0)]
        impl Player of super::IPlayer<ContractState> {
            fn play(ref self: ContractState) {//////////////////////////
            // YOUR EXPLOIT GOES HERE
            //////////////////////////

            // if you are using the exchange, REMEMBER to APPROVE
            // the ether token before trying to do a swap or transfer

            }
        }
    }


    #[test]
    #[available_gas(300000000)]
    fn exploit() {
        /// NO NEED TO CHANGE ANYTHING HERE 

        let (player, damn_valuable_token, puppet_pool) = __setup_play();

        player.play();

        let puppet_pool_balance = damn_valuable_token.balance_of(puppet_pool.contract_address);
        assert_eq(@puppet_pool_balance, @0, 'POOL_STILL_HAS_TOKENS');

        assert_ge(
            damn_valuable_token.balance_of(player.contract_address),
            POOL_INITIAL_TOKEN_BALANCE(),
            'NOT_ENOUGH_PLAYER_TOKEN_BALANCE'
        );
    }


    fn UNISWAP_INITIAL_ETH_RESERVE() -> u256 {
        to_wad(10)
    }

    fn UNISWAP_INITIAL_TOKEN_RESERVE() -> u256 {
        to_wad(10)
    }

    fn PLAYER_INITIAL_ETH_BALANCE() -> u256 {
        to_wad(25)
    }

    fn PLAYER_INITIAL_TOKEN_BALANCE() -> u256 {
        to_wad(1000)
    }

    fn POOL_INITIAL_TOKEN_BALANCE() -> u256 {
        to_wad(100_000)
    }


    fn __setup_play() -> (IPlayerDispatcher, IERC20Dispatcher, IPuppetPoolDispatcher) {
        ////////////////////////////////////
        // Deploy player contract
        ////////////////////////////////////
        let (uniswap_factory, ether_token, damn_valuable_token, puppet_pool) =
            __setup_with_initial_liquidity();
        let mut calldata = Default::default();
        Serde::<IUniswapFactoryDispatcher>::serialize(@uniswap_factory, ref calldata);
        Serde::<IERC20Dispatcher>::serialize(@ether_token, ref calldata);
        Serde::<IERC20Dispatcher>::serialize(@damn_valuable_token, ref calldata);
        Serde::<IPuppetPoolDispatcher>::serialize(@puppet_pool, ref calldata);

        let (player_address, _) = deploy_syscall(
            player::TEST_CLASS_HASH.try_into().unwrap(), 0, calldata.span(), false
        )
            .unwrap();
        let player = IPlayerDispatcher { contract_address: player_address };

        // fund player address with ETH and DVT
        call_contracts_as(DEPLOYER());
        ether_token.transfer(player.contract_address, PLAYER_INITIAL_ETH_BALANCE());
        damn_valuable_token.transfer(player.contract_address, PLAYER_INITIAL_TOKEN_BALANCE());

        (player, damn_valuable_token, puppet_pool)
    }


    fn __setup_with_initial_liquidity() -> (
        IUniswapFactoryDispatcher, IERC20Dispatcher, IERC20Dispatcher, IPuppetPoolDispatcher
    ) {
        let (uniswap_factory, ether_token, damn_valuable_token, puppet_pool) = __setup_exchange();

        // Add liquidity to DVT exchange

        let uniswap_dvt_exchange = IUniswapExchangeDispatcher {
            contract_address: uniswap_factory.get_exchange(damn_valuable_token.contract_address)
        };

        call_contracts_as(DEPLOYER());

        ether_token.approve(uniswap_dvt_exchange.contract_address, UNISWAP_INITIAL_ETH_RESERVE());
        damn_valuable_token
            .approve(uniswap_dvt_exchange.contract_address, UNISWAP_INITIAL_TOKEN_RESERVE());
        uniswap_dvt_exchange
            .add_liquidity(
                UNISWAP_INITIAL_ETH_RESERVE(),
                0, // immaterial when total Liquidity is 0
                UNISWAP_INITIAL_TOKEN_RESERVE(),
                12 // random block number
            );

        // Add initial liquidity to puppet pool 
        damn_valuable_token.transfer(puppet_pool.contract_address, POOL_INITIAL_TOKEN_BALANCE());

        (uniswap_factory, ether_token, damn_valuable_token, puppet_pool)
    }


    fn __setup_exchange() -> (
        IUniswapFactoryDispatcher, IERC20Dispatcher, IERC20Dispatcher, IPuppetPoolDispatcher
    ) {
        call_contracts_as(DEPLOYER());

        ////////////////////////////////////
        // Deploy Ether Token
        ////////////////////////////////////
        let name = 'Ether';
        let symbol = 'ETH';
        let initial_supply = BoundedInt::<u256>::max();
        let recipient = DEPLOYER();

        let mut calldata = Default::default();
        Serde::serialize(@name, ref calldata);
        Serde::serialize(@symbol, ref calldata);
        Serde::<u256>::serialize(@initial_supply, ref calldata);
        Serde::<ContractAddress>::serialize(@recipient, ref calldata);

        let (ether_token_address, _) = deploy_syscall(
            ERC20::TEST_CLASS_HASH.try_into().unwrap(),
            calldata.len().into(),
            calldata.span(),
            false
        )
            .unwrap();
        let ether_token = IERC20Dispatcher { contract_address: ether_token_address };

        ////////////////////////////////////
        // Deploy Damn Valuable Token
        ////////////////////////////////////
        let name = 'DamnValuableToken';
        let symbol = 'DVT';
        let initial_supply = BoundedInt::<u256>::max();
        let recipient = DEPLOYER();

        let mut calldata = Default::default();
        Serde::serialize(@name, ref calldata);
        Serde::serialize(@symbol, ref calldata);
        Serde::<u256>::serialize(@initial_supply, ref calldata);
        Serde::<ContractAddress>::serialize(@recipient, ref calldata);

        let (damn_valuable_token_address, _) = deploy_syscall(
            ERC20::TEST_CLASS_HASH.try_into().unwrap(),
            calldata.len().into(),
            calldata.span(),
            false
        )
            .unwrap();

        let damn_valuable_token = IERC20Dispatcher {
            contract_address: damn_valuable_token_address
        };

        ////////////////////////////////////
        // Deploy Uniswap Factory
        ////////////////////////////////////
        let calldata = Default::default();
        let (uniswap_factory_address, _) = deploy_syscall(
            uniswap_factory::TEST_CLASS_HASH.try_into().unwrap(),
            calldata.len().into(),
            calldata.span(),
            false
        )
            .unwrap();

        let uniswap_factory = IUniswapFactoryDispatcher {
            contract_address: uniswap_factory_address
        };
        uniswap_factory
            .initialize_factory(
                uniswap_exchange::TEST_CLASS_HASH.try_into().unwrap(), ether_token.contract_address
            );

        call_contracts_as(uniswap_factory_address);

        ////////////////////////////////////////
        // Create Damn Valuable Token Exchange
        ////////////////////////////////////////
        let uniswap_uniswap_dvt_exchange_address = uniswap_factory
            .create_exchange(damn_valuable_token.contract_address);

        ////////////////////////////////////////
        // Deploy Puppet Pool
        ////////////////////////////////////////
        let mut calldata = Default::default();
        Serde::<ContractAddress>::serialize(@uniswap_uniswap_dvt_exchange_address, ref calldata);
        Serde::<ContractAddress>::serialize(@damn_valuable_token.contract_address, ref calldata);
        Serde::<ContractAddress>::serialize(@ether_token.contract_address, ref calldata);

        let (puppet_pool_address, _) = deploy_syscall(
            puppet_pool::TEST_CLASS_HASH.try_into().unwrap(),
            calldata.len().into(),
            calldata.span(),
            false
        )
            .unwrap();

        let puppet_pool = IPuppetPoolDispatcher { contract_address: puppet_pool_address };

        (uniswap_factory, ether_token, damn_valuable_token, puppet_pool)
    }
}

