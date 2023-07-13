#[cfg(test)]
mod test_dvt_exchange {

    use array::ArrayTrait;
    use option::OptionTrait;
    use result::ResultTrait;
    use integer::BoundedInt;
    use test::test_utils::{ assert_eq, assert_ne };
    use traits::{TryInto,Into};
    use starknet::contract_address::ContractAddress;
    use starknet::syscalls::deploy_syscall;
    use damnvulnerabledefi::tests::utils::constants::{
        DEPLOYER, RECEIVER
    };
    use damnvulnerabledefi::tests::utils::helpers::{
        call_contracts_as,
        to_wad
    };
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
    #[available_gas(3000000)]
    fn test_factory_address(){

        let (
            uniswap_factory, 
            ether_token,
            damn_valuable_token,
            other_side_token
        ) = __setup_exchange();

        let dvt_exchange = IUniswapExchangeDispatcher{
            contract_address: uniswap_factory.get_exchange(
                damn_valuable_token.contract_address
            )
        };
        assert_eq(
            @dvt_exchange.factory_address(), 
            @uniswap_factory.contract_address,
            'WRONG_FACTORY_ADDRESS'
        );
    }



    #[test]
    #[available_gas(3000000)]
    fn test_token_address(){

        let (
            uniswap_factory, 
            ether_token,
            damn_valuable_token,
            other_side_token
        ) = __setup_exchange();

        let dvt_exchange = IUniswapExchangeDispatcher{
            contract_address: uniswap_factory.get_exchange(
                damn_valuable_token.contract_address
            )
        };

        assert_eq(
            @dvt_exchange.token_address(), 
            @damn_valuable_token.contract_address,
            'WRONG_TOKEN_ADDRESS'
        );
    }


    #[test]
    #[available_gas(3000000)]
    fn test_name_symbol_decimal(){
            
            let (
                uniswap_factory, 
                ether_token,
                damn_valuable_token,
                other_side_token
            ) = __setup_exchange();
    
            let dvt_exchange = IERC20Dispatcher{
                contract_address: uniswap_factory.get_exchange(
                    damn_valuable_token.contract_address
                )
            };
    
            assert_eq(
                @dvt_exchange.name(), 
                @'Uniswap V1',
                'WRONG_NAME'
            );
    
            assert_eq(
                @dvt_exchange.symbol(), 
                @'UNI-V1',
                'WRONG_SYMBOL'
            );
    
            assert_eq(
                @dvt_exchange.decimals(), 
                @damn_valuable_token.decimals(),
                'WRONG_DECIMALS'
            );
    }


    #[test]
    #[available_gas(30000000)]
    fn test_add_liquidity() {

        let (
            uniswap_factory, 
            ether_token,
            damn_valuable_token,
            _
        ) = __setup_exchange();

        let eth_amount = to_wad(200);
        let max_tokens = to_wad(1_000);
        
        let dvt_exchange = IUniswapExchangeDispatcher{
            contract_address: uniswap_factory.get_exchange(
                damn_valuable_token.contract_address
            )
        };

        call_contracts_as(DEPLOYER());
        
        ether_token.approve(
            dvt_exchange.contract_address,
            eth_amount
        );
        damn_valuable_token.approve(
            dvt_exchange.contract_address,
            max_tokens
        );
        let DVT_UNI = dvt_exchange.add_liquidity(
            eth_amount,
            to_wad(0), // immaterial when total Liquidity is 0
            max_tokens,
            12
        );


        assert_eq(
            @DVT_UNI, 
            @to_wad(200), // 200 DVT_UNI
            'WRONG DVT_UNI AMOUNT'
        );

    
        let eth_amount = to_wad(3);
        let max_tokens = to_wad(15) + 1;
        ether_token.approve(
            dvt_exchange.contract_address,
            eth_amount
        );

        damn_valuable_token.approve(
            dvt_exchange.contract_address,
            max_tokens
        );

        let DVT_UNI = dvt_exchange.add_liquidity(
            eth_amount,
            to_wad(1), // immaterial when total liquidity is 0
            max_tokens,
            1
        );


        assert_eq(
            @DVT_UNI, 
            @to_wad(3), // 3 DVT_UNI
            'WRONG DVT_UNI AMOUNT'
        );


        let eth_amount = to_wad(12);
        let max_tokens = to_wad(60) + 1;
        ether_token.approve(
            dvt_exchange.contract_address,
            eth_amount
        );

        damn_valuable_token.approve(
            dvt_exchange.contract_address,
            max_tokens
        );

        let DVT_UNI = dvt_exchange.add_liquidity(
            eth_amount,
            to_wad(1), // immaterial when total liquidity is 0
            max_tokens,
            1
        );


        assert_eq(
            @DVT_UNI, 
            @to_wad(12), // 12 DVT_UNI
            'WRONG DVT_UNI AMOUNT'
        );

    }


