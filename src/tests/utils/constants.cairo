fn DEPLOYER() -> starknet::ContractAddress {
  starknet::contract_address_const::<'deployer'>()
}