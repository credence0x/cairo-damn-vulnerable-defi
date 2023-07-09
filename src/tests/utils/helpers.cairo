fn call_contracts_as(to: starknet::ContractAddress) {
  starknet::testing::set_contract_address(
            to
  );
}

fn to_wad(amount: u256) -> u256 {
  // a wad is a decimal number
  // with 18 digits of precision. 
  amount * 1_000_000_000_000_000_000
}