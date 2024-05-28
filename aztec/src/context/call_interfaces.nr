use dep::protocol_types::{abis::function_selector::FunctionSelector, address::AztecAddress, traits::Deserialize};
use crate::context::{private_context::PrivateContext, public_context::PublicContext, gas::GasOpts, public_context::FunctionReturns};
use crate::oracle::arguments;

#[derive(Debug)]
struct CallArgs {
    target_contract: AztecAddress,
    selector: FunctionSelector,
    args_hash: Option<Field>,
    args: Option<Vec<Field>>,
}

impl CallArgs {
    fn new_private(target_contract: AztecAddress, selector: FunctionSelector, args_hash: Field) -> Self {
        Self {
            target_contract,
            selector,
            args_hash: Some(args_hash),
            args: None,
        }
    }

    fn new_public(target_contract: AztecAddress, selector: FunctionSelector, args: Vec<Field>, gas_opts: GasOpts) -> Self {
        Self {
            target_contract,
            selector,
            args_hash: None,
            args: Some(args),
        }
    }
}

struct PrivateCallInterface<T> {
    call_args: CallArgs,
}

impl<T> PrivateCallInterface<T> {
    pub fn call<N>(self, context: &mut PrivateContext) -> T
    where
        T: Deserialize<N>,
    {
        let returns = context.call_private_function_with_packed_args(
            self.call_args.target_contract,
            self.call_args.selector,
            self.call_args.args_hash.unwrap(),
            false,
            false,
        );
        returns.unpack_into()
    }

    pub fn view<N>(self, context: &mut PrivateContext) -> T
    where
        T: Deserialize<N>,
    {
        let returns = context.call_private_function_with_packed_args(
            self.call_args.target_contract,
            self.call_args.selector,
            self.call_args.args_hash.unwrap(),
            true,
            false,
        );
        returns.unpack_into()
    }

    pub fn delegate_call<N>(self, context: &mut PrivateContext) -> T
    where
        T: Deserialize<N>,
    {
        let returns = context.call_private_function_with_packed_args(
            self.call_args.target_contract,
            self.call_args.selector,
            self.call_args.args_hash.unwrap(),
            false,
            true,
        );
        returns.unpack_into()
    }
}

struct PrivateVoidCallInterface {
    call_args: CallArgs,
}

impl PrivateVoidCallInterface {
    pub fn call(self, context: &mut PrivateContext) {
        context
            .call_private_function_with_packed_args(
                self.call_args.target_contract,
                self.call_args.selector,
                self.call_args.args_hash.unwrap(),
                false,
                false,
            )
            .assert_empty();
    }

    pub fn view(self, context: &mut PrivateContext) {
        context
            .call_private_function_with_packed_args(
                self.call_args.target_contract,
                self.call_args.selector,
                self.call_args.args_hash.unwrap(),
                true,
                false,
            )
            .assert_empty();
    }

    pub fn delegate_call(self, context: &mut PrivateContext) {
        context
            .call_private_function_with_packed_args(
                self.call_args.target_contract,
                self.call_args.selector,
                self.call_args.args_hash.unwrap(),
                false,
                true,
            )
            .assert_empty();
    }
}

struct PrivateStaticCallInterface<T> {
    call_args: CallArgs,
}

impl<T> PrivateStaticCallInterface<T> {
    pub fn view<N>(self, context: &mut PrivateContext) -> T
    where
        T: Deserialize<N>,
    {
        let returns = context.call_private_function_with_packed_args(
            self.call_args.target_contract,
            self.call_args.selector,
            self.call_args.args_hash.unwrap(),
            true,
            false,
        );
        returns.unpack_into()
    }
}

struct PrivateStaticVoidCallInterface {
    call_args: CallArgs,
}

impl PrivateStaticVoidCallInterface {
    pub fn view(self, context: &mut PrivateContext) {
        context
            .call_private_function_with_packed_args(
                self.call_args.target_contract,
                self.call_args.selector,
                self.call_args.args_hash.unwrap(),
                true,
                false,
            )
            .assert_empty();
    }
}

struct PublicCallInterface<T> {
    call_args: CallArgs,
    gas_opts: GasOpts,
}

impl<T> PublicCallInterface<T> {
    pub fn with_gas(mut self, gas_opts: GasOpts) -> Self {
        self.gas_opts = gas_opts;
        self
    }

    pub fn call<N>(self, context: &mut PublicContext) -> T
    where
        T: Deserialize<N>,
    {
        let returns = context.call_public_function(
            self.call_args.target_contract,
            self.call_args.selector,
            self.call_args.args.unwrap(),
            self.gas_opts,
        );
        returns.deserialize_into()
    }

    pub fn view<N>(self, context: &mut PublicContext) -> T
    where
        T: Deserialize<N>,
    {
        let returns = context.static_call_public_function(
            self.call_args.target_contract,
            self.call_args.selector,
            self.call_args.args.unwrap(),
            self.gas_opts,
        );
        returns.deserialize_into()
    }

