use starknet::ContractAddress;

#[starknet::contract]
mod uniswap_exchange {
    use zeroable::Zeroable;
    use starknet::ContractAddress;
    use starknet::info::get_block_timestamp;

    use damnvulnerabledefi::contracts::dependencies::external::token::ERC20::{
        ERC20,
        IERC20, 
        IERC20Dispatcher, 
        IERC20DispatcherTrait
    };
    use damnvulnerabledefi::contracts::dependencies::external::token::ERC20::ERC20::{
        ERC20 as ERC20Impl,
        PrivateImpl as PrivateERC20Impl,
    };

    use damnvulnerabledefi::contracts::dependencies::external::uniswap_v1::uniswap_interfaces::{
        IUniswapExchange, IUniswapExchangeDispatcher, IUniswapExchangeDispatcherTrait,
        IUniswapFactory, IUniswapFactoryDispatcher, IUniswapFactoryDispatcherTrait,
        IUniswapExchangeStorage
    };

    use damnvulnerabledefi::contracts::dependencies::external::token::ERC20::ERC20::name::InternalContractStateTrait as ERC20NameInternalContractStateTrait;
    use damnvulnerabledefi::contracts::dependencies::external::token::ERC20::ERC20::symbol::InternalContractStateTrait as ERC20SymbolInternalContractStateTrait;

    use traits::Into;


    

    #[storage]
    struct Storage{
        token: IERC20Dispatcher,
        ether_token: IERC20Dispatcher,
        ether_token_balance: u256,
        factory: IUniswapFactoryDispatcher,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event{
        TokenPurchase: TokenPurchase,
        EthPurchase: EthPurchase,
        AddLiquidity: AddLiquidity,
        RemoveLiquidity: RemoveLiquidity
    }

    #[derive(Drop, starknet::Event)]
    struct TokenPurchase {
        buyer: ContractAddress,
        eth_sold: u256,
        tokens_bought: u256
    }

    #[derive(Drop, starknet::Event)]
    struct EthPurchase {
        buyer: ContractAddress,
        tokens_sold: u256,
        eth_bought: u256
    }

    #[derive(Drop, starknet::Event)]
    struct AddLiquidity {
        provider: ContractAddress,
        eth_amount: u256,
        token_amount: u256
    }

    #[derive(Drop, starknet::Event)]
    struct RemoveLiquidity {
        provider: ContractAddress,
        eth_amount: u256,
        token_amount: u256
    }


    #[external(v0)]
    impl UniswapERC20Impl of IERC20<ContractState> {
       
        fn name(self: @ContractState) -> felt252 {
            let state = ERC20::unsafe_new_contract_state();
            ERC20Impl::name(@state)
        }

        fn symbol(self: @ContractState) -> felt252 {
            let state = ERC20::unsafe_new_contract_state();
            ERC20Impl::symbol(@state)
        }

        fn decimals(self: @ContractState) -> u8 {
            let state = ERC20::unsafe_new_contract_state();
            ERC20Impl::decimals(@state)
        }

        fn total_supply(self: @ContractState) -> u256 {
            let state = ERC20::unsafe_new_contract_state();
            ERC20Impl::total_supply(@state)
        }

        fn balance_of(self: @ContractState, account: ContractAddress) -> u256 {
            let state = ERC20::unsafe_new_contract_state();
            ERC20Impl::balance_of(@state, account)
        }

        fn allowance(self: @ContractState, owner: ContractAddress, spender: ContractAddress) -> u256 {
            let state = ERC20::unsafe_new_contract_state();
            ERC20Impl::allowance(@state, owner, spender)
        }

        fn transfer(ref self: ContractState, recipient: ContractAddress, amount: u256) -> bool {
            let mut state = ERC20::unsafe_new_contract_state();
            assert(ERC20Impl::transfer(ref state, recipient, amount),'');

            true
        }

        fn transfer_from(
            ref self: ContractState, sender: ContractAddress, recipient: ContractAddress, amount: u256
        ) -> bool {
            let mut state = ERC20::unsafe_new_contract_state();
            assert(ERC20Impl::transfer_from(ref state, sender, recipient, amount),'');

            true
        }