    #[test]
    #[available_gas(30000000)]
    fn test_get_eth_to_token_input_price() {

        let (
            uniswap_factory, 
            _,
            damn_valuable_token,
            _
        ) = __setup_with_initial_liquidity();

        let dvt_exchange = IUniswapExchangeDispatcher{
            contract_address: uniswap_factory.get_exchange(
                damn_valuable_token.contract_address
            )
        };

        let eth_sold = to_wad(1);
        let tokens_bought = dvt_exchange.get_eth_to_token_input_price(eth_sold); 
        assert_eq(
            @tokens_bought, 
            @4_961_990_212_827_030_005, // 4.961990212827030005 DVT
            'WRONG_TOKENS_BOUGHT_VALUE'
        );

        let eth_sold = to_wad(200);
        let tokens_bought = dvt_exchange.get_eth_to_token_input_price(eth_sold);
        assert_eq(
            @tokens_bought, 
            @517_265_926_640_926_640_927, // 517.265926640926640927 DVT
            'WRONG_TOKENS_BOUGHT_VALUE'
        );

    }


    #[test]
    #[available_gas(30000000)]
    fn test_get_eth_to_token_output_price() {

        let (
            uniswap_factory, 
            _,
            damn_valuable_token,
            _
        ) = __setup_with_initial_liquidity();

        let dvt_exchange = IUniswapExchangeDispatcher{
            contract_address: uniswap_factory.get_exchange(
                damn_valuable_token.contract_address
            )
        };

        let tokens_bought = to_wad(1);
        let eth_to_be_sold = dvt_exchange.get_eth_to_token_output_price(tokens_bought); 
        
        assert_eq(
            @eth_to_be_sold, 
            @200_788_585_495_779_705, // 0.200788585495779705 ETH
            'WRONG_ETH_SOLD_VALUE'
        );

        let tokens_bought = to_wad(1000);
        let eth_to_be_sold = dvt_exchange.get_eth_to_token_output_price(tokens_bought);
        assert_eq(
            @eth_to_be_sold, 
            @2_875_292_544_299_565_362_679, // 2875.292544299565362679 ETH
            'WRONG_ETH_SOLD_VALUE'
        );
    }


    #[test]
    #[available_gas(30000000)]
    fn test_get_token_to_eth_input_price() {

        let (
            uniswap_factory, 
            _,
            damn_valuable_token,
            _
        ) = __setup_with_initial_liquidity();

        let dvt_exchange = IUniswapExchangeDispatcher{
            contract_address: uniswap_factory.get_exchange(
                damn_valuable_token.contract_address
            )
        };

        let tokens_sold = to_wad(1);
        let eth_bought = dvt_exchange.get_token_to_eth_input_price(tokens_sold); 
        assert_eq(
            @eth_bought, 
            @199_215_239_447_693_627, // 0.199215239447693627 ETH
            'WRONG_TOKENS_BOUGHT_VALUE'
        );

        let tokens_sold = to_wad(200);
        let eth_bought = dvt_exchange.get_token_to_eth_input_price(tokens_sold);

        assert_eq(
            @eth_bought, 
            @33_640_144_381_669_805_398, // 33.640144381669805398 ETH
            'WRONG_TOKENS_BOUGHT_VALUE'
        );
    }


    #[test]
    #[available_gas(30000000)]
    fn test_get_token_to_eth_output_price() {

        let (
            uniswap_factory, 
            _,
            damn_valuable_token,
            _
        ) = __setup_with_initial_liquidity();

        let dvt_exchange = IUniswapExchangeDispatcher{
            contract_address: uniswap_factory.get_exchange(
                damn_valuable_token.contract_address
            )
        };
        let eth_bought = to_wad(1);
        let tokens_to_be_sold = dvt_exchange.get_token_to_eth_output_price(eth_bought);
        
        assert_eq(
            @tokens_to_be_sold, 
            @5_038_479_925_758_584_164, // 5.038479925758584164 DVT
            'WRONG_TOKENS_SOLD_VALUE'
        );
        

        let eth_bought = to_wad(200);
        let tokens_to_be_sold = dvt_exchange.get_token_to_eth_output_price(eth_bought);

        assert_eq(
            @tokens_to_be_sold, 
            @14_376_462_721_497_826_813_802, // 14,376.462721497826813802 DVT
            'WRONG_TOKENS_SOLD_VALUE'
        );
    }


    #[test]
    #[available_gas(30000000)]
    fn test_eth_to_token_swap_input(){
            
 

            let (
                uniswap_factory, 
                ether_token,
                damn_valuable_token,
                _
            ) = __setup_with_initial_liquidity();

            let dvt_exchange = IUniswapExchangeDispatcher{
                contract_address: uniswap_factory.get_exchange(
                    damn_valuable_token.contract_address
                )
            };

            call_contracts_as(DEPLOYER());

            let before_deployer_token_balance = damn_valuable_token.balance_of(DEPLOYER());
    
            let eth_sold = to_wad(1);
            let min_tokens = to_wad(1);
            let deadline = 1_000;

            ether_token.approve(
                dvt_exchange.contract_address,
                eth_sold
            );
            let tokens_bought = dvt_exchange.eth_to_token_swap_input(
                eth_sold,
                min_tokens,
                deadline
            );
    
            assert_eq(
                @tokens_bought, 
                @4_961_990_212_827_030_005, // 4.961990212827030005 DVT
                'WRONG_TOKENS_BOUGHT_VALUE'
            );
    
    
            assert_eq(
                @damn_valuable_token.balance_of(DEPLOYER()), 
                @(before_deployer_token_balance + tokens_bought),
                'WRONG DVT TOKEN BALANCE'
            );
    
    }



