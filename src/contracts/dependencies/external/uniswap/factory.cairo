
#[starknet::contract]
mod uniswap_factory {
    use zeroable::Zeroable;
    use starknet::ContractAddress;
    use damnvulnerabledefi::contracts::dependencies::external::uniswap::exchange::uniswap_exchange;
    use damnvulnerabledefi::contracts::dependencies::external::uniswap::interfaces::{
        IUniswapExchange, IUniswapExchangeDispatcher, IUniswapExchangeDispatcherTrait,
        IUniswapFactory
    };
    use starknet::syscalls::deploy_syscall;
    use option::OptionTrait;
    use traits::TryInto;
    use traits::Into;
    use array::SpanTrait;
    use result::ResultTrait;
    use array::ArrayTrait;


    
    #[storage]
    struct Storage{
        exchange_template: ContractAddress,
        token_count: u256,
        token_to_exchange: LegacyMap<ContractAddress, ContractAddress>,
        exchange_to_token: LegacyMap<ContractAddress, ContractAddress>,
        id_to_token: LegacyMap<u256, ContractAddress>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event{
        NewExchange: NewExchange
    }

    #[derive(Drop, starknet::Event)]
    struct NewExchange {
        token: ContractAddress,
        exchange: ContractAddress
    }


    #[external(v0)]
    impl UniswapFactoryImpl of IUniswapFactory<ContractState> {

        /////////////////////////
        // Factory Functions
        /////////////////////////



        fn initialize_factory(ref self: ContractState, template: ContractAddress){
            assert(self.exchange_template.read().is_zero(), 'INVALID_ADDRESS');
            assert(template.is_non_zero(), 'INVALID_ADDRESS');
            self.exchange_template.write(template);
        }

        fn create_exchange(ref self: ContractState, token: ContractAddress, ether_token: ContractAddress) -> ContractAddress {
            assert(token.is_non_zero(), 'INVALID_ADDRESS');
            assert(self.exchange_template.read().is_non_zero(), 'INVALID_ADDRESS');
            assert(self.token_to_exchange.read(token).is_zero(), 'INVALID_ADDRESS');

            // deploy exchange contract

            // how to do this the right way?

            // I want to do this
            // UniswapExchange exchange = new UniswapExchange();

            // let calldata: Array::<felt252> = Default::default();
            // let (address_uniswap_exchange, _) = deploy_syscall(
            //     uniswap_exchange::TEST_CLASS_HASH.try_into().unwrap(),
            //     calldata.len().into(),
            //     calldata.span(), 
            //     false
            // ).unwrap();


            // let exchange = IUniswapExchangeDispatcher{
            //     contract_address: address_uniswap_exchange
            // };
            // exchange.setup(token,ether_token);
            // self.token_to_exchange.write(token, exchange.contract_address);
            // self.exchange_to_token.write(exchange.contract_address, token);

            // let token_id = self.token_count.read() + 1;
            // self.token_count.write(token_id);
            // self.id_to_token.write(token_id, token);
            // self.emit(Event::NewExchange(NewExchange{
            //     token: token,
            //     exchange: exchange.contract_address,
            // }));

            // exchange.contract_address
            token // just return the token for now
        }


          ///////////////////////
          // Getter Functions
          ///////////////////////


        fn get_exchange(self: @ContractState, token: ContractAddress) -> ContractAddress {
            self.token_to_exchange.read(token)
        }

        fn get_token(self: @ContractState, exchange: ContractAddress) -> ContractAddress {
            self.exchange_to_token.read(exchange)
        }

        fn get_token_with_id(self: @ContractState, token_id: u256) -> ContractAddress {
            self.id_to_token.read(token_id)
        }

        
    }


   

}