        fn approve(ref self: ContractState, spender: ContractAddress, amount: u256) -> bool {
            let mut state = ERC20::unsafe_new_contract_state();
            assert(ERC20Impl::approve(ref state, spender, amount),'');

            true
        }

        fn increase_allowance(ref self: ContractState, spender: ContractAddress, added_value: u256) -> bool {
            let mut state = ERC20::unsafe_new_contract_state();
            assert(ERC20Impl::increase_allowance(ref state, spender, added_value),'');

            true
        }

        fn decrease_allowance(ref self: ContractState, spender: ContractAddress, subtracted_value: u256) -> bool {
            let mut state = ERC20::unsafe_new_contract_state();
            assert(ERC20Impl::decrease_allowance(ref state, spender, subtracted_value),'');

            true
        }
    }

    #[generate_trait]
    impl UniswapPrivateERC20Impl of UniswapPrivateERC20Trait {

        fn _initializer(
             name: felt252, 
             symbol: felt252
        ) {
            let mut state = ERC20::unsafe_new_contract_state();
            state.name.write(name);
            state.symbol.write(symbol);
        }

        fn _mint(recipient: ContractAddress, amount: u256) {
            let mut state = ERC20::unsafe_new_contract_state();
            PrivateERC20Impl::_mint(ref state, recipient, amount);
        }

        fn _burn(account: ContractAddress, amount: u256) {
            let mut state = ERC20::unsafe_new_contract_state();
            PrivateERC20Impl::_burn(ref state, account, amount);
        }

    }

    #[external(v0)]
    impl UniswapExchangeStorage of IUniswapExchangeStorage<ContractState> {
        fn token(ref self: ContractState) -> IERC20Dispatcher {
            self.token.read()
        }
        fn ether_token(ref self: ContractState) -> IERC20Dispatcher {
            self.ether_token.read()
        }
        fn ether_token_balance(ref self: ContractState) -> u256 {
            self.ether_token_balance.read()
        }
        fn factory(ref self: ContractState) -> IUniswapFactoryDispatcher {
            self.factory.read()
        }
    }
    

    #[external(v0)]
    impl UniswapExchangeImpl of IUniswapExchange<ContractState> {

        fn setup(
            ref self: ContractState, 
            token_addr: ContractAddress, 
            ether_token_addr: ContractAddress
        ){
            assert(self.factory.read().contract_address.is_zero(), 'INVALID_ADDRESS');
            assert(self.token.read().contract_address.is_zero(), 'INVALID_ADDRESS');
            assert(self.ether_token.read().contract_address.is_zero(), 'INVALID_ADDRESS');
            assert(!token_addr.is_zero(), 'INVALID_ADDRESS');

            self.factory.write(IUniswapFactoryDispatcher{
                contract_address: starknet::get_caller_address()
            });
            self.token.write(IERC20Dispatcher{
                contract_address: token_addr
            });
            self.ether_token.write(IERC20Dispatcher{
                contract_address: ether_token_addr
            });

            UniswapPrivateERC20Impl::_initializer(
               'Uniswap V1',
                'UNI-V1'
            );

        }


        fn get_input_price(
            self: @ContractState,
            input_amount: u256,
            input_reserve: u256, 
            output_reserve: u256
        ) -> u256 {
            assert(input_reserve > 0 && output_reserve > 0, 'RESERVE_IS_ZERO');
            let input_amount_with_fee = input_amount * 997;
            let numerator = input_amount_with_fee * output_reserve;
            let denominator = (input_reserve * 1000) + input_amount_with_fee;
            numerator / denominator
        }



        fn get_output_price(
            self: @ContractState,
            output_amount: u256,
            input_reserve: u256, 
            output_reserve: u256
        ) -> u256 {
            assert(input_reserve > 0 && output_reserve > 0, 'INVALID_VALUE');
            let numerator = input_reserve * output_amount * 1000;
            let denominator = (output_reserve - output_amount) * 997;
            (numerator / denominator) + 1
        }


