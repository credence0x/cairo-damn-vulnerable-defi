use starknet::{ContractAddress, ClassHash};
use damnvulnerabledefi::contracts::dependencies::external::token::ERC20::IERC20Dispatcher;

#[starknet::interface]
trait IUniswapExchange<TContractState> {
    fn setup(
        ref self: TContractState, token_addr: ContractAddress, ether_token_addr: ContractAddress
    );

    /// @dev Pricing function for converting between ETH && Tokens.
    /// @param input_amount Amount of ETH or Tokens being sold.
    /// @param input_reserve Amount of ETH or Tokens (input type) in exchange reserves.
    /// @param output_reserve Amount of ETH or Tokens (output type) in exchange reserves.
    /// @return Amount of ETH or Tokens bought.
    fn get_input_price(
        self: @TContractState, input_amount: u256, input_reserve: u256, output_reserve: u256
    ) -> u256;

    /// @dev Pricing function for converting between ETH && Tokens.
    /// @param output_amount Amount of ETH or Tokens being bought.
    /// @param input_reserve Amount of ETH or Tokens (input type) in exchange reserves.
    /// @param output_reserve Amount of ETH or Tokens (output type) in exchange reserves.
    /// @return Amount of ETH or Tokens sold.
    fn get_output_price(
        self: @TContractState, output_amount: u256, input_reserve: u256, output_reserve: u256
    ) -> u256;

    /// @notice Convert ETH to Tokens.
    /// @dev User specifies exact input (msg.value) && minimum output.
    /// @param min_tokens Minimum Tokens bought.
    /// @param deadline Time after which this transaction can no longer be executed.
    /// @return Amount of Tokens bought.
    fn eth_to_token_swap_input(
        ref self: TContractState, value: u256, min_tokens: u256, deadline: u256
    ) -> u256;

    /// @notice Convert ETH to Tokens && transfers Tokens to recipient.
    /// @dev User specifies exact input (msg.value) && minimum output
    /// @param min_tokens Minimum Tokens bought.
    /// @param deadline Time after which this transaction can no longer be executed.
    /// @param recipient The address that receives output Tokens.
    /// @return  Amount of Tokens bought.
    fn eth_to_token_transfer_input(
        ref self: TContractState,
        value: u256,
        min_tokens: u256,
        deadline: u256,
        recipient: ContractAddress
    ) -> u256;

    /// @notice Convert ETH to Tokens.
    /// @dev User specifies maximum input (msg.value) && exact output.
    /// @param tokens_bought Amount of tokens bought.
    /// @param deadline Time after which this transaction can no longer be executed.
    /// @return Amount of ETH sold.
    fn eth_to_token_swap_output(
        ref self: TContractState, value: u256, tokens_bought: u256, deadline: u256
    ) -> u256;

    /// @notice Convert ETH to Tokens && transfers Tokens to recipient.
    /// @dev User specifies maximum input (msg.value) && exact output.
    /// @param tokens_bought Amount of tokens bought.
    /// @param deadline Time after which this transaction can no longer be executed.
    /// @param recipient The address that receives output Tokens.
    /// @return Amount of ETH sold.
    fn eth_to_token_transfer_output(
        ref self: TContractState,
        value: u256,
        tokens_bought: u256,
        deadline: u256,
        recipient: ContractAddress
    ) -> u256;

    /// @notice Convert Tokens to ETH. 
    /// @dev User specifies exact input && minimum output.
    /// @param tokens_sold Amount of Tokens sold.
    /// @param min_eth Minimum ETH purchased.
    /// @param deadline Time after which this transaction can no longer be executed.
    /// @return Amount of ETH bought.
    fn token_to_eth_swap_input(
        ref self: TContractState, tokens_sold: u256, min_eth: u256, deadline: u256
    ) -> u256;

