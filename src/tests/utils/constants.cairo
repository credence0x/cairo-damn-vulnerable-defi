fn DEPLOYER() -> starknet::ContractAddress {
    starknet::contract_address_const::<'deployer'>()
}

fn RECEIVER() -> starknet::ContractAddress {
    starknet::contract_address_const::<'receiver'>()
}