        fn eth_to_token_swap_input(
            ref self: ContractState,
            value: u256,
            min_tokens: u256,
            deadline: u256
        ) -> u256 {

            let caller = starknet::get_caller_address();
            UniswapExchangePrivateImpl::_receive_ether(ref self,caller, value);

            UniswapExchangePrivateImpl::eth_to_token_input(
                ref self,
                value, 
                min_tokens,  
                deadline,
                caller,
                caller
            )
        }



        fn eth_to_token_transfer_input(
            ref self: ContractState,
            value: u256,
            min_tokens: u256,
            deadline: u256,
            recipient: ContractAddress
        ) -> u256 {
            let this = starknet::get_contract_address();
            assert(recipient != this, 'INVALID_ADDRESS');
            assert(!recipient.is_zero(), 'INVALID_ADDRESS');

            let caller = starknet::get_caller_address();
            UniswapExchangePrivateImpl::_receive_ether(ref self,caller, value);

            UniswapExchangePrivateImpl::eth_to_token_input(
                ref self,
                value, 
                min_tokens,  
                deadline,
                caller,
                recipient
            )
        }



        fn eth_to_token_swap_output(
            ref self: ContractState,
            value: u256,
            tokens_bought: u256,
            deadline: u256
        ) -> u256 {
            let caller = starknet::get_caller_address();
            UniswapExchangePrivateImpl::_receive_ether(ref self,caller, value);

            UniswapExchangePrivateImpl::eth_to_token_output(
                ref self,
                tokens_bought, 
                value, 
                deadline,
                caller,
                caller
            )
        }




        fn eth_to_token_transfer_output(
            ref self: ContractState,
            value: u256,
            tokens_bought: u256,
            deadline: u256,
            recipient: ContractAddress
        ) -> u256 {
            let this = starknet::get_contract_address();
            assert(recipient != this, 'INVALID_ADDRESS');
            assert(!recipient.is_zero(), 'INVALID_ADDRESS');

            let caller = starknet::get_caller_address();
            UniswapExchangePrivateImpl::_receive_ether(ref self,caller, value);

            UniswapExchangePrivateImpl::eth_to_token_output(
                ref self,
                tokens_bought, 
                value, 
                deadline,
                caller,
                recipient
            )
        }



        fn token_to_eth_swap_input(
            ref self: ContractState,
            tokens_sold: u256,
            min_eth: u256,
            deadline: u256
        ) -> u256 {
            let caller = starknet::get_caller_address();
            UniswapExchangePrivateImpl::token_to_eth_input(
                ref self,
                tokens_sold, 
                min_eth, 
                deadline,
                caller,
                caller
            )
        }



        fn token_to_eth_transfer_input(
            ref self: ContractState,
            tokens_sold: u256,
            min_eth: u256,
            deadline: u256,
            recipient: ContractAddress
        ) -> u256 {
            let this = starknet::get_contract_address();
            assert(recipient != this, 'INVALID_ADDRESS');
            assert(!recipient.is_zero(), 'INVALID_ADDRESS');

            let caller = starknet::get_caller_address();
            UniswapExchangePrivateImpl::token_to_eth_input(
                ref self,
                tokens_sold, 
                min_eth, 
                deadline,
                caller,
                recipient
            )
        }



        fn token_to_eth_swap_output(
            ref self: ContractState,
            eth_bought: u256,
            max_tokens: u256,
            deadline: u256
        ) -> u256 {
            let caller = starknet::get_caller_address();
            UniswapExchangePrivateImpl::token_to_eth_output(
                ref self,
                eth_bought, 
                max_tokens, 
                deadline,
                caller,
                caller
            )
        }



