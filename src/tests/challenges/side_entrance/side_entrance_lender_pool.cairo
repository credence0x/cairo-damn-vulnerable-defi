#[cfg(test)]
mod test_side_entrance_lender_pool {
    use array::ArrayTrait;
    use result::ResultTrait;
    use test::test_utils::assert_eq;
    use traits::TryInto;
    use starknet::contract_address::ContractAddress;
    use option::OptionTrait;
    use integer::BoundedInt;
    use starknet::syscalls::deploy_syscall;
    use damnvulnerabledefi::tests::utils::constants::DEPLOYER;
    use damnvulnerabledefi::tests::utils::helpers::{call_contracts_as, to_wad};
    use damnvulnerabledefi::contracts::challenges::side_entrance::side_entrance_lender_pool::{
        side_entrance_lender_pool, ISideEntranceLenderPoolDispatcher, IFlashLoanEtherReceiver
    };
    use damnvulnerabledefi::contracts::dependencies::external::token::ERC20::{
        ERC20, IERC20Dispatcher, IERC20DispatcherTrait
    };


    ////////////////////////////
    // Player contract
    ////////////////////////////

    #[starknet::interface]
    trait IPlayer<TContractState> {
        fn play(ref self: TContractState);
    }

    #[starknet::contract]
    mod player {
        use super::{IERC20Dispatcher, IERC20DispatcherTrait};
        use damnvulnerabledefi::contracts::challenges::side_entrance::side_entrance_lender_pool::{
            ISideEntranceLenderPoolDispatcher, ISideEntranceLenderPoolDispatcherTrait,
            IFlashLoanEtherReceiver
        };

        #[storage]
        struct Storage {
            ether_token: IERC20Dispatcher,
            side_pool: ISideEntranceLenderPoolDispatcher
        }

        #[constructor]
        fn constructor(
            ref self: ContractState,
            ether_token: IERC20Dispatcher,
            side_pool: ISideEntranceLenderPoolDispatcher
        ) {
            self.ether_token.write(ether_token);
            self.side_pool.write(side_pool);
        }

        #[external(v0)]
        impl FlashLoanReceiver of IFlashLoanEtherReceiver<ContractState> {
            fn execute(self: @ContractState, token: IERC20Dispatcher, amount: u256) {}
        }

        #[external(v0)]
        impl Player of super::IPlayer<ContractState> {
            fn play(ref self: ContractState) { //
            //////////////////////////
            // YOUR EXPLOIT GOES HERE
            //////////////////////////
            }
        }
    }


    #[test]
    #[available_gas(30000000)]
    fn exploit() {
        /// NO NEED TO CHANGE ANYTHING HERE 

        let (ether_token, side_pool) = __setup_contracts();
        let player = __setup_player(ether_token, side_pool);
        __fund_pool(ether_token, side_pool);

        player.play();

        __check_solution(player.contract_address, ether_token, side_pool);
    }


    fn __setup_contracts() -> (IERC20Dispatcher, ISideEntranceLenderPoolDispatcher) {
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

        let (address_ether_token, _) = deploy_syscall(
            ERC20::TEST_CLASS_HASH.try_into().unwrap(), 0, calldata.span(), false
        )
            .unwrap();
        let mut ether_token = IERC20Dispatcher { contract_address: address_ether_token };

        ////////////////////////////////////
        // Deploy Side Entrance Lender Pool
        ////////////////////////////////////
        let mut calldata = Default::default();
        Serde::<ContractAddress>::serialize(@address_ether_token, ref calldata);

        let (address_side_pool, _) = deploy_syscall(
            side_entrance_lender_pool::TEST_CLASS_HASH.try_into().unwrap(),
            0,
            calldata.span(),
            false
        )
            .unwrap();
        let side_pool = ISideEntranceLenderPoolDispatcher { contract_address: address_side_pool };

        (ether_token, side_pool)
    }

    fn __setup_player(
        ether_token: IERC20Dispatcher, side_pool: ISideEntranceLenderPoolDispatcher
    ) -> IPlayerDispatcher {
        ////////////////////////////////////
        // Deploy player contract
        ////////////////////////////////////
        let mut calldata = Default::default();
        Serde::<IERC20Dispatcher>::serialize(@ether_token, ref calldata);
        Serde::<ISideEntranceLenderPoolDispatcher>::serialize(@side_pool, ref calldata);

        let (address_player, _) = deploy_syscall(
            player::TEST_CLASS_HASH.try_into().unwrap(), 0, calldata.span(), false
        )
            .unwrap();

        IPlayerDispatcher { contract_address: address_player }
    }

    fn __ether_in_pool() -> u256 {
        to_wad(1000) // 1000 Ether
    }

    fn __fund_pool(ether_token: IERC20Dispatcher, side_pool: ISideEntranceLenderPoolDispatcher) {
        call_contracts_as(DEPLOYER());
        ether_token.transfer(side_pool.contract_address, __ether_in_pool());
    }

    fn __check_solution(
        address_player: ContractAddress,
        ether_token: IERC20Dispatcher,
        side_pool: ISideEntranceLenderPoolDispatcher
    ) {
        assert_eq(
            @ether_token.balance_of(address_player),
            @__ether_in_pool(),
            'Player should have 1000 Ether'
        );

        assert_eq(
            @ether_token.balance_of(side_pool.contract_address), @0, 'Pool should have 0 Ether'
        );
    }
}
