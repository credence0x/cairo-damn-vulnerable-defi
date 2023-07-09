// #[starknet::contract]
// mod damn_valuable_token {
//     use starknet::{ get_caller_address, get_contract_address, ContractAddress};
//     use damnvulnerabledefi::contracts::dependencies::external::token::ERC20::ERC20;
//     use damnvulnerabledefi::contracts::dependencies::external::token::ERC20::{
//         IERC20Dispatcher,IERC20DispatcherTrait
//     };


//     #[storage]
//     struct Storage {
//         token: ERC20::ContractState
//     }


//     #[constructor]
//     fn constructor(ref self: ContractState) {
//         self.token.write(ERC20::unsafe_new_contract_state());
//     }
// }

