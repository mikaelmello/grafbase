use std::{
    borrow::Cow,
    fmt::{self, Write},
};

use crate::common::{Identifier, Quoted};

use super::{StaticType, TypeName};

#[derive(Clone, Debug)]
pub struct TypeIdentifier<'a> {
    name: TypeName<'a>,
    extends: Option<Box<StaticType<'a>>>,
    params: Vec<StaticType<'a>>,
    array: bool,
}

impl<'a> TypeIdentifier<'a> {
    pub fn ident(name: impl Into<Cow<'a, str>>) -> Self {
        Self::new(TypeName::Ident(Identifier::new(name)))
    }

    #[allow(dead_code)]
    pub fn string(name: impl Into<Cow<'a, str>>) -> Self {
        Self::new(TypeName::String(Quoted::new(name)))
    }

    pub fn extends(&mut self, r#type: StaticType<'a>) {
        self.extends = Some(Box::new(r#type));
    }

    pub fn array(&mut self) {
        self.array = true;
    }

    fn new(name: TypeName<'a>) -> Self {
        Self {
            name,
            params: Vec::new(),
            extends: None,
            array: false,
        }
    }

    pub fn push_param(&mut self, param: StaticType<'a>) {
        self.params.push(param);
    }
}

impl<'a> fmt::Display for TypeIdentifier<'a> {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        self.name.fmt(f)?;

        if !self.params.is_empty() {
            f.write_char('<')?;

            for (i, param) in self.params.iter().enumerate() {
                param.fmt(f)?;

                if i < self.params.len() - 1 {
                    f.write_str(", ")?;
                }
            }

            f.write_char('>')?;
        }

        if self.array {
            f.write_str("[]")?;
        }

        if let Some(ref extends) = self.extends {
            write!(f, " extends {extends}")?;
        }

        Ok(())
    }
}