        fn token_to_eth_transfer_output(
            ref self: ContractState,
            eth_bought: u256,
            max_tokens: u256,
            deadline: u256,
            recipient: ContractAddress
        ) -> u256 {
            let this = starknet::get_contract_address();
            assert(recipient != this, 'INVALID_ADDRESS');
            assert(!recipient.is_zero(), 'INVALID_ADDRESS');

            let caller = starknet::get_caller_address();
            UniswapExchangePrivateImpl::token_to_eth_output(
                ref self,
                eth_bought, 
                max_tokens, 
                deadline,
                caller,
                recipient
            )
        }


        fn token_to_token_swap_input(
            ref self: ContractState,
            tokens_sold: u256,
            min_tokens_bought: u256,
            min_eth_bought: u256,
            deadline: u256,
            token_addr: ContractAddress
        ) -> u256 {

            let factory = self.factory.read();
            let exchange_addr = factory.get_exchange(token_addr);

            let caller = starknet::get_caller_address();
            UniswapExchangePrivateImpl::token_to_token_input(
                ref self,
                tokens_sold, 
                min_tokens_bought, 
                min_eth_bought, 
                deadline,
                caller,
                caller,
                exchange_addr
            )
        }


        fn token_to_token_transfer_input(
            ref self: ContractState,
            tokens_sold: u256,
            min_tokens_bought: u256,
            min_eth_bought: u256,
            deadline: u256,
            recipient: ContractAddress,
            token_addr: ContractAddress
        ) -> u256 {

            let factory = self.factory.read();
            let exchange_addr = factory.get_exchange(token_addr);

            let caller = starknet::get_caller_address();
            UniswapExchangePrivateImpl::token_to_token_input(
                ref self,
                tokens_sold, 
                min_tokens_bought, 
                min_eth_bought, 
                deadline,
                caller,
                recipient,
                exchange_addr
            )
        }



        fn token_to_token_swap_output(
            ref self: ContractState,
            tokens_bought: u256,
            max_tokens_sold: u256,
            max_eth_sold: u256,
            deadline: u256,
            token_addr: ContractAddress
        ) -> u256 {

            let factory = self.factory.read();
            let exchange_addr = factory.get_exchange(token_addr);

            let caller = starknet::get_caller_address();
            UniswapExchangePrivateImpl::token_to_token_output(
                ref self,
                tokens_bought, 
                max_tokens_sold, 
                max_eth_sold, 
                deadline,
                caller,
                caller,
                exchange_addr
            )
        }


        fn token_to_token_transfer_output(
            ref self: ContractState,
            tokens_bought: u256,
            max_tokens_sold: u256,
            max_eth_sold: u256,
            deadline: u256,
            recipient: ContractAddress,
            token_addr: ContractAddress
        ) -> u256 {

            let factory = self.factory.read();
            let exchange_addr = factory.get_exchange(token_addr);

            let caller = starknet::get_caller_address();
            UniswapExchangePrivateImpl::token_to_token_output(
                ref self,
                tokens_bought, 
                max_tokens_sold, 
                max_eth_sold, 
                deadline,
                caller,
                recipient,
                exchange_addr
            )
        }



        fn token_to_exchange_swap_input(
            ref self: ContractState,
            tokens_sold: u256,
            min_tokens_bought: u256,
            min_eth_bought: u256,
            deadline: u256,
            exchange_addr: ContractAddress
        ) -> u256 {

            let caller = starknet::get_caller_address();
            UniswapExchangePrivateImpl::token_to_token_input(
                ref self,
                tokens_sold, 
                min_tokens_bought, 
                min_eth_bought, 
                deadline,
                caller,
                caller,
                exchange_addr
            )
        }


        fn token_to_exchange_transfer_input(
            ref self: ContractState,
            tokens_sold: u256,
            min_tokens_bought: u256,
            min_eth_bought: u256,
            deadline: u256,
            recipient: ContractAddress,
            exchange_addr: ContractAddress
        ) -> u256 {

            assert(recipient != starknet::get_contract_address(), 'INVALID_ADDRESS');

            let caller = starknet::get_caller_address();
            UniswapExchangePrivateImpl::token_to_token_input(
                ref self,
                tokens_sold, 
                min_tokens_bought, 
                min_eth_bought, 
                deadline,
                caller,
                recipient,
                exchange_addr
            )
        }