    #[test]
    #[available_gas(30000000)]
    fn test_eth_to_token_transfer_input(){


            let (
                uniswap_factory, 
                ether_token,
                damn_valuable_token,
                _
            ) = __setup_with_initial_liquidity();

            let dvt_exchange = IUniswapExchangeDispatcher{
                contract_address: uniswap_factory.get_exchange(
                    damn_valuable_token.contract_address
                )
            };

            call_contracts_as(DEPLOYER());

            let before_receiver_token_balance = damn_valuable_token.balance_of(RECEIVER());

            let eth_sold = to_wad(1);
            let min_tokens = to_wad(1);
            let deadline = 1_000;

            ether_token.approve(
                dvt_exchange.contract_address,
                eth_sold
            );
            let tokens_bought = dvt_exchange.eth_to_token_transfer_input(
                eth_sold,
                min_tokens,
                deadline,
                RECEIVER()
            );

            assert_eq(
                @tokens_bought, 
                @4_961_990_212_827_030_005, // 4.961990212827030005 DVT
                'WRONG_TOKENS_BOUGHT_VALUE'
            );

            assert_eq(
                @damn_valuable_token.balance_of(RECEIVER()), 
                @(before_receiver_token_balance + tokens_bought),
                'WRONG_DVT_TOKEN_BALANCE'
            );
        
    }


    #[test]
    #[available_gas(30000000)]
    fn test_eth_to_token_swap_output() {

 
            let (
                uniswap_factory, 
                ether_token,
                damn_valuable_token,
                _
            ) = __setup_with_initial_liquidity();

            let dvt_exchange = IUniswapExchangeDispatcher{
                contract_address: uniswap_factory.get_exchange(
                    damn_valuable_token.contract_address
                )
            };

            call_contracts_as(DEPLOYER());

            let before_deployer_token_balance = damn_valuable_token.balance_of(DEPLOYER());

            let tokens_bought = to_wad(1);
            let max_eth = 200_788_585_495_779_705;  // 0.200788585495779705 ETH
            let deadline = 1_000;

            ether_token.approve(
                dvt_exchange.contract_address,
                max_eth
            );
            let eth_sold = dvt_exchange.eth_to_token_swap_output(
                max_eth,
                tokens_bought,
                deadline
            );

            assert_eq(
                @eth_sold, 
                @max_eth,
                'WRONG_ETH_SOLD_VALUE'
            );

            assert_eq(
                @damn_valuable_token.balance_of(DEPLOYER()), 
                @(before_deployer_token_balance + tokens_bought),
                'WRONG_DVT_TOKEN_BALANCE'
            );

    }


    #[test]
    #[available_gas(30000000)]
    fn test_eth_to_token_transfer_output() {


            let (
                uniswap_factory, 
                ether_token,
                damn_valuable_token,
                _
            ) = __setup_with_initial_liquidity();

            let dvt_exchange = IUniswapExchangeDispatcher{
                contract_address: uniswap_factory.get_exchange(
                    damn_valuable_token.contract_address
                )
            };

            call_contracts_as(DEPLOYER());

            let before_receiver_token_balance = damn_valuable_token.balance_of(RECEIVER());

            let tokens_bought = to_wad(1);
            let max_eth = 200_788_585_495_779_705;  // 0.200788585495779705 ETH
            let deadline = 1_000;

            ether_token.approve(
                dvt_exchange.contract_address,
                max_eth
            );
            let eth_sold = dvt_exchange.eth_to_token_transfer_output(
                max_eth,
                tokens_bought,
                deadline,
                RECEIVER()
            );

            assert_eq(
                @eth_sold, 
                @max_eth,
                'WRONG_ETH_SOLD_VALUE'
            );

            assert_eq(
                @damn_valuable_token.balance_of(RECEIVER()), 
                @(before_receiver_token_balance + tokens_bought),
                'WRONG_DVT_TOKEN_BALANCE'
            );

    }



    #[test]
    #[available_gas(30000000)]
    fn test_token_to_eth_swap_input() {

            let (
                uniswap_factory, 
                ether_token,
                damn_valuable_token,
                _
            ) = __setup_with_initial_liquidity();

            let dvt_exchange = IUniswapExchangeDispatcher{
                contract_address: uniswap_factory.get_exchange(
                    damn_valuable_token.contract_address
                )
            };

            call_contracts_as(DEPLOYER());

            let before_deployer_eth_balance = ether_token.balance_of(DEPLOYER());

            let tokens_sold = to_wad(1);
            let min_eth = 199_215_239_447_693_627; // 0.199215239447693627 ETH
            let deadline = 1_000;

            damn_valuable_token.approve(
                dvt_exchange.contract_address,
                tokens_sold
            );
            let eth_bought = dvt_exchange.token_to_eth_swap_input(
                tokens_sold,
                min_eth,
                deadline
            );

            assert_eq(
                @eth_bought, 
                @min_eth,
                'WRONG_ETH_BOUGHT_VALUE'
            );

            assert_eq(
                @ether_token.balance_of(DEPLOYER()), 
                @(before_deployer_eth_balance + eth_bought),
                'WRONG_ETH_BALANCE'
            );

    }