    /// @notice Convert Tokens to ETH && transfers ETH to recipient.
    /// @dev User specifies exact input && minimum output.
    /// @param tokens_sold Amount of Tokens sold.
    /// @param min_eth Minimum ETH purchased.
    /// @param deadline Time after which this transaction can no longer be executed.
    /// @param recipient The address that receives output ETH.
    /// @return  Amount of ETH bought.
    fn token_to_eth_transfer_input(
        ref self: TContractState,
        tokens_sold: u256,
        min_eth: u256,
        deadline: u256,
        recipient: ContractAddress
    ) -> u256;

    /// @notice Convert Tokens to ETH.
    /// @dev User specifies maximum input && exact output.
    /// @param eth_bought Amount of ETH purchased.
    /// @param max_tokens Maximum Tokens sold.
    /// @param deadline Time after which this transaction can no longer be executed.
    /// @return Amount of Tokens sold.
    fn token_to_eth_swap_output(
        ref self: TContractState, eth_bought: u256, max_tokens: u256, deadline: u256
    ) -> u256;

    /// @notice Convert Tokens to ETH && transfers ETH to recipient.
    /// @dev User specifies maximum input && exact output.
    /// @param eth_bought Amount of ETH purchased.
    /// @param max_tokens Maximum Tokens sold.
    /// @param deadline Time after which this transaction can no longer be executed.
    /// @param recipient The address that receives output ETH.
    /// @return Amount of Tokens sold.
    fn token_to_eth_transfer_output(
        ref self: TContractState,
        eth_bought: u256,
        max_tokens: u256,
        deadline: u256,
        recipient: ContractAddress
    ) -> u256;

    /// @notice Convert Tokens (token) to Tokens (token_addr).
    /// @dev User specifies exact input && minimum output.
    /// @param tokens_sold Amount of Tokens sold.
    /// @param min_tokens_bought Minimum Tokens (token_addr) purchased.
    /// @param min_eth_bought Minimum ETH purchased as intermediary.
    /// @param deadline Time after which this transaction can no longer be executed.
    /// @param token_addr The address of the token being purchased.
    /// @return Amount of Tokens (token_addr) bought.
    fn token_to_token_swap_input(
        ref self: TContractState,
        tokens_sold: u256,
        min_tokens_bought: u256,
        min_eth_bought: u256,
        deadline: u256,
        token_addr: ContractAddress
    ) -> u256;

    /// @notice Convert Tokens (token) to Tokens (token_addr) && transfers
    ///         Tokens (token_addr) to recipient.
    /// @dev User specifies exact input && minimum output.
    /// @param tokens_sold Amount of Tokens sold.
    /// @param min_tokens_bought Minimum Tokens (token_addr) purchased.
    /// @param min_eth_bought Minimum ETH purchased as intermediary.
    /// @param deadline Time after which this transaction can no longer be executed.
    /// @param recipient The address that receives output ETH.
    /// @param token_addr The address of the token being purchased.
    /// @return Amount of Tokens (token_addr) bought.
    fn token_to_token_transfer_input(
        ref self: TContractState,
        tokens_sold: u256,
        min_tokens_bought: u256,
        min_eth_bought: u256,
        deadline: u256,
        recipient: ContractAddress,
        token_addr: ContractAddress
    ) -> u256;

    /// @notice Convert Tokens (token) to Tokens (token_addr).
    /// @dev User specifies maximum input && exact output.
    /// @param tokens_bought Amount of Tokens (token_addr) bought.
    /// @param max_tokens_sold Maximum Tokens (token) sold.
    /// @param max_eth_sold Maximum ETH purchased as intermediary.
    /// @param deadline Time after which this transaction can no longer be executed.
    /// @param token_addr The address of the token being purchased.
    /// @return Amount of Tokens (token) sold.
    fn token_to_token_swap_output(
        ref self: TContractState,
        tokens_bought: u256,
        max_tokens_sold: u256,
        max_eth_sold: u256,
        deadline: u256,
        token_addr: ContractAddress
    ) -> u256;