        fn token_to_exchange_swap_output(
            ref self: ContractState,
            tokens_bought: u256,
            max_tokens_sold: u256,
            max_eth_sold: u256,
            deadline: u256,
            exchange_addr: ContractAddress
        ) -> u256 {

            let caller = starknet::get_caller_address();
            UniswapExchangePrivateImpl::token_to_token_output(
                ref self,
                tokens_bought, 
                max_tokens_sold, 
                max_eth_sold, 
                deadline,
                caller,
                caller,
                exchange_addr
            )
        }


        fn token_to_exchange_transfer_output(
            ref self: ContractState,
            tokens_bought: u256,
            max_tokens_sold: u256,
            max_eth_sold: u256,
            deadline: u256,
            recipient: ContractAddress,
            exchange_addr: ContractAddress
        ) -> u256 {

            assert(recipient != starknet::get_contract_address(), 'INVALID_ADDRESS');

            let caller = starknet::get_caller_address();
            UniswapExchangePrivateImpl::token_to_token_output(
                ref self,
                tokens_bought, 
                max_tokens_sold, 
                max_eth_sold, 
                deadline,
                caller,
                recipient,
                exchange_addr
            )
        }


    //       //////////////////////////////////
    //       //         Getter Functions       
    //       //////////////////////////////////



        fn get_eth_to_token_input_price(self: @ContractState, eth_sold: u256) -> u256 {
            assert(eth_sold > 0 , 'INVALID_VALUE');
            
            let this = starknet::get_contract_address();
            let token = self.token.read();


            UniswapExchangeImpl::get_input_price(
                self,
                eth_sold, 
                self.ether_token_balance.read(), 
                token.balance_of(this)
            )
        }



        fn get_eth_to_token_output_price(self: @ContractState, tokens_bought: u256) -> u256 {
            assert(tokens_bought > 0 , 'INVALID_VALUE');
            let this = starknet::get_contract_address();
            let token = self.token.read();

            let eth_sold = UniswapExchangeImpl::get_output_price(
                self,
                tokens_bought, 
                self.ether_token_balance.read(), 
                token.balance_of(this)
            );

            eth_sold
        }



        fn get_token_to_eth_input_price(self: @ContractState, tokens_sold: u256) -> u256 {
            assert(tokens_sold > 0 , 'INVALID_VALUE');
            let this = starknet::get_contract_address();
            let token = self.token.read();

            let eth_bought = UniswapExchangeImpl::get_input_price(
                self,
                tokens_sold, 
                token.balance_of(this), 
                self.ether_token_balance.read()
            );

            eth_bought
        }



        fn get_token_to_eth_output_price(self: @ContractState, eth_bought: u256) -> u256 {
            assert(eth_bought > 0 , 'INVALID_VALUE');
            let this = starknet::get_contract_address();
            let token = self.token.read();

            UniswapExchangeImpl::get_output_price(
                self,
                eth_bought, 
                token.balance_of(this), 
                self.ether_token_balance.read()
            )
        }


        fn token_address(self: @ContractState) -> ContractAddress {
            let token = self.token.read();
            token.contract_address
        }


        fn factory_address(self: @ContractState) -> ContractAddress {
            let factory = self.factory.read();
            factory.contract_address
        }



         /////////////////////////////
         //   Liquidity Functions        
         /////////////////////////////