    pub fn delegate_call<N>(self, context: &mut PublicContext) -> T
    where
        T: Deserialize<N>,
    {
        let returns = context.delegate_call_public_function(
            self.call_args.target_contract,
            self.call_args.selector,
            self.call_args.args.unwrap(),
        );
        returns.deserialize_into()
    }

    pub fn enqueue(self, context: &mut PrivateContext) {
        let args_hash = arguments::pack_arguments(self.call_args.args.unwrap());
        context.call_public_function_with_packed_args(
            self.call_args.target_contract,
            self.call_args.selector,
            args_hash,
            false,
            false,
        );
    }

    pub fn enqueue_view(self, context: &mut PrivateContext) {
        let args_hash = arguments::pack_arguments(self.call_args.args.unwrap());
        context.call_public_function_with_packed_args(
            self.call_args.target_contract,
            self.call_args.selector,
            args_hash,
            true,
            false,
        );
    }

    pub fn delegate_enqueue(self, context: &mut PrivateContext) {
        let args_hash = arguments::pack_arguments(self.call_args.args.unwrap());
        context.call_public_function_with_packed_args(
            self.call_args.target_contract,
            self.call_args.selector,
            args_hash,
            false,
            true,
        );
    }
}

struct PublicVoidCallInterface {
    call_args: CallArgs,
    gas_opts: GasOpts,
}

impl PublicVoidCallInterface {
    pub fn with_gas(mut self, gas_opts: GasOpts) -> Self {
        self.gas_opts = gas_opts;
        self
    }

    pub fn call(self, context: &mut PublicContext) {
        let returns = context.call_public_function(
            self.call_args.target_contract,
            self.call_args.selector,
            self.call_args.args.unwrap(),
            self.gas_opts,
        );
        returns.assert_empty();
    }

    pub fn view(self, context: &mut PublicContext) {
        let returns = context.static_call_public_function(
            self.call_args.target_contract,
            self.call_args.selector,
            self.call_args.args.unwrap(),
            self.gas_opts,
        );
        returns.assert_empty();
    }

    pub fn delegate_call(self, context: &mut PublicContext) {
        let returns = context.delegate_call_public_function(
            self.call_args.target_contract,
            self.call_args.selector,
            self.call_args.args.unwrap(),
        );
        returns.assert_empty();
    }

    pub fn enqueue(self, context: &mut PrivateContext) {
        let args_hash = arguments::pack_arguments(self.call_args.args.unwrap());
        context.call_public_function_with_packed_args(
            self.call_args.target_contract,
            self.call_args.selector,
            args_hash,
            false,
            false,
        );
    }

    pub fn enqueue_view(self, context: &mut PrivateContext) {
        let args_hash = arguments::pack_arguments(self.call_args.args.unwrap());
        context.call_public_function_with_packed_args(
            self.call_args.target_contract,
            self.call_args.selector,
            args_hash,
            true,
            false,
        );
    }

    pub fn delegate_enqueue(self, context: &mut PrivateContext) {
        let args_hash = arguments::pack_arguments(self.call_args.args.unwrap());
        context.call_public_function_with_packed_args(
            self.call_args.target_contract,
            self.call_args.selector,
            args_hash,
            false,
            true,
        );
    }
}

struct PublicStaticCallInterface<T> {
    call_args: CallArgs,
    gas_opts: GasOpts,
}

impl<T> PublicStaticCallInterface<T> {
    pub fn with_gas(mut self, gas_opts: GasOpts) -> Self {
        self.gas_opts = gas_opts;
        self
    }

    pub fn view<N>(self, context: &mut PublicContext) -> T
    where
        T: Deserialize<N>,
    {
        let returns = context.static_call_public_function(
            self.call_args.target_contract,
            self.call_args.selector,
            self.call_args.args.unwrap(),
            self.gas_opts,
        );
        returns.deserialize_into()
    }

    pub fn enqueue_view(self, context: &mut PrivateContext) {
        let args_hash = arguments::pack_arguments(self.call_args.args.unwrap());
        context.call_public_function_with_packed_args(
            self.call_args.target_contract,
            self.call_args.selector,
            args_hash,
            true,
            false,
        );
    }
}

struct PublicStaticVoidCallInterface {
    call_args: CallArgs,
    gas_opts: GasOpts,
}

impl PublicStaticVoidCallInterface {
    pub fn with_gas(mut self, gas_opts: GasOpts) -> Self {
        self.gas_opts = gas_opts;
        self
    }

    pub fn view(self, context: &mut PublicContext) {
        let returns = context.static_call_public_function(
            self.call_args.target_contract,
            self.call_args.selector,
            self.call_args.args.unwrap(),
            self.gas_opts,
        );
        returns.assert_empty();
    }

    pub fn enqueue_view(self, context: &mut PrivateContext) {
        let args_hash = arguments::pack_arguments(self.call_args.args.unwrap());
        context.call_public_function_with_packed_args(
            self.call_args.target_contract,
            self.call_args.selector,
            args_hash,
            true,
            false,
        );
    }
}