    /// @notice Convert Tokens (token) to Tokens (token_addr) && transfers
    ///         Tokens (token_addr) to recipient.
    /// @dev User specifies maximum input && exact output.
    /// @param tokens_bought Amount of Tokens (token_addr) bought.
    /// @param max_tokens_sold Maximum Tokens (token) sold.
    /// @param max_eth_sold Maximum ETH purchased as intermediary.
    /// @param deadline Time after which this transaction can no longer be executed.
    /// @param recipient The address that receives output ETH.
    /// @param token_addr The address of the token being purchased.
    /// @return Amount of Tokens (token) sold.
    fn token_to_token_transfer_output(
        ref self: TContractState,
        tokens_bought: u256,
        max_tokens_sold: u256,
        max_eth_sold: u256,
        deadline: u256,
        recipient: ContractAddress,
        token_addr: ContractAddress
    ) -> u256;

    /// @notice Convert Tokens (token) to Tokens (exchange_addr.token).
    /// @dev Allows trades through contracts that were not deployed from the same factory.
    /// @dev User specifies exact input && minimum output.
    /// @param tokens_sold Amount of Tokens sold.
    /// @param min_tokens_bought Minimum Tokens (token_addr) purchased.
    /// @param min_eth_bought Minimum ETH purchased as intermediary.
    /// @param deadline Time after which this transaction can no longer be executed.
    /// @param exchange_addr The address of the exchange for the token being purchased.
    /// @return Amount of Tokens (exchange_addr.token) bought.
    fn token_to_exchange_swap_input(
        ref self: TContractState,
        tokens_sold: u256,
        min_tokens_bought: u256,
        min_eth_bought: u256,
        deadline: u256,
        exchange_addr: ContractAddress
    ) -> u256;

    /// @notice Convert Tokens (token) to Tokens (exchange_addr.token) && transfers
    ///         Tokens (exchange_addr.token) to recipient.
    /// @dev Allows trades through contracts that were not deployed from the same factory.
    /// @dev User specifies exact input && minimum output.
    /// @param tokens_sold Amount of Tokens sold.
    /// @param min_tokens_bought Minimum Tokens (token_addr) purchased.
    /// @param min_eth_bought Minimum ETH purchased as intermediary.
    /// @param deadline Time after which this transaction can no longer be executed.
    /// @param recipient The address that receives output ETH.
    /// @param exchange_addr The address of the exchange for the token being purchased.
    /// @return Amount of Tokens (exchange_addr.token) bought.
    fn token_to_exchange_transfer_input(
        ref self: TContractState,
        tokens_sold: u256,
        min_tokens_bought: u256,
        min_eth_bought: u256,
        deadline: u256,
        recipient: ContractAddress,
        exchange_addr: ContractAddress
    ) -> u256;

    /// @notice Convert Tokens (token) to Tokens (exchange_addr.token).
    /// @dev Allows trades through contracts that were not deployed from the same factory.
    /// @dev User specifies maximum input && exact output.
    /// @param tokens_bought Amount of Tokens (token_addr) bought.
    /// @param max_tokens_sold Maximum Tokens (token) sold.
    /// @param max_eth_sold Maximum ETH purchased as intermediary.
    /// @param deadline Time after which this transaction can no longer be executed.
    /// @param exchange_addr The address of the exchange for the token being purchased.
    /// @return Amount of Tokens (token) sold.
    fn token_to_exchange_swap_output(
        ref self: TContractState,
        tokens_bought: u256,
        max_tokens_sold: u256,
        max_eth_sold: u256,
        deadline: u256,
        exchange_addr: ContractAddress
    ) -> u256;

    /// @notice Convert Tokens (token) to Tokens (exchange_addr.token) && transfers
    ///         Tokens (exchange_addr.token) to recipient.
    /// @dev Allows trades through contracts that were not deployed from the same factory.
    /// @dev User specifies maximum input && exact output.
    /// @param tokens_bought Amount of Tokens (token_addr) bought.
    /// @param max_tokens_sold Maximum Tokens (token) sold.
    /// @param max_eth_sold Maximum ETH purchased as intermediary.
    /// @param deadline Time after which this transaction can no longer be executed.
    /// @param recipient The address that receives output ETH.
    /// @param exchange_addr The address of the exchange for the token being purchased.
    /// @return Amount of Tokens (token) sold.
    fn token_to_exchange_transfer_output(
        ref self: TContractState,
        tokens_bought: u256,
        max_tokens_sold: u256,
        max_eth_sold: u256,
        deadline: u256,
        recipient: ContractAddress,
        exchange_addr: ContractAddress
    ) -> u256;