    #[test]
    #[available_gas(30000000)]
    fn test_token_to_eth_transfer_input() {


            let (
                uniswap_factory, 
                ether_token,
                damn_valuable_token,
                _
            ) = __setup_with_initial_liquidity();

            let dvt_exchange = IUniswapExchangeDispatcher{
                contract_address: uniswap_factory.get_exchange(
                    damn_valuable_token.contract_address
                )
            };

            call_contracts_as(DEPLOYER());

            let before_receiver_eth_balance = ether_token.balance_of(RECEIVER());

            let tokens_sold = to_wad(1);
            let min_eth = 199_215_239_447_693_627; // 0.199215239447693627 ETH
            let deadline = 1_000;

            damn_valuable_token.approve(
                dvt_exchange.contract_address,
                tokens_sold
            );
            let eth_bought = dvt_exchange.token_to_eth_transfer_input(
                tokens_sold,
                min_eth,
                deadline,
                RECEIVER()
            );

            assert_eq(
                @eth_bought, 
                @min_eth,
                'WRONG_ETH_BOUGHT_VALUE'
            );

            assert_eq(
                @ether_token.balance_of(RECEIVER()), 
                @(before_receiver_eth_balance + eth_bought),
                'WRONG_ETH_BALANCE'
            );

    }


    #[test]
    #[available_gas(30000000)]
    fn test_token_to_eth_swap_output() {


            let (
                uniswap_factory, 
                ether_token,
                damn_valuable_token,
                _
            ) = __setup_with_initial_liquidity();

            let dvt_exchange = IUniswapExchangeDispatcher{
                contract_address: uniswap_factory.get_exchange(
                    damn_valuable_token.contract_address
                )
            };

            call_contracts_as(DEPLOYER());

            let before_deployer_eth_balance = ether_token.balance_of(DEPLOYER());

            let eth_bought = to_wad(1);
            let max_tokens = 5_038_479_925_758_584_164; // 5.038479925758584164 DVT
            let deadline = 1_000;

            damn_valuable_token.approve(
                dvt_exchange.contract_address,
                max_tokens
            );
            let tokens_sold = dvt_exchange.token_to_eth_swap_output(
                eth_bought,
                max_tokens,
                deadline
            );

            assert_eq(
                @tokens_sold, 
                @max_tokens,
                'WRONG_TOKENS_SOLD_VALUE'
            );

            assert_eq(
                @ether_token.balance_of(DEPLOYER()), 
                @(before_deployer_eth_balance + eth_bought),
                'WRONG_ETH_BALANCE'
            );

    }


    #[test]
    #[available_gas(30000000)]
    fn test_token_to_eth_transfer_output() {

            let (
                uniswap_factory, 
                ether_token,
                damn_valuable_token,
                _
            ) = __setup_with_initial_liquidity();

            let dvt_exchange = IUniswapExchangeDispatcher{
                contract_address: uniswap_factory.get_exchange(
                    damn_valuable_token.contract_address
                )
            };

            call_contracts_as(DEPLOYER());

            let before_receiver_eth_balance = ether_token.balance_of(RECEIVER());

            let eth_bought = to_wad(1);
            let max_tokens = 5_038_479_925_758_584_164; // 5.038479925758584164 DVT
            let deadline = 1_000;

            damn_valuable_token.approve(
                dvt_exchange.contract_address,
                max_tokens
            );
            let tokens_sold = dvt_exchange.token_to_eth_transfer_output(
                eth_bought,
                max_tokens,
                deadline,
                RECEIVER()
            );

            assert_eq(
                @tokens_sold, 
                @max_tokens,
                'WRONG_TOKENS_SOLD_VALUE'
            );

            assert_eq(
                @ether_token.balance_of(RECEIVER()), 
                @(before_receiver_eth_balance + eth_bought),
                'WRONG_ETH_BALANCE'
            );

    }


    #[test]
    #[available_gas(30000000)]
    fn token_to_token_swap_input(){

        let (
            uniswap_factory, 
            ether_token,
            damn_valuable_token,
            other_side_token
        ) = __setup_with_initial_liquidity();

        let dvt_exchange = IUniswapExchangeDispatcher{
            contract_address: uniswap_factory.get_exchange(
                damn_valuable_token.contract_address
            )
        };

        let ost_exchange = IUniswapExchangeDispatcher{
            contract_address: uniswap_factory.get_exchange(
                other_side_token.contract_address
            )
        };

        call_contracts_as(DEPLOYER());

        let before_deployer_token_balance = damn_valuable_token.balance_of(DEPLOYER());
        let before_deployer_ost_balance = other_side_token.balance_of(DEPLOYER());

        let dvt_tokens_sold = to_wad(1);
        let min_ost_bought = to_wad(1);
        let min_eth_bought = 199_215_239_447_693_627; // 0.199215239447693627 ETH
        let deadline = 1_000;

        damn_valuable_token.approve(
            dvt_exchange.contract_address,
            dvt_tokens_sold
        );
        let ost_bought = dvt_exchange.token_to_token_swap_input(
            dvt_tokens_sold,
            min_ost_bought,
            min_eth_bought,
            deadline,
            other_side_token.contract_address
        );

        

        assert_eq(
            @ost_bought, 
            @19_842_054_467_370_275_639, // 19.842054467370275639 OST
            'WRONG_OST_BOUGHT_VALUE'
        );

        assert_eq(
            @other_side_token.balance_of(DEPLOYER()), 
            @(before_deployer_ost_balance + ost_bought),
            'WRONG_OST_BALANCE'
        );

        assert_eq(
            @damn_valuable_token.balance_of(DEPLOYER()), 
            @(before_deployer_token_balance - dvt_tokens_sold),
            'WRONG_DVT_BALANCE'
        );
    }



