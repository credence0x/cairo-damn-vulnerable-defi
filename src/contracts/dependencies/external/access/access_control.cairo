use starknet::ContractAddress;

const IACCESSCONTROL_ID: felt252 =
    0x23700be02858dbe2ac4dc9c9f66d0b6b0ed81ec7f970ca6844500a56ff61751;

#[starknet::interface]
trait IAccessControl<TContractState> {
    fn has_role(self: @TContractState, role: felt252, account: ContractAddress) -> bool;
    fn get_role_admin(self: @TContractState, role: felt252) -> felt252;
    fn grant_role(ref self: TContractState, role: felt252, account: ContractAddress);
    fn revoke_role(ref self: TContractState, role: felt252, account: ContractAddress);
    fn renounce_role(ref self: TContractState, role: felt252, account: ContractAddress);
}


#[starknet::contract]
mod access_control {
    use starknet::ContractAddress;
    use starknet::get_caller_address;
    use damnvulnerabledefi::contracts::dependencies::external::utils::IERC165::{
       IERC165_ID, IERC165, IERC165Dispatcher, IERC165DispatcherTrait
    };

    #[storage]
    struct Storage {
        role_admin: LegacyMap::<felt252, felt252>,
        role_members: LegacyMap::<(felt252, ContractAddress), bool>,
    }


    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        RoleGranted: RoleGranted,
        RoleRevoked: RoleRevoked,
        RoleAdminChanged: RoleAdminChanged
    }

    /// Emitted when `account` is granted `role`.
    ///
    /// `sender` is the account that originated the contract call, an admin role
    /// bearer (except if `_grant_role` is called during initialization from the constructor).
    #[derive(Drop, starknet::Event)]
    struct RoleGranted{
        role: felt252, 
        account: ContractAddress, 
        sender: ContractAddress
    }

    /// Emitted when `account` is revoked `role`.
    ///
    /// `sender` is the account that originated the contract call:
    ///   - If using `revoke_role`, it is the admin role bearer.
    ///   - If using `renounce_role`, it is the role bearer (i.e. `account`).
    #[derive(Drop, starknet::Event)]
    struct RoleRevoked{
        role: felt252, 
        account: ContractAddress, 
        sender: ContractAddress
    }

    /// Emitted when `new_admin_role` is set as `role`'s admin role, replacing `previous_admin_role`
    ///
    /// `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
    /// {RoleAdminChanged} not being emitted signaling this.
    #[derive(Drop, starknet::Event)]
    struct RoleAdminChanged{
        role: felt252, 
        previous_admin_role: felt252, 
        new_admin_role: felt252
    }


    #[external(v0)]
    impl ERC165 of IERC165<ContractState> {
        fn supports_interface(self: @ContractState, interface_id: felt252) -> bool {
               (interface_id == super::IACCESSCONTROL_ID)
            || (interface_id == IERC165_ID)
        }
    }

    #[external(v0)]
    impl AccessControlImpl of super::IAccessControl<ContractState> {
        fn has_role(self: @ContractState, role: felt252, account: ContractAddress) -> bool {
            self.role_members.read((role, account))
        }

        fn get_role_admin(self: @ContractState, role: felt252) -> felt252 {
            self.role_admin.read(role)
        }

        fn grant_role(ref self: ContractState, role: felt252, account: ContractAddress) {
            let admin = AccessControlImpl::get_role_admin(@self, role);
            InternalAccessControlImpl::assert_only_role(@self, admin);
            InternalAccessControlImpl::_grant_role(ref self, role, account);
        }

        fn revoke_role(ref self: ContractState, role: felt252, account: ContractAddress) {
            let admin: felt252 = AccessControlImpl::get_role_admin(@self, role);
            InternalAccessControlImpl::assert_only_role(@self, admin);
            InternalAccessControlImpl::_revoke_role(ref self, role, account);
        }

        fn renounce_role(ref self: ContractState, role: felt252, account: ContractAddress) {
            let caller: ContractAddress = get_caller_address();
            assert(caller == account, 'Can only renounce role for self');
            InternalAccessControlImpl::_revoke_role(ref self, role, account);
        }
    }

    #[generate_trait]
    impl InternalAccessControlImpl of InternalAccessControlTrait {
        fn assert_only_role(self: @ContractState, role: felt252) {
            let caller: ContractAddress = get_caller_address();
            let authorized: bool = AccessControlImpl::has_role(self, role, caller);
            assert(authorized, 'Caller is missing role');
        }

        //
        // WARNING
        // The following internal methods are unprotected and should
        // not be used outside of a contract's constructor.
        //


        fn _grant_role(ref self: ContractState, role: felt252, account: ContractAddress) {
            if !AccessControlImpl::has_role(@self, role, account) {
                let caller: ContractAddress = get_caller_address();
                self.role_members.write((role, account), true);

                self.emit(Event::RoleGranted(RoleGranted{
                    role,
                    account,
                    sender: caller
                }));
            }
        }


        fn _revoke_role(ref self: ContractState, role: felt252, account: ContractAddress) {
            if AccessControlImpl::has_role(@self, role, account) {
                let caller: ContractAddress = get_caller_address();
                self.role_members.write((role, account), false);

                self.emit(Event::RoleRevoked(RoleRevoked{
                    role,
                    account,
                    sender: caller
                }));
            }
        }


        fn _set_role_admin(ref self: ContractState, role: felt252, admin_role: felt252) {
            let previous_admin_role: felt252 = AccessControlImpl::get_role_admin(@self, role);
            self.role_admin.write(role, admin_role);

            self.emit(Event::RoleAdminChanged(RoleAdminChanged{
                role,
                previous_admin_role,
                new_admin_role: admin_role
            }));
        }
    }


    
}