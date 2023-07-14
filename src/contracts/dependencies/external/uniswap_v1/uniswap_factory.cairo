#[starknet::contract]
mod uniswap_factory {
    use zeroable::Zeroable;
    use starknet::ContractAddress;
    use damnvulnerabledefi::contracts::dependencies::external::uniswap_v1::uniswap_exchange::uniswap_exchange;
    use damnvulnerabledefi::contracts::dependencies::external::uniswap_v1::uniswap_interfaces::{
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
    use starknet::ClassHash;


    #[storage]
    struct Storage {
        exchange_template: ClassHash,
        ether_token: ContractAddress,
        token_count: u256,
        token_to_exchange: LegacyMap<ContractAddress, ContractAddress>,
        exchange_to_token: LegacyMap<ContractAddress, ContractAddress>,
        id_to_token: LegacyMap<u256, ContractAddress>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
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

        fn initialize_factory(
            ref self: ContractState, template: ClassHash, ether_token: ContractAddress
        ) {
            assert(self.exchange_template.read().is_zero(), 'ALREADY_INITIALIZED');
            assert(self.ether_token.read().is_zero(), 'ALREADY_INITIALIZED');
            assert(template.is_non_zero(), 'INVALID_CLASS_HASH');
            self.exchange_template.write(template);
            self.ether_token.write(ether_token);
        }

        fn create_exchange(ref self: ContractState, token: ContractAddress) -> ContractAddress {
            assert(token.is_non_zero(), 'INVALID_ADDRESS');
            assert(self.exchange_template.read().is_non_zero(), 'NOT_INITIALIZED');
            assert(self.token_to_exchange.read(token).is_zero(), 'EXCHANGE_ALREADY_CREATED');

            let calldata: Array::<felt252> = Default::default();
            let (address_uniswap_exchange, _) = deploy_syscall(
                self.exchange_template.read(), calldata.len().into(), calldata.span(), false
            )
                .unwrap();

            let exchange = IUniswapExchangeDispatcher {
                contract_address: address_uniswap_exchange
            };
            exchange.setup(token, self.ether_token.read());
            self.token_to_exchange.write(token, exchange.contract_address);
            self.exchange_to_token.write(exchange.contract_address, token);

            let token_id = self.token_count.read() + 1;
            self.token_count.write(token_id);
            self.id_to_token.write(token_id, token);
            self
                .emit(
                    Event::NewExchange(
                        NewExchange { token: token, exchange: exchange.contract_address,  }
                    )
                );

            exchange.contract_address
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