    #[test]
    #[available_gas(30000000)]
    fn token_to_token_transfer_input() {
            
            let (
                uniswap_factory, 
                ether_token,
                damn_valuable_token,
                other_side_token
            ) = __setup_with_initial_liquidity();
    
            let dvt_exchange = IUniswapExchangeDispatcher{
                contract_address: uniswap_factory.get_exchange(
                    damn_valuable_token.contract_address
                )
            };
    
            let ost_exchange = IUniswapExchangeDispatcher{
                contract_address: uniswap_factory.get_exchange(
                    other_side_token.contract_address
                )
            };
    
            call_contracts_as(DEPLOYER());
    
            let before_deployer_token_balance = damn_valuable_token.balance_of(DEPLOYER());
            let before_receiver_token_balance = damn_valuable_token.balance_of(RECEIVER());
            let before_receiver_ost_balance = other_side_token.balance_of(RECEIVER());
    
            let dvt_tokens_sold = to_wad(1);
            let min_ost_bought = to_wad(1);
            let min_eth_bought = 199_215_239_447_693_627; // 0.199215239447693627 ETH
            let deadline = 1_000;
    
            damn_valuable_token.approve(
                dvt_exchange.contract_address,
                dvt_tokens_sold
            );
            let ost_bought = dvt_exchange.token_to_token_transfer_input(
                dvt_tokens_sold,
                min_ost_bought,
                min_eth_bought,
                deadline,
                RECEIVER(),
                other_side_token.contract_address
            );
    
            
    
            assert_eq(
                @ost_bought, 
                @19_842_054_467_370_275_639, // 19.842054467370275639 OST
                'WRONG_OST_BOUGHT_VALUE'
            );
    
            assert_eq(
                @other_side_token.balance_of(RECEIVER()), 
                @(before_receiver_ost_balance + ost_bought),
                'WRONG_OST_BALANCE'
            );

            assert_eq(
                @damn_valuable_token.balance_of(DEPLOYER()), 
                @(before_deployer_token_balance - dvt_tokens_sold),
                'WRONG_DVT_BALANCE'
            );
    }



    #[test]
    #[available_gas(30000000)]
    fn token_to_token_swap_output(){
            
            let (
                uniswap_factory, 
                ether_token,
                damn_valuable_token,
                other_side_token
            ) = __setup_with_initial_liquidity();
    
            let dvt_exchange = IUniswapExchangeDispatcher{
                contract_address: uniswap_factory.get_exchange(
                    damn_valuable_token.contract_address
                )
            };
    
            let ost_exchange = IUniswapExchangeDispatcher{
                contract_address: uniswap_factory.get_exchange(
                    other_side_token.contract_address
                )
            };
    
            call_contracts_as(DEPLOYER());
    
            let before_deployer_token_balance = damn_valuable_token.balance_of(DEPLOYER());
            let before_deployer_ost_balance = other_side_token.balance_of(DEPLOYER());
    
            let ost_bought = to_wad(20);
            let max_dvt_tokens_sold = 1_007_975_557_063_817_411; // 1.007975557063817411 DVT
            let max_eth_sold = 200_802_608_024_273_020;  // 0.200802608024273020 ETH
            let deadline = 1_000;
    
            damn_valuable_token.approve(
                dvt_exchange.contract_address,
                max_dvt_tokens_sold
            );
            let tokens_sold = dvt_exchange.token_to_token_swap_output(
                ost_bought,
                max_dvt_tokens_sold,
                max_eth_sold,
                deadline,
                other_side_token.contract_address
            );

    
            assert_eq(
                @tokens_sold, 
                @max_dvt_tokens_sold,
                'WRONG_TOKENS_SOLD_VALUE'
            );
    
            assert_eq(
                @other_side_token.balance_of(DEPLOYER()), 
                @(before_deployer_ost_balance + ost_bought),
                'WRONG_OST_BALANCE'
            );

            assert_eq(
                @damn_valuable_token.balance_of(DEPLOYER()), 
                @(before_deployer_token_balance - tokens_sold),
                'WRONG_DVT_BALANCE'
            );
    }

