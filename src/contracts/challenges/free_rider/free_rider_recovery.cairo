use core::array::SpanTrait;

#[starknet::contract]
mod free_rider_recovery {

    use starknet::{
        ContractAddress,
        get_caller_address,
        get_contract_address
    };
    use damnvulnerabledefi::contracts::dependencies::external::token::erc721::IERC721::{
        IERC721, IERC721Dispatcher, IERC721DispatcherTrait, IERC721Receiver,
        IERC721_ID

    };
    use damnvulnerabledefi::contracts::dependencies::external::token::ERC20::{
        IERC20Dispatcher, IERC20DispatcherTrait
    };
    use damnvulnerabledefi::contracts::dependencies::external::security::reentrancy_guard::{
        IReentrancyGuard, reentrancy_guard
    };
    use damnvulnerabledefi::contracts::dependencies::external::security::reentrancy_guard::reentrancy_guard::{
        ReentrancyGuard
    };

    use array::{ArrayTrait, SpanTrait};
    use traits::TryInto;
    use option::OptionTrait;

    const PRIZE: u256 = 45_000_000_000_000_000_000; // 45e18 == 45 ETH

    #[storage]
    struct Storage {
        beneficiary: ContractAddress,
        nft: IERC721Dispatcher,
        received: u256,

        ether_token: IERC20Dispatcher
    }


    #[constructor]
    fn constructor(
        ref self: ContractState,
        _beneficiary: ContractAddress, 
        _nft_address: ContractAddress,
        _ether_token_address: ContractAddress,

    ) {
        self.ether_token.write(
            IERC20Dispatcher { 
                contract_address: 
                _ether_token_address 
            }
        );

        let caller = get_caller_address();
        EtherTransferImpl::receive_ether(
            ref self,
            caller,
            PRIZE
        );

        self.beneficiary.write(_beneficiary);


        let nft = IERC721Dispatcher {
            contract_address: _nft_address
        };
        self.nft.write(nft);

        nft.set_approval_for_all(
             caller,
             true
        );    
    }    


    #[generate_trait]
    impl EtherTransferImpl of EtherTransferTrait {
        
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

    impl FreeRiderReentrancyGuard of IReentrancyGuard<ContractState> {
        fn start(ref self: ContractState) {
            let mut state = reentrancy_guard::unsafe_new_contract_state();
            ReentrancyGuard::start(ref state);
        }

        fn end(ref self: ContractState) {
            let mut state = reentrancy_guard::unsafe_new_contract_state();
            ReentrancyGuard::end(ref state);
        }
    }


    #[external(v0)]
    impl ERC721ReceiverImpl of IERC721Receiver<ContractState> {

        // Read https://eips.ethereum.org/EIPS/eip-721 for more info on this function
        fn on_erc721_received(
            ref self: ContractState,
            operator: ContractAddress,
            from: ContractAddress,
            token_id: u256,
            data: Span<felt252>
        ) -> felt252 {
            FreeRiderReentrancyGuard::start(ref self);

            let nft = self.nft.read();
            assert(
                operator == nft.contract_address,
                'CallerNotNFT'
            );

            assert(
                from == self.beneficiary.read(),
                'SenderNotBeneficiary'
            );

            assert(
                token_id <= 5,
                'InvalidTokenID'
            );

            assert(
                nft.owner_of(token_id) == get_contract_address(),
                'StillNotOwningToken'
            );

            let received = self.received.read() + 1;
            self.received.write(received);

            if (received == 6) {
                let recipient: ContractAddress = (*data.at(0)).try_into().unwrap();
                EtherTransferImpl::send_ether(ref self, recipient, PRIZE);
            }

            FreeRiderReentrancyGuard::end(ref self);

            IERC721_ID
            
        }
        
    }
}