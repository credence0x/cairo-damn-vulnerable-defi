#[starknet::interface]
trait IERC165<TContractState> {
    fn supports_interface(self: @TContractState, interface_id: felt252) -> bool;
}

const IERC165_ID: felt252 = 0x3f918d17e5ee77373b56385708f855659a07f75997f365cf87748628532a055;