        fn add_liquidity(
            ref self: ContractState,
            value: u256,
            min_liquidity: u256, 
            max_tokens: u256,
            deadline: u256
        ) -> u256 {
            assert(deadline > get_block_timestamp().into() && max_tokens > 0 && value > 0, 'INVALID_ARGUMENT');
                
            let this = starknet::get_contract_address();
            let caller = starknet::get_caller_address();
            UniswapExchangePrivateImpl::_receive_ether(ref self,caller, value);

            let total_liquidity = UniswapERC20Impl::total_supply(@self);

            if (total_liquidity > 0) {

                assert(min_liquidity > 0,'MIN_LIQUIDITY MUST BE > 0');
                let token = self.token.read();

                let eth_reserve = self.ether_token_balance.read() - value;
                let token_reserve = token.balance_of(this);
                let token_amount = ((value * token_reserve) / eth_reserve) + 1;
                let liquidity_minted = (value * total_liquidity) / eth_reserve;

                assert(max_tokens >= token_amount && liquidity_minted >= min_liquidity,'');

        
                UniswapPrivateERC20Impl::_mint(caller, liquidity_minted);

                assert(token.transfer_from(caller, this, token_amount),'');

                self.emit(Event::AddLiquidity(AddLiquidity {
                    provider: caller,
                    eth_amount: value,
                    token_amount: token_amount
                }));


                liquidity_minted

            } else {

                let factory = self.factory.read();
                let token = self.token.read();

                assert(
                    factory.contract_address.is_non_zero()
                    && token.contract_address.is_non_zero() 
                    && value >= 1000000000, 
                    'INVALID_VALUE'
                );
                assert(factory.get_exchange(token.contract_address) == this,'');
                let token_amount = max_tokens;
                let initial_liquidity = self.ether_token_balance.read();

                UniswapPrivateERC20Impl::_mint(caller, initial_liquidity);

                assert(token.transfer_from(caller, this, token_amount),'');

                self.emit(Event::AddLiquidity(AddLiquidity {
                    provider: caller,
                    eth_amount: value,
                    token_amount: token_amount
                }));
                
                initial_liquidity

        }
        
    }



        fn remove_liquidity(
            ref self: ContractState,
            amount: u256,
            min_eth: u256, 
            min_tokens: u256,
            deadline: u256
        ) -> (u256, u256) {
            assert(amount > 0 && deadline > get_block_timestamp().into() && min_eth > 0 && min_tokens > 0,'');
            let this = starknet::get_contract_address();
            let caller = starknet::get_caller_address();

            let total_liquidity = UniswapERC20Impl::total_supply(@self);
            assert(total_liquidity > 0,'');

            let token = self.token.read();

            let token_reserve = token.balance_of(this);
            let eth_amount = (amount * self.ether_token_balance.read()) / total_liquidity;
            let token_amount = (amount * token_reserve) / total_liquidity;
            assert(eth_amount >= min_eth && token_amount >= min_tokens,'');

            UniswapPrivateERC20Impl::_burn(caller, amount);

            UniswapExchangePrivateImpl::_send_ether(ref self,caller, eth_amount);
            assert(token.transfer(caller, token_amount),'');

            self.emit(Event::RemoveLiquidity(RemoveLiquidity {
                provider: caller,
                eth_amount: eth_amount,
                token_amount: token_amount
            }));

            (eth_amount, token_amount)
        }
        
    }


    #[generate_trait]
    impl UniswapExchangePrivateImpl of UniswapExchangePrivateTrait{

        fn eth_to_token_input(
            ref self: ContractState,
            eth_sold: u256,
            min_tokens: u256,
            deadline: u256,
            buyer: ContractAddress,
            recipient: ContractAddress
        ) -> u256 {
            assert(deadline >= get_block_timestamp().into(), 'EXPIRED');
            assert(eth_sold > 0 && min_tokens > 0, 'INVALID_VALUE');

            let token = self.token.read();

            let token_reserve = token.balance_of(starknet::get_contract_address());
            let eth_reserve = self.ether_token_balance.read() - eth_sold;
            let tokens_bought = UniswapExchangeImpl::get_input_price(
                @self, 
                eth_sold, 
                eth_reserve, 
                token_reserve
            );
            assert(tokens_bought >= min_tokens, 'INSUFFICIENT_OUTPUT_AMOUNT');
            assert(token.transfer(recipient, tokens_bought), 'TRANSFER_FAILED');

            self.emit(Event::TokenPurchase(TokenPurchase {
                buyer: buyer,
                eth_sold: eth_sold,
                tokens_bought: tokens_bought
            }));

            tokens_bought
        }