    #[test]
    #[available_gas(30000000)]
    fn token_to_token_transfer_output(){
        let (
            uniswap_factory, 
            ether_token,
            damn_valuable_token,
            other_side_token
        ) = __setup_with_initial_liquidity();

        let dvt_exchange = IUniswapExchangeDispatcher{
            contract_address: uniswap_factory.get_exchange(
                damn_valuable_token.contract_address
            )
        };

        let ost_exchange = IUniswapExchangeDispatcher{
            contract_address: uniswap_factory.get_exchange(
                other_side_token.contract_address
            )
        };

        call_contracts_as(DEPLOYER());

        let before_deployer_token_balance = damn_valuable_token.balance_of(DEPLOYER());
        let before_receiver_token_balance = damn_valuable_token.balance_of(RECEIVER());

        let ost_bought = to_wad(20);
        let max_dvt_tokens_sold = 1_007_975_557_063_817_411; // 1.007975557063817411 DVT
        let max_eth_sold = 200_802_608_024_273_020;  // 0.200802608024273020 ETH
        let deadline = 1_000;

        damn_valuable_token.approve(
            dvt_exchange.contract_address,
            max_dvt_tokens_sold
        );
        let tokens_sold = dvt_exchange.token_to_token_transfer_output(
            ost_bought,
            max_dvt_tokens_sold,
            max_eth_sold,
            deadline,
            RECEIVER(),
            other_side_token.contract_address
        );


        assert_eq(
            @tokens_sold, 
            @max_dvt_tokens_sold,
            'WRONG_TOKENS_SOLD_VALUE'
        );

        assert_eq(
            @other_side_token.balance_of(RECEIVER()), 
            @(before_receiver_token_balance + ost_bought),
            'WRONG_OST_BALANCE'
        );

        assert_eq(
            @damn_valuable_token.balance_of(DEPLOYER()), 
            @(before_deployer_token_balance - tokens_sold),
            'WRONG_DVT_BALANCE'
        );

    }




    #[test]
    #[available_gas(30000000)]
    fn token_to_exchange_swap_input(){

        let (
            uniswap_factory, 
            ether_token,
            damn_valuable_token,
            other_side_token
        ) = __setup_with_initial_liquidity();

        let dvt_exchange = IUniswapExchangeDispatcher{
            contract_address: uniswap_factory.get_exchange(
                damn_valuable_token.contract_address
            )
        };

        let ost_exchange = IUniswapExchangeDispatcher{
            contract_address: uniswap_factory.get_exchange(
                other_side_token.contract_address
            )
        };

        call_contracts_as(DEPLOYER());

        let before_deployer_token_balance = damn_valuable_token.balance_of(DEPLOYER());
        let before_deployer_ost_balance = other_side_token.balance_of(DEPLOYER());

        let dvt_tokens_sold = to_wad(1);
        let min_ost_bought = to_wad(1);
        let min_eth_bought = 199_215_239_447_693_627; // 0.199215239447693627 ETH
        let deadline = 1_000;

        damn_valuable_token.approve(
            dvt_exchange.contract_address,
            dvt_tokens_sold
        );
        let ost_bought = dvt_exchange.token_to_exchange_swap_input(
            dvt_tokens_sold,
            min_ost_bought,
            min_eth_bought,
            deadline,
            ost_exchange.contract_address
        );

        

        assert_eq(
            @ost_bought, 
            @19_842_054_467_370_275_639, // 19.842054467370275639 OST
            'WRONG_OST_BOUGHT_VALUE'
        );

        assert_eq(
            @other_side_token.balance_of(DEPLOYER()), 
            @(before_deployer_ost_balance + ost_bought),
            'WRONG_OST_BALANCE'
        );

        assert_eq(
            @damn_valuable_token.balance_of(DEPLOYER()), 
            @(before_deployer_token_balance - dvt_tokens_sold),
            'WRONG_DVT_BALANCE'
        );
    }



    #[test]
    #[available_gas(30000000)]
    fn test_remove_liquidity(){


        let (
            uniswap_factory, 
            ether_token,
            damn_valuable_token,
            other_side_token
        ) = __setup_with_initial_liquidity();

        // dvt exchange has 215 ETH and 1,075.00000...01 DVT
        let dvt_exchange = IUniswapExchangeDispatcher{
            contract_address: uniswap_factory.get_exchange(
                damn_valuable_token.contract_address
            )
        };

        
        call_contracts_as(DEPLOYER());

        let before_deployer_token_balance = damn_valuable_token.balance_of(DEPLOYER());
        let before_deployer_eth_balance = ether_token.balance_of(DEPLOYER());

        let dvt_UNI = to_wad(1);
        let min_eth = to_wad(1); // 1 ETH 
        let min_tokens = to_wad(5); // 5 DVT
        let deadline = 1_000;
  
        let (eth_amount, token_amount) = dvt_exchange.remove_liquidity(
            dvt_UNI,
            min_eth,
            min_tokens,
            deadline
        );

        assert_eq(
            @eth_amount, 
            @min_eth,
            'WRONG_ETH_AMOUNT'
        );

        assert_eq(
            @token_amount, 
            @min_tokens,
            'WRONG_TOKEN_AMOUNT'
        );

        assert_eq(
            @ether_token.balance_of(DEPLOYER()), 
            @(before_deployer_eth_balance + eth_amount),
            'WRONG_ETH_BALANCE'
        );

        assert_eq(
            @damn_valuable_token.balance_of(DEPLOYER()), 
            @(before_deployer_token_balance + token_amount),
            'WRONG_DVT_BALANCE'
        );
    }


    



