use starknet::ContractAddress;

#[starknet::interface]
trait IERC721<TContractState> {
    fn name(self: @TContractState) -> felt252;
    fn symbol(self: @TContractState) -> felt252;
    fn approve(ref self: TContractState, to: ContractAddress, token_id: u256);
    fn balance_of(self: @TContractState, account: ContractAddress) -> u256;
    fn owner_of(self: @TContractState, token_id: u256) -> ContractAddress;
    fn transfer_from(
        ref self: TContractState, from: ContractAddress, to: ContractAddress, token_id: u256
    );
    fn safe_transfer_from(
        ref self: TContractState,
        from: ContractAddress,
        to: ContractAddress,
        token_id: u256,
        data: Span<felt252>
    );
    fn set_approval_for_all(ref self: TContractState, operator: ContractAddress, approved: bool);
    fn get_approved(self: @TContractState, token_id: u256) -> ContractAddress;
    fn is_approved_for_all(
        self: @TContractState, owner: ContractAddress, operator: ContractAddress
    ) -> bool;
    fn token_uri(self: @TContractState, token_id: u256) -> felt252;
}


#[starknet::interface]
trait IERC721Burnable<TContractState> {
    fn burn(ref self: TContractState, token_id: u256);
}


#[starknet::interface]
trait IERC721Receiver<TContractState> {
    fn on_erc721_received(
        ref self: TContractState,
        operator: ContractAddress,
        from: ContractAddress,
        token_id: u256,
        data: Span<felt252>
    ) -> felt252;
}