        fn eth_to_token_output(
            ref self: ContractState,
            tokens_bought: u256,
            max_eth: u256,
            deadline: u256,
            buyer: ContractAddress,
            recipient: ContractAddress
        ) -> u256 {
            assert(deadline >= get_block_timestamp().into(), 'EXPIRED');
            assert(tokens_bought > 0 && max_eth > 0, 'INVALID_VALUE');

            let token = self.token.read();

            let this = starknet::get_contract_address();
            let token_reserve = token.balance_of(this);
            let ether_reserve = self.ether_token_balance.read();

            let eth_sold = UniswapExchangeImpl::get_output_price(
                @self, 
                tokens_bought, 
                ether_reserve - max_eth, 
                token_reserve
            );


            assert(eth_sold <= max_eth, 'INSUFFICIENT_INPUT_AMOUNT');
            let eth_refund = max_eth - eth_sold;
            if eth_refund > 0 {
                UniswapExchangePrivateImpl::_send_ether(ref self,buyer, eth_refund);
            }

            assert(token.transfer(recipient, tokens_bought), 'TRANSFER_FAILED');

            self.emit(Event::TokenPurchase(TokenPurchase {
                buyer: buyer,
                eth_sold: eth_sold,
                tokens_bought: tokens_bought
            }));

            eth_sold
        }


        fn token_to_eth_input(
            ref self: ContractState,
            tokens_sold: u256,
            min_eth: u256,
            deadline: u256,
            buyer: ContractAddress,
            recipient: ContractAddress
        ) -> u256 {
            assert(deadline >= get_block_timestamp().into(), 'EXPIRED');
            assert(tokens_sold > 0 && min_eth > 0, 'INVALID_VALUE');

            let token = self.token.read();

            let this = starknet::get_contract_address();
            let token_reserve = token.balance_of(this);
            let eth_reserve = self.ether_token_balance.read();

            let eth_bought = UniswapExchangeImpl::get_input_price(
                @self, 
                tokens_sold, 
                token_reserve, 
                eth_reserve
            );

            let wei_bought = eth_bought;
            assert(wei_bought >= min_eth, 'INSUFFICIENT_OUTPUT_AMOUNT');
            UniswapExchangePrivateImpl::_send_ether(ref self,recipient, wei_bought);
            assert(token.transfer_from(buyer, this, tokens_sold), 'TRANSFER_FROM_FAILED');

            self.emit(Event::EthPurchase(EthPurchase {
                buyer: buyer,
                tokens_sold: tokens_sold,
                eth_bought: wei_bought
            }));

            wei_bought
        }



        fn token_to_eth_output(
            ref self: ContractState,
            eth_bought: u256,
            max_tokens: u256,
            deadline: u256,
            buyer: ContractAddress,
            recipient: ContractAddress
        ) -> u256 {
            assert(deadline >= get_block_timestamp().into(), 'EXPIRED');
            assert(eth_bought > 0, 'INVALID_VALUE');

            let token = self.token.read();

            let this = starknet::get_contract_address();
            let tokens_sold = UniswapExchangeImpl::get_output_price(
                @self, 
                eth_bought, 
                token.balance_of(this), 
                self.ether_token_balance.read()
            );

            assert(max_tokens >= tokens_sold, 'INSUFFICIENT_INPUT_AMOUNT');
            UniswapExchangePrivateImpl::_send_ether(ref self,recipient, eth_bought);
            assert(token.transfer_from(buyer, this, tokens_sold), 'TRANSFER_FROM_FAILED');

            self.emit(Event::EthPurchase(EthPurchase {
                buyer: buyer,
                tokens_sold: tokens_sold,
                eth_bought: eth_bought
            }));

            tokens_sold
        }