    /// @notice external price function for ETH to Token trades with an exact input.
    /// @param eth_sold Amount of ETH sold.
    /// @return Amount of Tokens that can be bought with input ETH.
    fn get_eth_to_token_input_price(self: @TContractState, eth_sold: u256) -> u256;

    /// @notice external price function for ETH to Token trades with an exact output.
    /// @param tokens_bought Amount of Tokens bought.
    /// @return Amount of ETH needed to buy output Tokens.
    fn get_eth_to_token_output_price(self: @TContractState, tokens_bought: u256) -> u256;

    /// @notice external price function for Token to ETH trades with an exact input.
    /// @param tokens_sold Amount of Tokens sold.
    /// @return Amount of ETH that can be bought with input Tokens.
    fn get_token_to_eth_input_price(self: @TContractState, tokens_sold: u256) -> u256;


    /// @notice external price function for Token to ETH trades with an exact output.
    /// @param eth_bought Amount of output ETH.
    /// @return Amount of Tokens needed to buy output ETH.
    fn get_token_to_eth_output_price(self: @TContractState, eth_bought: u256) -> u256;

    /// @return Address of Token that is sold on this exchange.
    fn token_address(self: @TContractState) -> ContractAddress;

    /// @return Address of factory that created this exchange.
    fn factory_address(self: @TContractState) -> ContractAddress;


    // /***********************************|
    // |        Liquidity Functions        |
    // |__________________________________*/

    /// @notice Deposit ETH && Tokens (token) at current ratio to mint UNI tokens.
    /// @dev min_liquidity does nothing when total UNI supply is 0.
    /// @param min_liquidity Minimum number of UNI sender will mint if total UNI supply is greater than 0.
    /// @param max_tokens Maximum number of tokens deposited. Deposits max amount if total UNI supply is 0.
    /// @param deadline Time after which this transaction can no longer be executed.
    /// @return The amount of UNI minted.
    fn add_liquidity(
        ref self: TContractState, value: u256, min_liquidity: u256, max_tokens: u256, deadline: u256
    ) -> u256;

    /// @dev Burn UNI tokens to withdraw ETH && Tokens at current ratio.
    /// @param amount Amount of UNI burned.
    /// @param min_eth Minimum ETH withdrawn.
    /// @param min_tokens Minimum Tokens withdrawn.
    /// @param deadline Time after which this transaction can no longer be executed.
    /// @return The amount of ETH && Tokens withdrawn.
    fn remove_liquidity(
        ref self: TContractState, amount: u256, min_eth: u256, min_tokens: u256, deadline: u256
    ) -> (u256, u256);
}

#[starknet::interface]
trait IUniswapExchangeStorage<TContractState> {
    fn token(ref self: TContractState) -> IERC20Dispatcher;
    fn ether_token(ref self: TContractState) -> IERC20Dispatcher;
    fn ether_token_balance(ref self: TContractState) -> u256;
    fn factory(ref self: TContractState) -> IUniswapFactoryDispatcher;
}


#[starknet::interface]
trait IUniswapFactory<TContractState> {
    fn initialize_factory(
        ref self: TContractState, template: ClassHash, ether_token: ContractAddress
    );
    fn create_exchange(ref self: TContractState, token: ContractAddress) -> ContractAddress;
    fn get_exchange(self: @TContractState, token: ContractAddress) -> ContractAddress;
    fn get_token(self: @TContractState, exchange: ContractAddress) -> ContractAddress;
    fn get_token_with_id(self: @TContractState, token_id: u256) -> ContractAddress;
}
