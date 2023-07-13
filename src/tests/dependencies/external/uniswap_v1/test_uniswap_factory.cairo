#[cfg(test)]
mod test_uniswap_factory {

    use array::ArrayTrait;
    use option::OptionTrait;
    use result::ResultTrait;
    use integer::BoundedInt;
    use test::test_utils::{assert_eq,assert_ne};
    use traits::{TryInto,Into};
    use starknet::contract_address::ContractAddress;
    use starknet::syscalls::deploy_syscall;
    use damnvulnerabledefi::tests::utils::constants::DEPLOYER;
    use damnvulnerabledefi::tests::utils::helpers::call_contracts_as;
    use damnvulnerabledefi::contracts::dependencies::external::uniswap_v1::uniswap_exchange::uniswap_exchange;
    use damnvulnerabledefi::contracts::dependencies::external::uniswap_v1::uniswap_factory::uniswap_factory;
    use damnvulnerabledefi::contracts::dependencies::external::uniswap_v1::uniswap_interfaces::{
        IUniswapExchange, IUniswapExchangeDispatcher, IUniswapExchangeDispatcherTrait,
        IUniswapFactory, IUniswapFactoryDispatcher, IUniswapFactoryDispatcherTrait
    };
    use damnvulnerabledefi::contracts::dependencies::external::token::ERC20::{
        ERC20, IERC20Dispatcher, IERC20DispatcherTrait
    };

    

    #[test]
    #[available_gas(30000000)]
    fn get_exchange() {

        let (
            uniswap_factory, 
            uniswap_exchange,
            _,
            damn_valuable_token
        ) = __setup_factory();

        let exchange_address = uniswap_factory.get_exchange(
            damn_valuable_token.contract_address
        );

        assert_ne(
            @exchange_address.into(), 
            @0,
            'Exchange address cant be zero'
        );

        assert_eq(
            @exchange_address, 
            @uniswap_exchange.contract_address,
            'Exchange address is not correct'
        );
     
    }

    #[test]
    #[available_gas(30000000)]
    fn get_token() {
            
        let (
            uniswap_factory, 
            uniswap_exchange,
            _,
            damn_valuable_token
        ) = __setup_factory();

        let token_address = uniswap_factory.get_token(
            uniswap_exchange.contract_address
        );

        assert_ne(
            @token_address.into(), 
            @0,
            'Token address cant be zero'
        );

        assert_eq(
            @token_address, 
            @damn_valuable_token.contract_address,
            'Token address is not correct'
        );
        
    }


    #[test]
    #[available_gas(30000000)]
    fn get_token_with_id() {
        let (
            uniswap_factory, 
            uniswap_exchange,
            _,
            damn_valuable_token
        ) = __setup_factory();

        let token_address = uniswap_factory.get_token_with_id(1);

        assert_ne(
            @token_address.into(), 
            @0,
            'Token address cant be zero'
        );

        assert_eq(
            @token_address, 
            @damn_valuable_token.contract_address,
            'Token address is not correct'
        );
    }


    ///////////////////////
    // Panic tests
    ///////////////////////

    #[test]
    #[should_panic(expected: ('ALREADY_INITIALIZED','ENTRYPOINT_FAILED' ))]
    #[available_gas(30000000)]
    fn panic_initialize_factory() {
        let (
            uniswap_factory, 
            _,
            ether_token,
            _
        ) = __setup_factory();

        uniswap_factory.initialize_factory(
            uniswap_exchange::TEST_CLASS_HASH.try_into().unwrap(),
            ether_token.contract_address
        );
    }



    #[test]
    #[should_panic(expected: ('EXCHANGE_ALREADY_CREATED','ENTRYPOINT_FAILED' ))]
    #[available_gas(30000000)]
    fn panic_create_exchange() {
        let (
            uniswap_factory, 
            _,
            _,
            damn_valuable_token
        ) = __setup_factory();

        uniswap_factory.create_exchange(
            damn_valuable_token.contract_address
        );
    }



    
    fn __setup_factory() -> (
        IUniswapFactoryDispatcher, 
        IUniswapExchangeDispatcher,
        IERC20Dispatcher,
        IERC20Dispatcher
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
            ).unwrap();
            let ether_token = IERC20Dispatcher{ 
                contract_address: ether_token_address
            };


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
            ).unwrap();

            let damn_valuable_token = IERC20Dispatcher{ 
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
            ).unwrap();

            let uniswap_factory = IUniswapFactoryDispatcher{
                contract_address: uniswap_factory_address
            };
            uniswap_factory.initialize_factory(
                uniswap_exchange::TEST_CLASS_HASH.try_into().unwrap(),
                ether_token.contract_address
            );


            ////////////////////////////////////
            // Create Exchange
            ////////////////////////////////////
            call_contracts_as(uniswap_factory_address);
            let uniswap_exchange_address = uniswap_factory.create_exchange(
                damn_valuable_token.contract_address
            );
            let uniswap_exchange = IUniswapExchangeDispatcher{
                contract_address: uniswap_exchange_address
            };

            (
                uniswap_factory,
                uniswap_exchange,
                ether_token,
                damn_valuable_token
            )
            

        }        

}

