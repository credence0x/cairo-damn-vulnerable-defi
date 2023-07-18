#[starknet::interface]
trait IERC165<TContractState> {
    fn supports_interface(self: @TContractState, interface_id: felt252) -> bool;
}