    #[test]
    #[available_gas(30000000)]
    fn token_to_exchange_transfer_input() {
            
            let (
                uniswap_factory, 
                ether_token,
                damn_valuable_token,
                other_side_token
            ) = __setup_with_initial_liquidity();
    
            let dvt_exchange = IUniswapExchangeDispatcher{
                contract_address: uniswap_factory.get_exchange(
                    damn_valuable_token.contract_address
                )
            };
    
            let ost_exchange = IUniswapExchangeDispatcher{
                contract_address: uniswap_factory.get_exchange(
                    other_side_token.contract_address
                )
            };
    
            call_contracts_as(DEPLOYER());
    
            let before_deployer_token_balance = damn_valuable_token.balance_of(DEPLOYER());
            let before_receiver_token_balance = damn_valuable_token.balance_of(RECEIVER());
            let before_receiver_ost_balance = other_side_token.balance_of(RECEIVER());
    
            let dvt_tokens_sold = to_wad(1);
            let min_ost_bought = to_wad(1);
            let min_eth_bought = 199_215_239_447_693_627; // 0.199215239447693627 ETH
            let deadline = 1_000;
    
            damn_valuable_token.approve(
                dvt_exchange.contract_address,
                dvt_tokens_sold
            );
            let ost_bought = dvt_exchange.token_to_exchange_transfer_input(
                dvt_tokens_sold,
                min_ost_bought,
                min_eth_bought,
                deadline,
                RECEIVER(),
                ost_exchange.contract_address
            );
    
            
    
            assert_eq(
                @ost_bought, 
                @19_842_054_467_370_275_639, // 19.842054467370275639 OST
                'WRONG_OST_BOUGHT_VALUE'
            );
    
            assert_eq(
                @other_side_token.balance_of(RECEIVER()), 
                @(before_receiver_ost_balance + ost_bought),
                'WRONG_OST_BALANCE'
            );

            assert_eq(
                @damn_valuable_token.balance_of(DEPLOYER()), 
                @(before_deployer_token_balance - dvt_tokens_sold),
                'WRONG_DVT_BALANCE'
            );
    }



    #[test]
    #[available_gas(30000000)]
    fn token_to_exchange_swap_output(){
            
            let (
                uniswap_factory, 
                ether_token,
                damn_valuable_token,
                other_side_token
            ) = __setup_with_initial_liquidity();
    
            let dvt_exchange = IUniswapExchangeDispatcher{
                contract_address: uniswap_factory.get_exchange(
                    damn_valuable_token.contract_address
                )
            };
    
            let ost_exchange = IUniswapExchangeDispatcher{
                contract_address: uniswap_factory.get_exchange(
                    other_side_token.contract_address
                )
            };
    
            call_contracts_as(DEPLOYER());
    
            let before_deployer_token_balance = damn_valuable_token.balance_of(DEPLOYER());
            let before_deployer_ost_balance = other_side_token.balance_of(DEPLOYER());
    
            let ost_bought = to_wad(20);
            let max_dvt_tokens_sold = 1_007_975_557_063_817_411; // 1.007975557063817411 DVT
            let max_eth_sold = 200_802_608_024_273_020;  // 0.200802608024273020 ETH
            let deadline = 1_000;
    
            damn_valuable_token.approve(
                dvt_exchange.contract_address,
                max_dvt_tokens_sold
            );
            let tokens_sold = dvt_exchange.token_to_exchange_swap_output(
                ost_bought,
                max_dvt_tokens_sold,
                max_eth_sold,
                deadline,
                ost_exchange.contract_address
            );

    
            assert_eq(
                @tokens_sold, 
                @max_dvt_tokens_sold,
                'WRONG_TOKENS_SOLD_VALUE'
            );
    
            assert_eq(
                @other_side_token.balance_of(DEPLOYER()), 
                @(before_deployer_ost_balance + ost_bought),
                'WRONG_OST_BALANCE'
            );

            assert_eq(
                @damn_valuable_token.balance_of(DEPLOYER()), 
                @(before_deployer_token_balance - tokens_sold),
                'WRONG_DVT_BALANCE'
            );
    }

