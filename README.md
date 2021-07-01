# Get `dove` Action

This GitHub Action delivers specified [`dove`] release for a Move language.

[`dove`]: https://github.com/pontem-network/move-tools


## Parameters

- `version` - specified version of the release. Optional. Default value is `latest`.


## Usage Example

Download the latest version of dove

```yaml
- name: get dove
  uses: pontem-network/get-dove@master
```

Download a specific version of dove

```yaml
- name: get dove
  uses: pontem-network/get-dove@master
  with:
    version: 1.2.2
```
