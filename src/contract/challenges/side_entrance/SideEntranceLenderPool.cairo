#[starknet::interface]
trait IFlashLoanEtherReceiver<TContractState> {
    fn execute(ref self: TContractState, amount: u256);
}

#[starknet::interface]
trait ISideEntranceLenderPool<TContractState> {
    fn deposit(ref self: TContractState, amount: u256);
    fn withdraw(ref self: TContractState);
    fn flash_loan(ref self: TContractState, amount: u256);
}


#[starknet::contract]
mod SideEntranceLenderPool {
    use starknet::{get_caller_address,get_contract_address,ContractAddress};
    use damnvulnerabledefi::contract::dependencies::token::ERC20::{
        IERC20Dispatcher,IERC20DispatcherTrait
    };
    use super::{IFlashLoanEtherReceiverDispatcher,IFlashLoanEtherReceiverDispatcherTrait};

    
    #[storage]
    struct Storage {
        balances: LegacyMap::<ContractAddress, u256>, 
        damnValuableToken: IERC20Dispatcher
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Deposit: Deposit,
        Withdraw: Withdraw
    }

    #[derive(Drop, starknet::Event)]
    struct Deposit {
        who: ContractAddress,
        amount: u256
    }

    #[derive(Drop, starknet::Event)]
    struct Withdraw {
        who: ContractAddress,
        amount: u256
    }

    #[constructor]
    fn constructor(
        ref self: ContractState, 
        _damnValuableToken: ContractAddress
    ) {
        self.damnValuableToken.write(IERC20Dispatcher{
             contract_address: _damnValuableToken
        });
    }

   

    #[external(v0)]
    impl SideEntranceLenderPool of super::ISideEntranceLenderPool<ContractState> {
        fn deposit(ref self: ContractState, amount: u256) {
            assert(amount > 0, 'Amount cannot be 0');

            let caller = get_caller_address();
            self.balances.write(caller, self.balances.read(caller) + amount);
        
            self.emit(Event::Deposit(Deposit {who:caller, amount }));
        }

        fn withdraw(ref self: ContractState) {
            let caller = get_caller_address();
            let amount = self.balances.read(caller);

            assert(amount > 0, 'Balance cannot be 0');

            self.balances.write(caller, 0);

            let token: IERC20Dispatcher = self.damnValuableToken.read();
            token.transfer(caller, amount);

            self.emit(Event::Withdraw(Withdraw{who:caller, amount }));
        }


        fn flash_loan(ref self: ContractState, amount: u256) {
            let token: IERC20Dispatcher = self.damnValuableToken.read();
            let this = get_contract_address();
            let balance_before = token.balance_of(this);

            IFlashLoanEtherReceiverDispatcher{
                contract_address:get_caller_address()
            }.execute(amount);

            assert(
                token.balance_of(this) >= balance_before,
                 'RepayFailed'
            ); 

        }
    
    }

}