        fn token_to_token_input(
            ref self: ContractState,
            tokens_sold: u256,
            min_tokens_bought: u256,
            min_eth_bought: u256,
            deadline: u256,
            buyer: ContractAddress,
            recipient: ContractAddress,
            exchange_addr: ContractAddress
        ) -> u256 {
            assert(deadline >= get_block_timestamp().into(), 'EXPIRED');
            assert(tokens_sold > 0 && min_tokens_bought > 0 && min_eth_bought > 0, 'INVALID_VALUE');

            let this = starknet::get_contract_address();
            assert(exchange_addr != this && !exchange_addr.is_zero(), 'INVALID_EXCHANGE_ADDRESS');

            let token = self.token.read();
            let ether_token = self.ether_token.read();

            let this = starknet::get_contract_address();
            let eth_bought = UniswapExchangeImpl::get_input_price(
                @self, 
                tokens_sold,
                token.balance_of(this), 
                self.ether_token_balance.read()
            );

            let wei_bought = eth_bought;
            assert(wei_bought >= min_eth_bought, 'INSUFFICIENT_OUTPUT_AMOUNT');
            assert(token.transfer_from(buyer, this, tokens_sold), 'TRANSFER_FROM_FAILED');

            assert(ether_token.approve(exchange_addr, wei_bought), 'APPROVE_FAILED');

            let tokens_bought = IUniswapExchangeDispatcher{
                contract_address: exchange_addr 
            }.eth_to_token_transfer_input( 
                wei_bought, 
                min_tokens_bought, 
                deadline, 
                recipient
            );

            self.emit(Event::EthPurchase(EthPurchase {
                buyer: buyer,
                tokens_sold: tokens_sold,
                eth_bought: wei_bought
            }));

            tokens_bought
        }





        fn token_to_token_output(
            ref self: ContractState,
            tokens_bought: u256,
            max_tokens_sold: u256,
            max_eth_sold: u256,
            deadline: u256,
            buyer: ContractAddress,
            recipient: ContractAddress,
            exchange_addr: ContractAddress 
        ) -> u256 {
            let this = starknet::get_contract_address();
            assert(deadline >= get_block_timestamp().into(), 'EXPIRED');
            assert(tokens_bought > 0 && max_eth_sold > 0, 'INVALID_VALUE');
            assert(exchange_addr != this && !exchange_addr.is_zero(), 'INVALID_EXCHANGE_ADDRESS');

            let exchange =  IUniswapExchangeDispatcher{
                contract_address: exchange_addr
            };
            let eth_bought = exchange.get_eth_to_token_output_price(tokens_bought);

            let token = self.token.read();
            let ether_token = self.ether_token.read();
            let tokens_sold = UniswapExchangeImpl::get_output_price(
                @self, 
                eth_bought, 
                token.balance_of(this), 
                self.ether_token_balance.read()
            );

            // tokens sold is always > 0

            assert(max_tokens_sold >= tokens_sold && max_eth_sold >= eth_bought,'');
            assert(token.transfer_from(buyer, this, tokens_sold), 'TRANSFER_FROM_FAILED');

            assert(ether_token.approve(exchange_addr, eth_bought), 'APPROVE_FAILED');
            let eth_sold = exchange.eth_to_token_transfer_output(
                eth_bought, 
                tokens_bought, 
                deadline, 
                recipient
            );

            self.emit(Event::EthPurchase(EthPurchase {
                buyer: buyer,
                tokens_sold: tokens_sold,
                eth_bought: eth_bought
            }));

            tokens_sold
        }


        #[inline(always)]
        fn _receive_ether(ref self: ContractState, from: ContractAddress, value: u256){
            let ether_token = self.ether_token.read();
            assert(ether_token.transfer_from(
                from, 
                starknet::get_contract_address(), 
                value
            ), 'ETH_TRANSFER_FROM_FAILED');

            self.ether_token_balance.write(
                self.ether_token_balance.read() + value
            );

        }

        #[inline(always)]
        fn _send_ether(ref self: ContractState, to: ContractAddress, value: u256){
            assert(self.ether_token.read().transfer(
                to, 
                value
            ), 'ETH_TRANSFER_FAILED');

            self.ether_token_balance.write(
                self.ether_token_balance.read() - value
            );
        }
    }


}