# swift-nanopack

A Swift implementation of the [NanoPack](https://github.com/poly-gui/nanopack) serialization format.

## Generating Swift code

`nanoc` supports generating Swift code from NanoPack schemas:

```
nanoc --language swift schema1.yaml schema2.yaml ...
```

The generated code imports this library, so please make sure that this library is included in the project that is using the generated code.
