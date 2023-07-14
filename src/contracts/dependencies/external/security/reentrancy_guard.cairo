#[starknet::interface]
trait IReentrancyGuard<TContractState> {
    fn start(ref self: TContractState);
    fn end(ref self: TContractState);
}

#[starknet::contract]
mod reentrancy_guard {
    #[storage]
    struct Storage {
        entered: bool
    }

    #[external(v0)]
    impl ReentrancyGuard of super::IReentrancyGuard<ContractState> {
        fn start(ref self: ContractState) {
            assert(!self.entered.read(), 'ReentrancyGuard: reentrant call');
            self.entered.write(true);
        }

        fn end(ref self: ContractState) {
            self.entered.write(false);
        }
    }
}
