
#[starknet::interface]
trait IMarketplace<TContractState> {
    fn offer_many(
        ref self: TContractState,
        token_ids: Span<u256>,
        prices: Span<u256>
    );

    fn buy_many(
        ref self: TContractState,
        value: u256,
        token_ids: Span<u256>
    );
}


#[starknet::contract]
mod free_rider_nft_marketplace {
    use starknet::ClassHash;
    use result::ResultTrait;
    use damnvulnerabledefi::contracts::dependencies::internal::token::damn_valuable_nft::{
        damn_valuable_nft, IERC721SafeMint, IERC721SafeMintDispatcher, IERC721SafeMintDispatcherTrait
    };
    use damnvulnerabledefi::contracts::dependencies::external::token::erc721::IERC721::{
        IERC721, IERC721Dispatcher, IERC721DispatcherTrait,  
    };
    use damnvulnerabledefi::contracts::dependencies::external::token::ERC20::{
        IERC20Dispatcher, IERC20DispatcherTrait
    };
    
    use damnvulnerabledefi::contracts::dependencies::external::access::ownable::{
        IOwnable, IOwnableDispatcher, IOwnableDispatcherTrait
    };
    use damnvulnerabledefi::contracts::dependencies::external::security::reentrancy_guard::{
        IReentrancyGuard, reentrancy_guard
    };
    use damnvulnerabledefi::contracts::dependencies::external::security::reentrancy_guard::reentrancy_guard::{
        ReentrancyGuard
    };
    use starknet::syscalls::deploy_syscall;
    use array::{ArrayTrait, SpanTrait};
    use starknet::ContractAddress;

    #[storage]
    struct Storage {
        token : IERC721Dispatcher,
        offers_count: u256,
        // token_id -> price
        offers: LegacyMap::<u256, u256>,

        ether_token: IERC20Dispatcher

    }


    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        NFTOffered: NFTOffered,
        NFTBought: NFTBought
    }

    #[derive(Drop, starknet::Event)]
    struct NFTOffered {
        offerer: ContractAddress,
        token_id: u256,
        price: u256
    }

    #[derive(Drop, starknet::Event)]
    struct NFTBought {
        buyer: ContractAddress,
        token_id: u256,
        price: u256
    }

    

    #[constructor]
    fn constructor(
        ref self: ContractState, 
        token_class_hash: ClassHash, 
        ether_token_address: ContractAddress,
        amount: u256
        ) {
        self.ether_token.write(
            IERC20Dispatcher { contract_address: ether_token_address }
        );


        let calldata = Default::default();
        let (token_address, _) = deploy_syscall(
            token_class_hash, 0, calldata.span(), false
        ).unwrap();

        IOwnableDispatcher{
            contract_address: token_address,
        }.renounce_ownership();

        let token = IERC721SafeMintDispatcher{
            contract_address: token_address,
        };

        let caller = starknet::get_caller_address();
        let count = 0;
        loop {
            if count == amount {
                break;
            }
            token.safe_mint(caller);
        };

        self.token.write(IERC721Dispatcher{
            contract_address: token_address,
        });
    }


    impl MarketplaceReentrancyGuard of IReentrancyGuard<ContractState> {
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
    impl MarketplaceMoneyImpl of MarketplaceMoneyTrait {
        
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
    impl MarketplaceImpl of super::IMarketplace<ContractState>{
        fn offer_many(
            ref self :ContractState,
            token_ids: Span<u256>,
            prices: Span<u256>
        ){
            MarketplaceReentrancyGuard::start(ref self);

            let mut amount = token_ids.len();
            assert(amount > 0, 'INVALID_TOKENS_AMOUNT');
            assert(amount == prices.len(), 'INVALID_PRICES_AMOUNT');
            
            let mut count = 0;
            loop {
                if count == amount {
                    break;
                }
                let token_id = *token_ids.at(count);
                let price = *prices.at(count);
                InternalMarketplaceImpl::_offer_one(ref self, token_id, price);
                count += 1;
            };

            MarketplaceReentrancyGuard::end(ref self);

        }


        fn buy_many(
            ref self :ContractState,
            value: u256,
            token_ids: Span<u256>
        ){
            MarketplaceReentrancyGuard::start(ref self);
            

            let caller = starknet::get_caller_address();
            MarketplaceMoneyImpl::receive_ether(
                ref self, caller, value
            );


            let mut amount = token_ids.len();
            let mut count = 0;
            loop {
                if count == amount {
                    break;
                }
                let token_id = *token_ids.at(count);
                InternalMarketplaceImpl::_buy_one(ref self, value, token_id);
                count += 1;
            };

            MarketplaceReentrancyGuard::end(ref self);

        }

    }



    #[external(v0)]
    #[generate_trait]
    impl InternalMarketplaceImpl of InternalMarketplaceTrait {
            
        fn _offer_one(
            ref self: ContractState,
            token_id: u256,
            price: u256
        ){
            let token = self.token.read();
            let caller = starknet::get_caller_address();
            let this = starknet::get_contract_address();

            assert(price > 0, 'INVALID_PRICE');

            let owner = token.owner_of(token_id);
            assert(caller == owner, 'CALLER_NOT_OWNER');
            
            if token.get_approved(token_id) != this {
                assert(
                    token.is_approved_for_all(caller, this), 
                    'INVALID_APPROVAL'
                );
            }

            self.offers.write(token_id, price);
            self.offers_count.write(self.offers_count.read() + 1);

            self.emit(Event::NFTOffered(NFTOffered{
                offerer: caller,
                token_id: token_id,
                price: price
            }));
        }
        



        fn _buy_one(
            ref self: ContractState,
            value: u256,
            token_id: u256
        ){
            let price_to_pay = self.offers.read(token_id);
            assert(price_to_pay > 0, 'TOKEN_NOT_OFFERED');


            assert(value >= price_to_pay, 'INSUFFICIENT_PAYMENT');

            self.offers_count.write(self.offers_count.read() - 1);

            // transfer from seller to buyer
            let caller = starknet::get_caller_address();
            let token = self.token.read();
            token.safe_transfer_from(
                token.owner_of(token_id), 
                caller, 
                token_id,
                ArrayTrait::new().span()
            );

            // pay seller using cached token
            MarketplaceMoneyImpl::send_ether(
                ref self, 
                token.owner_of(token_id), 
                price_to_pay
            );

            self.emit(Event::NFTBought(NFTBought{
                buyer: caller,
                token_id: token_id,
                price: price_to_pay
            }));

        }
    }


}