    #[test]
    #[available_gas(30000000)]
    fn token_to_exchange_transfer_output(){
        let (
            uniswap_factory, 
            ether_token,
            damn_valuable_token,
            other_side_token
        ) = __setup_with_initial_liquidity();

        let dvt_exchange = IUniswapExchangeDispatcher{
            contract_address: uniswap_factory.get_exchange(
                damn_valuable_token.contract_address
            )
        };

        let ost_exchange = IUniswapExchangeDispatcher{
            contract_address: uniswap_factory.get_exchange(
                other_side_token.contract_address
            )
        };

        call_contracts_as(DEPLOYER());

        let before_deployer_token_balance = damn_valuable_token.balance_of(DEPLOYER());
        let before_receiver_token_balance = damn_valuable_token.balance_of(RECEIVER());

        let ost_bought = to_wad(20);
        let max_dvt_tokens_sold = 1_007_975_557_063_817_411; // 1.007975557063817411 DVT
        let max_eth_sold = 200_802_608_024_273_020;  // 0.200802608024273020 ETH
        let deadline = 1_000;

        damn_valuable_token.approve(
            dvt_exchange.contract_address,
            max_dvt_tokens_sold
        );
        let tokens_sold = dvt_exchange.token_to_exchange_transfer_output(
            ost_bought,
            max_dvt_tokens_sold,
            max_eth_sold,
            deadline,
            RECEIVER(),
            ost_exchange.contract_address
        );


        assert_eq(
            @tokens_sold, 
            @max_dvt_tokens_sold,
            'WRONG_TOKENS_SOLD_VALUE'
        );

        assert_eq(
            @other_side_token.balance_of(RECEIVER()), 
            @(before_receiver_token_balance + ost_bought),
            'WRONG_OST_BALANCE'
        );

        assert_eq(
            @damn_valuable_token.balance_of(DEPLOYER()), 
            @(before_deployer_token_balance - tokens_sold),
            'WRONG_DVT_BALANCE'
        );

    }


    
    fn __setup_exchange() -> (
        IUniswapFactoryDispatcher, 
        IERC20Dispatcher,
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
            // Deploy Other Side Token
            ////////////////////////////////////
            let name = 'OtherSideToken';
            let symbol = 'OST';
            let initial_supply = BoundedInt::<u256>::max();
            let recipient = DEPLOYER();

            let mut calldata = Default::default();
            Serde::serialize(@name, ref calldata);
            Serde::serialize(@symbol, ref calldata);
            Serde::<u256>::serialize(@initial_supply, ref calldata);
            Serde::<ContractAddress>::serialize(@recipient, ref calldata);


            let (other_side_token_address, _) = deploy_syscall(
                ERC20::TEST_CLASS_HASH.try_into().unwrap(),
                calldata.len().into(), 
                calldata.span(), 
                false
            ).unwrap();

            let other_side_token = IERC20Dispatcher{ 
                contract_address: other_side_token_address
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

            call_contracts_as(uniswap_factory_address);

            ////////////////////////////////////////
            // Create Damn Valuable Token Exchange
            ////////////////////////////////////////
            uniswap_factory.create_exchange(
                damn_valuable_token.contract_address
            );

            ////////////////////////////////////////
            // Create Other Side Token Exchange
            ////////////////////////////////////////
            uniswap_factory.create_exchange(
                other_side_token.contract_address
            );


            (
                uniswap_factory,
                ether_token,
                damn_valuable_token,
                other_side_token
            )
            
        }



    fn __setup_with_initial_liquidity() -> (
        IUniswapFactoryDispatcher, 
        IERC20Dispatcher,
        IERC20Dispatcher,
        IERC20Dispatcher,
        ) {


        let (
            uniswap_factory, 
            ether_token,
            damn_valuable_token,
            other_side_token
        ) = __setup_exchange();

        // Add liquidity to DVT exchange

        let dvt_exchange = IUniswapExchangeDispatcher{
            contract_address: uniswap_factory.get_exchange(
                damn_valuable_token.contract_address
            )
        };



        let eth_amount = to_wad(200);
        let max_tokens = to_wad(1_000);

        call_contracts_as(DEPLOYER());
        
        /////////////////////////////////////////
        ether_token.approve(
            dvt_exchange.contract_address,
            eth_amount
        );
        damn_valuable_token.approve(
            dvt_exchange.contract_address,
            max_tokens
        );
        dvt_exchange.add_liquidity(
            eth_amount,
            0, // immaterial when total Liquidity is 0
            max_tokens,
            12
        );


        /////////////////////////////////////////
        let eth_amount = to_wad(3);
        let max_tokens = to_wad(15) + 1;
        ether_token.approve(
            dvt_exchange.contract_address,
            eth_amount
        );

        damn_valuable_token.approve(
            dvt_exchange.contract_address,
            max_tokens
        );

        dvt_exchange.add_liquidity(
            eth_amount,
            to_wad(1), 
            max_tokens,
            1
        );
        

        /////////////////////////////////////////
        let eth_amount = to_wad(12);
        let max_tokens = to_wad(60) + 1;
        ether_token.approve(
            dvt_exchange.contract_address,
            eth_amount
        );

        damn_valuable_token.approve(
            dvt_exchange.contract_address,
            max_tokens
        );

        dvt_exchange.add_liquidity(
            eth_amount,
            to_wad(1), 
            max_tokens,
            1
        );
        /////////////////////////////////////////



        /////////////////////////////////////////////////////////////////////
        // NOTE: DVT Exchange has a total of 1075.000...002 DVT and 215 ETH
        //       having a ratio of about 1 ETH = 5 DVT 
        //////////////////////////////////////////////////////////////////////




        // Add liquidity to Other Side Token exchange

        let ost_exchange = IUniswapExchangeDispatcher{
            contract_address: uniswap_factory.get_exchange(
                other_side_token.contract_address
            )
        };
        let eth_amount = to_wad(200);
        let max_tokens = to_wad(20_000);
        ether_token.approve(
            ost_exchange.contract_address,
            eth_amount
        );

        other_side_token.approve(
            ost_exchange.contract_address,
            max_tokens
        );

        let OST_UNI = ost_exchange.add_liquidity(
            eth_amount,
            0, // immaterial when total liquidity is 0
            max_tokens,
            1
        );


        //////////////////////////////////////////////////////////////
        // NOTE: OST Exchange has a total of 20_000 OST and 200 ETH
        //       having a ratio of 1 ETH = 100 OST
        //////////////////////////////////////////////////////////////

        
        (
            uniswap_factory,
            ether_token,
            damn_valuable_token,
            other_side_token
        )    
     
    }
        
}

